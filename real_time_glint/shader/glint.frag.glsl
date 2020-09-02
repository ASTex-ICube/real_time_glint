#version 450

// The MIT License
// Copyright © 2020 Xavier Chermain (ICUBE), Basile Sauvage (ICUBE), Jean-Michel Dishler (ICUBE) and Carsten Dachsbacher (KIT)
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Implementation of
// Procedural Physically based BRDF for Real-Time Rendering of Glints
// 2020 Xavier Chermain (ICUBE), Basile Sauvage (ICUBE), Jean-Michel Dishler (ICUBE) and Carsten Dachsbacher (KIT)
// Accepted for [Pacific Graphic 2020](https://pg2020.org/) and for CGF special issue.

in vec2 TexCoord;
in vec3 VertexPos;
in vec3 VertexNorm;
in vec3 VertexTang;

uniform struct LightInfo
{
    vec4 Position; // Light position in world coords
    vec3 L;        // Intensity
} Light;

uniform struct MaterialInfo
{
    float Alpha_x;              // Material roughness along x
    float Alpha_y;              // Material roughness along y
    float LogMicrofacetDensity; // Logarithmic microfacet density
} Material;

uniform struct DictionaryInfo
{
    float Alpha;      // Roughness of the dictionary (\alpha_{dist} in the paper)
    int N;            // Number of marginal distributions in the dictionary
    int NLevels;      // Number of LOD in the dictionary
    int Pyramid0Size; // Number of cells along one axis at LOD 0, for NLevels LODs, in a MIP hierarchy
} Dictionary;

uniform vec3 CameraPosition;
uniform float MicrofacetRelativeArea;
uniform float MaxAnisotropy;

layout(binding = 0) uniform sampler1DArray DictionaryTex; // Array of 1D textures, containing the marginal distributions (the dictionary)

layout(location = 0) out vec4 FragColor;

//=========================================================================================================================
//=============================================== Beckmann anisotropic NDF ================================================
//==================== Shadertoy implementation : Arthur Cavalier (https://www.shadertoy.com/user/H4w0) ===================
//========================================= https://www.shadertoy.com/view/WlGXRt =========================================
//=========================================================================================================================

//-----------------------------------------------------------------------------
//-- Constants ----------------------------------------------------------------
const float m_pi = 3.141592;       /* MathConstant: PI                                 */
const float m_i_pi = 0.318309;     /* MathConstant: 1 / PI                             */
const float m_i_sqrt_2 = 0.707106; /* MathConstant: 1/sqrt(2)                          */

//-----------------------------------------------------------------------------
//-- Beckmann distribution ----------------------------------------------------
float p22_beckmann_anisotropic(float x, float y, float alpha_x, float alpha_y)
{
    float x_sqr = x * x;
    float y_sqr = y * y;
    float sigma_x = alpha_x * m_i_sqrt_2;
    float sigma_y = alpha_y * m_i_sqrt_2;
    float sigma_x_sqr = sigma_x * sigma_x;
    float sigma_y_sqr = sigma_y * sigma_y;
    return exp(-0.5 * ((x_sqr / sigma_x_sqr) + (y_sqr / sigma_y_sqr))) / (2. * m_pi * sigma_x * sigma_y);
}

float ndf_beckmann_anisotropic(vec3 omega_h, float alpha_x, float alpha_y)
{
    float slope_x = -(omega_h.x / omega_h.z);
    float slope_y = -(omega_h.y / omega_h.z);
    float cos_theta = omega_h.z;
    float cos_2_theta = cos_theta * cos_theta;
    float cos_4_theta = cos_2_theta * cos_2_theta;
    float beckmann_p22 = p22_beckmann_anisotropic(slope_x, slope_y, alpha_x, alpha_y);
    return beckmann_p22 / cos_4_theta;
}

//=========================================================================================================================
//=============================================== Diffuse Lambertian BRDF =================================================
//=========================================================================================================================

vec3 f_diffuse(vec3 wo, vec3 wi)
{
    if (wo.z <= 0.)
        return vec3(0., 0., 0.);
    if (wi.z <= 0.)
        return vec3(0., 0., 0.);

    return vec3(0.8, 0., 0.) * m_i_pi * wi.z;
}

//=========================================================================================================================
//=============================================== Inverse error function ==================================================
//=========================================================================================================================

