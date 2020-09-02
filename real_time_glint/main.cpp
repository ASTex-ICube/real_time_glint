#include "scene.h"
#include "scenerunner.h"
#include "sceneglint.h"

std::map<std::string, std::string> sceneInfo = {
	{ "glint", "Rendering real time glint"}
};


int main(int argc, char *argv[])
{
	std::string sceneName = (argc == 1) ? "glint" : SceneRunner::parseCLArgs(argc, argv, sceneInfo);

	SceneRunner runner("Real Time Glint - " + sceneName);
	std::unique_ptr<Scene> scene;
	if (sceneName == "glint") {
		scene = std::unique_ptr<Scene>(new SceneGlint());
	}

	return runner.run(std::move(scene));
}
