
#include "openglogl.h"
#include <string>

class Texture {
public:
    static GLuint loadMultiscaleMarginalDistributions(const std::string& baseName, const unsigned int nlevels, const GLsizei ndists);
};