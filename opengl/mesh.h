// https://learnopengl.com/Model-Loading/Mesh

#pragma once

#include "openglogl.h"

#include <vector>
#include <glm/glm.hpp>
#include <string>
#include <memory>

#include "glslprogram.h"

struct Vertex {
    // position
    glm::vec3 Position;
    // normal
    glm::vec3 Normal;
    // texCoords
    glm::vec2 TexCoords;
    // tangent
    glm::vec3 Tangent;
};

class Mesh {
public:
    // mesh data
    std::vector<Vertex>       vertices;
    std::vector<unsigned int> indices;
    unsigned int VAO;
    std::string name;

    Mesh(std::vector<Vertex> vertices, std::vector<unsigned int> indices, const std::string& name);
    void Draw(GLSLProgram& shader);
private:
    //  render data
    unsigned int VBO, EBO;

    void setupMesh();
};