float erfinv(float x)
{
    float w, p;
    w = -log((1.0 - x) * (1.0 + x));
    if (w < 5.000000)
    {
        w = w - 2.500000;
        p = 2.81022636e-08;
        p = 3.43273939e-07 + p * w;
        p = -3.5233877e-06 + p * w;
        p = -4.39150654e-06 + p * w;
        p = 0.00021858087 + p * w;
        p = -0.00125372503 + p * w;
        p = -0.00417768164 + p * w;
        p = 0.246640727 + p * w;
        p = 1.50140941 + p * w;
    }
    else
    {
        w = sqrt(w) - 3.000000;
        p = -0.000200214257;
        p = 0.000100950558 + p * w;
        p = 0.00134934322 + p * w;
        p = -0.00367342844 + p * w;
        p = 0.00573950773 + p * w;
        p = -0.0076224613 + p * w;
        p = 0.00943887047 + p * w;
        p = 1.00167406 + p * w;
        p = 2.83297682 + p * w;
    }
    return p * x;
}

//=========================================================================================================================
//================================================== Hash function ========================================================
//================================================== Inigo Quilez =========================================================
//====================================== https://www.shadertoy.com/view/llGSzw ============================================
//=========================================================================================================================
float hashIQ(uint n)
{
    // integer hash copied from Hugo Elias
    n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float(n & 0x7fffffffU) / float(0x7fffffff);
}

//=========================================================================================================================
//=============================================== Pyramid size at LOD level ===============================================
//=========================================================================================================================
int pyramidSize(int level)
{
    return int(pow(2., float(Dictionary.NLevels - 1 - level)));
}

//=========================================================================================================================
//========================================= Sampling from a normal distribution ===========================================
//=========================================================================================================================
float sampleNormalDistribution(float U, float mu, float sigma)
{
    float x = sigma * 1.414213f * erfinv(2.0f * U - 1.0f) + mu;
    return x;
}

//=========================================================================================================================
//=================== Spatially-varying, multiscale, rotated, and scaled slope distribution function ======================
//================================================= Eq. 11, Alg. 3 ========================================================
//=========================================================================================================================
float P22_theta_alpha(vec2 slope_h, int l, int s0, int t0)
{
    // Coherent index
    // Eq. 8, Alg. 3, line 1
    int twoToTheL = int(pow(2.,float(l)));
    s0 *= twoToTheL;
    t0 *= twoToTheL;

    // Seed pseudo random generator
    // Alg. 3, line 2
    uint rngSeed = s0 + 1549 * t0;

    // Alg.3, line 3
    float uMicrofacetRelativeArea = hashIQ(rngSeed * 13U);
    // Discard cells by using microfacet relative area
    // Alg.3, line 4
    if (uMicrofacetRelativeArea > MicrofacetRelativeArea)
        return 0.f;

    // Number of microfacets in a cell
    // Alg. 3, line 5
    float n = pow(2., float(2 * l - (2 * (Dictionary.NLevels - 1))));
    n *= exp(Material.LogMicrofacetDensity);

    // Corresponding continuous distribution LOD
    // Alg. 3, line 6
    float l_dist = log(n) / 1.38629; // 2. * log(2) = 1.38629

    // Alg. 3, line 7
    float uDensityRandomisation = hashIQ(rngSeed * 2171U);

    // Fix density randomisation to 2 to have better appearance
    // Notation in the paper: \zeta
    float densityRandomisation = 2.;

    // Sample a Gaussian to randomise the distribution LOD around the distribution level l_dist
    // Alg. 3, line 8
    l_dist = sampleNormalDistribution(uDensityRandomisation, l_dist, densityRandomisation);

    // Alg. 3, line 9
    l_dist = clamp(int(round(l_dist)), 0, Dictionary.NLevels);

    // Alg. 3, line 10
    if (l_dist == Dictionary.NLevels)
        return p22_beckmann_anisotropic(slope_h.x, slope_h.y, Material.Alpha_x, Material.Alpha_y);

    // Alg. 3, line 13
    float uTheta = hashIQ(rngSeed);
    float theta = 2.0 * m_pi * uTheta;

    // Uncomment to remove random distribution rotation
    // Lead to glint alignments
    // theta = 0.;

    float cosTheta = cos(theta);
    float sinTheta = sin(theta);

    vec2 scaleFactor = vec2(Material.Alpha_x / Dictionary.Alpha,
                            Material.Alpha_y / Dictionary.Alpha);

    // Rotate and scale slope
    // Alg. 3, line 16
    slope_h = vec2(slope_h.x * cosTheta / scaleFactor.x + slope_h.y * sinTheta / scaleFactor.y,
                   -slope_h.x * sinTheta / scaleFactor.x + slope_h.y * cosTheta / scaleFactor.y);

    vec2 abs_slope_h = vec2(abs(slope_h.x), abs(slope_h.y));

    int distPerChannel = Dictionary.N / 3;
    float alpha_dist_isqrt2_4 = Dictionary.Alpha * m_i_sqrt_2 * 4.f;

    if (abs_slope_h.x > alpha_dist_isqrt2_4 || abs_slope_h.y > alpha_dist_isqrt2_4)
        return 0.f;

    // Alg. 3, line 17
    float u1 = hashIQ(rngSeed * 16807U);
    float u2 = hashIQ(rngSeed * 48271U);

    // Alg. 3, line 18
    int i = int(u1 * float(Dictionary.N));
    int j = int(u2 * float(Dictionary.N));

    // 3 distributions values in one texel
    int distIdxXOver3 = i / 3;
    int distIdxYOver3 = j / 3;

    float texCoordX = abs_slope_h.x / alpha_dist_isqrt2_4;
    float texCoordY = abs_slope_h.y / alpha_dist_isqrt2_4;

    vec3 P_i = textureLod(DictionaryTex, vec2(texCoordX, l_dist * Dictionary.N / 3 + distIdxXOver3), 0).rgb;
    vec3 P_j = textureLod(DictionaryTex, vec2(texCoordY, l_dist * Dictionary.N / 3 + distIdxYOver3), 0).rgb;

    // Alg. 3, line 19
    return P_i[int(mod(i, 3))] * P_j[int(mod(j, 3))] / (scaleFactor.x * scaleFactor.y);
}

