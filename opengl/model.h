// https://learnopengl.com/Model-Loading/Model

#pragma once

#include <vector>
#include <glm/glm.hpp>
#include <string>
#include <memory>

#include <assimp/Importer.hpp>
#include <assimp/scene.h>
#include <assimp/postprocess.h>

#include "openglogl.h"

#include "glslprogram.h"
#include "mesh.h"

class Model {
public:
	Model(const std::string& path)
	{
		loadModel(path);
	}
	void Draw(GLSLProgram& shader);
private:
	// model data
	std::vector<Mesh> meshes;
	std::string directory;

	void loadModel(const std::string& path);
	void processNode(aiNode* node, const aiScene* scene);
	Mesh processMesh(aiMesh* mesh, const aiScene* scene);
};
