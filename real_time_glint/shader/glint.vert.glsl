#version 410

layout (location = 0) in vec3 VertexPosition;
layout (location = 1) in vec3 VertexNormal;
layout (location = 2) in vec2 VertexTexCoord;
layout (location = 3) in vec3 VertexTangent;

out vec2 TexCoord;
out vec3 VertexPos;
out vec3 VertexNorm;
out vec3 VertexTang;

uniform mat4 ModelMatrix;
uniform mat4 MVP;

void main() {

    // Transform normal and tangent to world space
    vec3 norm = normalize( (ModelMatrix * vec4(VertexNormal, 0.)).xyz );
    VertexNorm = norm;
    vec3 tang = normalize( (ModelMatrix * vec4(VertexTangent, 0.)).xyz );
    VertexTang = tang;

    TexCoord = VertexTexCoord;

    VertexPos = (ModelMatrix * vec4(VertexPosition, 1.)).xyz;

    gl_Position = MVP * vec4(VertexPosition,1.0);
}
