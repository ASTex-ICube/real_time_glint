#include "sceneglint.h"
#include "texture.h"

#include <iostream>
#include <glm/gtc/matrix_transform.hpp>

#include "imgui/imgui.h"
#include "imgui/imgui_impl_glfw.h"
#include "imgui/imgui_impl_opengl3.h"

SceneGlint::SceneGlint() :
	tPrev(0.0f),
	lightPos(5.0f, 5.0f, 5.0f, 1.0f),
	objectOrientation(0.),
	sphere("../media/sphere/sphere.obj"),
	camera(glm::vec3(0., 0., 2.2)),
	maxAnisotropy(8.f),
	microfacetRelativeArea(1.f),
	alpha_x(0.5f),
	alpha_y(0.5f),
	logMicrofacetDensity(27.f) {}

void SceneGlint::initScene() {

	compileAndLinkShader();

	glEnable(GL_DEPTH_TEST);

	view = camera.GetViewMatrix();

	projection = glm::perspective(glm::radians(50.0f), (float)width / height, 0.001f, 10000.0f);

	prog.setUniform("Light.L", glm::vec3(100.0f));
	prog.setUniform("Light.Position", lightPos);

	// Load dictionary of marginal distributions
	int numberOfLevels = 16;
	int numberOfDistributionsPerChannel = 64;
	GLuint dicoTex = Texture::loadMultiscaleMarginalDistributions("../media/dictionary/dict_16_192_64_0p5_0p02", numberOfLevels, numberOfDistributionsPerChannel);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_1D_ARRAY, dicoTex);

	prog.setUniform("Dictionary.Alpha", 0.5f);
	prog.setUniform("Dictionary.N", numberOfDistributionsPerChannel * 3);
	prog.setUniform("Dictionary.NLevels", numberOfLevels);
	prog.setUniform("Dictionary.Pyramid0Size", 1 << (numberOfLevels - 1));

	prog.setUniform("CameraPosition", camera.Position);

}

void SceneGlint::update(float t, GLFWwindow* window) {

	// Start the Dear ImGui frame
	ImGui_ImplOpenGL3_NewFrame();
	ImGui_ImplGlfw_NewFrame();
	ImGui::NewFrame();
	{
		ImGui::Begin("Parameters");

		ImGui::SliderFloat("Roughness X", &alpha_x, 0.01f, 1.0f);
		ImGui::SliderFloat("Roughness Y", &alpha_y, 0.01f, 1.0f);
		ImGui::SliderFloat("Log microfacet density", &logMicrofacetDensity, 15.f, 40.f);
		ImGui::SliderFloat("Microfacet relative area", &microfacetRelativeArea, 0.01f, 1.f);

		ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
		ImGui::End();
	}

	// Object update
	float deltaT = t - tPrev;
	if (tPrev == 0.0f) deltaT = 0.0f;
	tPrev = t;
	objectOrientation = glm::mod(objectOrientation + deltaT * 0.1f, glm::two_pi<float>());

	// Camera update
	if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
		camera.ProcessKeyboard(FORWARD, deltaT);
	if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
		camera.ProcessKeyboard(BACKWARD, deltaT);
	if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
		camera.ProcessKeyboard(LEFT, deltaT);
	if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
		camera.ProcessKeyboard(RIGHT, deltaT);

	if (glfwGetKey(window, GLFW_KEY_LEFT) == GLFW_PRESS)
		camera.ProcessMouseMovement(-5.f, 0.f);
	if (glfwGetKey(window, GLFW_KEY_RIGHT) == GLFW_PRESS)
		camera.ProcessMouseMovement(5.f, 0.f);
	if (glfwGetKey(window, GLFW_KEY_UP) == GLFW_PRESS)
		camera.ProcessMouseMovement(0.f, 5.f);
	if (glfwGetKey(window, GLFW_KEY_DOWN) == GLFW_PRESS)
		camera.ProcessMouseMovement(0.f, -5.f);

	view = camera.GetViewMatrix();

	prog.setUniform("CameraPosition", camera.Position);
	prog.setUniform("MicrofacetRelativeArea", microfacetRelativeArea);
	prog.setUniform("MaxAnisotropy", maxAnisotropy);
	prog.setUniform("Material.LogMicrofacetDensity", logMicrofacetDensity);
}

void SceneGlint::render()
{
	// Rendering
	ImGui::Render();

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	prog.setUniform("Light.Position", lightPos);
	drawScene();

	ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
}

void SceneGlint::resize(int w, int h)
{
	glViewport(0, 0, w, h);
	width = w;
	height = h;
	prog.setUniform("Resolution", glm::ivec2(width, height));
	projection = glm::perspective(glm::radians(60.0f), (float)w / h, 0.3f, 100.0f);
}

void SceneGlint::setMatrices()
{
	glm::mat4 mv = view * model;
	prog.setUniform("ModelMatrix", model);
	prog.setUniform("MVP", projection * mv);
}

void SceneGlint::compileAndLinkShader() {
	try {
		prog.compileShader("shader/glint.vert.glsl");
		prog.compileShader("shader/glint.frag.glsl");
		prog.link();
		prog.use();
	}
	catch (GLSLProgramException& e) {
		std::cerr << e.what() << std::endl;
		exit(EXIT_FAILURE);
	}
}

void SceneGlint::drawScene() {

	glm::vec3 color(1., 1., 1.);
	glm::vec3 pos(0., 0., 0.);
	glm::vec3 scale(1., 1., 1.);

	model = glm::mat4(1.0f);
	prog.setUniform("Material.Alpha_x", alpha_x);
	prog.setUniform("Material.Alpha_y", alpha_y);
	model = glm::rotate(model, glm::radians(180.0f) + objectOrientation, glm::vec3(0.0f, 1.0f, 0.0f));
	model = glm::scale(model, glm::vec3(scale.x, scale.y, scale.z));

	setMatrices();

	sphere.Draw(prog);
}