//=========================================================================================================================
//========================================= Alg. 2, P-SDF for a discrete LOD ==============================================
//=========================================================================================================================

// Most of this function is similar to pbrt-v3 EWA function,
// which itself is similar to Heckbert 1889 algorithm, http://www.cs.cmu.edu/~ph/texfund/texfund.pdf, Section 3.5.9.
// Go through cells within the pixel footprint for a givin LOD
float P22__P_(int l, vec2 slope_h, vec2 st, vec2 dst0, vec2 dst1)
{

    // Convert surface coordinates to appropriate scale for level
    float pyrSize = pyramidSize(l);
    st[0] = st[0] * pyrSize - 0.5f;
    st[1] = st[1] * pyrSize - 0.5f;
    dst0[0] *= pyrSize;
    dst0[1] *= pyrSize;
    dst1[0] *= pyrSize;
    dst1[1] *= pyrSize;

    // Compute ellipse coefficients to bound filter region
    float A = dst0[1] * dst0[1] + dst1[1] * dst1[1] + 1.;
    float B = -2. * (dst0[0] * dst0[1] + dst1[0] * dst1[1]);
    float C = dst0[0] * dst0[0] + dst1[0] * dst1[0] + 1.;
    float invF = 1. / (A * C - B * B * 0.25f);
    A *= invF;
    B *= invF;
    C *= invF;

    // Compute the ellipse's bounding box in texture space
    float det = -B * B + 4 * A * C;
    float invDet = 1 / det;
    float uSqrt = sqrt(det * C), vSqrt = sqrt(A * det);
    int s0 = int(ceil(st[0] - 2. * invDet * uSqrt));
    int s1 = int(floor(st[0] + 2. * invDet * uSqrt));
    int t0 = int(ceil(st[1] - 2. * invDet * vSqrt));
    int t1 = int(floor(st[1] + 2. * invDet * vSqrt));

    // Scan over ellipse bound and compute quadratic equation
    float sum = 0.f;
    float sumWts = 0;
    int nbrOfIter = 0;
    for (int it = t0; it <= t1; ++it)
    {
        float tt = it - st[1];
        for (int is = s0; is <= s1; ++is)
        {
            float ss = is - st[0];
            // Compute squared radius and filter SDF if inside ellipse
            float r2 = A * ss * ss + B * ss * tt + C * tt * tt;
            if (r2 < 1)
            {
                // Weighting function used in pbrt-v3 EWA function
                float alpha = 2;
                float W_P = exp(-alpha * r2) - exp(-alpha);
                // Alg. 2, line 3
                sum += P22_theta_alpha(slope_h, l, is, it) * W_P;
                sumWts += W_P;
            }
            nbrOfIter++;
            // Guardrail (Extremely rare case.)
            if (nbrOfIter > 100)
                break;
        }
        // Guardrail (Extremely rare case.)
        if (nbrOfIter > 100)
            break;
    }
    return sum / sumWts;
}

