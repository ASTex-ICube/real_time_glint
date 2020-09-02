#pragma once

#include "scene.h"
#include "glslprogram.h"
#include "openglogl.h"

#include "model.h"
#include "camera.h"

#include <glm/glm.hpp>

class SceneGlint : public Scene {
private:
    GLSLProgram prog;

    Model sphere;
    Camera camera;
	
	glm::vec4 lightPos;
    float objectOrientation;

    float tPrev;

    float alpha_x;
    float alpha_y;
    float logMicrofacetDensity;
    float microfacetRelativeArea;
    float maxAnisotropy;

    void setMatrices();
    void compileAndLinkShader();

	void drawScene();
public:
    SceneGlint();

    void initScene();
    void update( float t, GLFWwindow* window);
    void render();
    void resize(int, int);
};
