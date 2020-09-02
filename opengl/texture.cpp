#define TINYEXR_IMPLEMENTATION

#include "texture.h"
#include "stb/stb_image.h"
#include "glutils.h"
#include "tinyexr.h"
#include <cmath>
#include <iostream>

const char* err = nullptr;

GLuint Texture::loadMultiscaleMarginalDistributions(const std::string& baseName, const unsigned int nlevels, const GLsizei ndists)
{
	GLuint texID;
	glGenTextures(1, &texID);
	glBindTexture(GL_TEXTURE_1D_ARRAY, texID);

	GLint width;
	GLint height;
	GLsizei layerCount = ndists * nlevels;
	GLsizei mipLevelCount = 1;

	// Load the first one to get width/height
	std::string texName = baseName + "_0000" + "_" + "0000" + ".exr";
	float* data;
	bool ret = exrio::LoadEXRRGBA(&data, &width, &height, texName.c_str(), err);
	if (!ret) {
		exit(-1);
	}

	// Allocate the storage
	glTexStorage2D(GL_TEXTURE_1D_ARRAY, mipLevelCount, GL_RGB16F, width, layerCount);

	// Upload pixel data
	// The first 0 refers to the mipmap level (level 0)
	// The following zero refers to the x offset in case you only want to specify a subrectangle
	// The final 0 refers to the layer index offset (we start from index 0)
	glTexSubImage2D(GL_TEXTURE_1D_ARRAY, 0, 0, 0, width, 1, GL_RGBA, GL_FLOAT, data);

	free(data);

	// Load the other 1D distributions
	for (int l = 0; l < nlevels; ++l) {
		std::string index_level;
		if (l < 10)
			index_level = "000" + std::to_string(l);
		else if (l < 100)
			index_level = "00" + std::to_string(l);
		else if (l < 1000)
			index_level = "0" + std::to_string(l);
		else
			index_level = std::to_string(l);

		for (int i = 0; i < ndists; i++) {

			if (l == 0 && i == 0) continue;

			std::string index_dist;
			if (i < 10)
				index_dist = "000" + std::to_string(i);
			else if (i < 100)
				index_dist = "00" + std::to_string(i);
			else if (i < 1000)
				index_dist = "0" + std::to_string(i);
			else
				index_dist = std::to_string(i);

			texName = baseName + "_" + index_dist + "_" + index_level + ".exr";
			bool ret = exrio::LoadEXRRGBA(&data, &width, &height, texName.c_str(), err);
			if (!ret) {
				exit(-1);
			}
			glTexSubImage2D(GL_TEXTURE_1D_ARRAY, 0, 0, l * ndists + i, width, 1, GL_RGBA, GL_FLOAT, data);
			free(data);
		}
	}

	glTexParameteri(GL_TEXTURE_1D_ARRAY, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_1D_ARRAY, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_1D_ARRAY, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);

	return texID;
}