//=========================================================================================================================
//=============================== Evaluation of our procedural physically based glinty BRDF ===============================
//==================================================== Alg. 1, Eq. 14 =====================================================
//=========================================================================================================================
vec3 f_P(vec3 wo, vec3 wi)
{

    if (wo.z <= 0.)
        return vec3(0., 0., 0.);
    if (wi.z <= 0.)
        return vec3(0., 0., 0.);

    // Alg. 1, line 1
    vec3 wh = normalize(wo + wi);
    if (wh.z <= 0.)
        return vec3(0., 0., 0.);

    // Local masking shadowing
    if (dot(wo, wh) <= 0. || dot(wi, wh) <= 0.)
        return vec3(0.);

    // Eq. 1, Alg. 1, line 2
    vec2 slope_h = vec2(-wh.x / wh.z, -wh.y / wh.z);

    vec2 texCoord = TexCoord;

    // Uncomment for anisotropic glints
    // texCoord *= vec2(1000., 1.);

    float D_P = 0.;
    float P22_P = 0.;

    // ------------------------------------------------------------------------------------------------------
    // Similar to pbrt-v3 MIPMap::Lookup function, http://www.pbr-book.org/3ed-2018/Texture/Image_Texture.html#EllipticallyWeightedAverage

    // Alg. 1, line 3
    vec2 dst0 = dFdx(texCoord);
    vec2 dst1 = dFdy(texCoord);

    // Compute ellipse minor and major axes
    float dst0LengthSquared = length(dst0);
    dst0LengthSquared *= dst0LengthSquared;
    float dst1LengthSquared = length(dst1);
    dst1LengthSquared *= dst1LengthSquared;

    if (dst0LengthSquared < dst1LengthSquared)
    {
        // Swap dst0 and dst1
        vec2 tmp = dst0;
        dst0 = dst1;
        dst1 = tmp;
    }
    float majorLength = length(dst0);
    // Alg. 1, line 5
    float minorLength = length(dst1);

    // Clamp ellipse eccentricity if too large
    // Alg. 1, line 4
    if (minorLength * MaxAnisotropy < majorLength && minorLength > 0.)
    {
        float scale = majorLength / (minorLength * MaxAnisotropy);
        dst1 *= scale;
        minorLength *= scale;
    }
    // ------------------------------------------------------------------------------------------------------

    // Without footprint, we evaluate the Cook Torrance BRDF
    if (minorLength == 0)
    {
        D_P = ndf_beckmann_anisotropic(wh, Material.Alpha_x, Material.Alpha_y);
    }
    else
    {
        // Choose LOD
        // Alg. 1, line 6
        float l = max(0., Dictionary.NLevels - 1. + log2(minorLength));
        int il = int(floor(l));

        // Alg. 1, line 7
        float w = l - float(il);

        // Alg. 1, line 8
        P22_P = mix(P22__P_(il, slope_h, texCoord, dst0, dst1),
                    P22__P_(il + 1, slope_h, texCoord, dst0, dst1),
                    w);

        // Eq. 6, Alg. 1, line 10
        D_P = P22_P / (wh.z * wh.z * wh.z * wh.z);
    }

    // V-cavity masking shadowing
    float G1wowh = min(1., 2. * wh.z * wo.z / dot(wo, wh));
    float G1wiwh = min(1., 2. * wh.z * wi.z / dot(wi, wh));
    float G = G1wowh * G1wiwh;

    // Fresnel is set to one for simplicity here
    // but feel free to use "real" Fresnel term
    vec3 F = vec3(1., 1., 1.);

    // Eq. 14, Alg. 1, line 14
    // (wi dot wg) is cancelled by
    // the cosine weight in the rendering equation
    return (F * G * D_P) / (4. * wo.z);
}

//=========================================================================================================================
//=========================================== Evaluate rendering equation =================================================
//=========================================================================================================================
void main()
{
    vec3 binormal = cross(VertexNorm, VertexTang);

    // Matrix for transformation to tangent space
    mat3 toLocal = mat3(
        VertexTang.x, binormal.x, VertexNorm.x,
        VertexTang.y, binormal.y, VertexNorm.y,
        VertexTang.z, binormal.z, VertexNorm.z);

    // Transform light direction and view direction to tangent space
    vec3 wi = toLocal * normalize(Light.Position.xyz - VertexPos);
    wi = normalize(wi);
    vec3 wo = toLocal * normalize(CameraPosition - VertexPos);
    wo = normalize(wo);

    vec3 radiance_specular = vec3(0);
    vec3 radiance_diffuse = vec3(0);
    vec3 radiance = vec3(0);

    float distanceSquared = distance(VertexPos, Light.Position.xyz);
    distanceSquared *= distanceSquared;
    vec3 Li = Light.L / distanceSquared;

    radiance_specular = f_P(wo, wi) * Li;

    radiance_diffuse = f_diffuse(wo, wi) * Li;

    radiance = 0.5 * radiance_diffuse + 0.5 * radiance_specular;

    // Gamma
    radiance = pow(radiance, vec3(1.0 / 2.2));

    FragColor = vec4(radiance, 1);
}
