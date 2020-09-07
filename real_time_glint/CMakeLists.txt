project(real_time_glint LANGUAGES CXX)
set(SHADER_PATH ${CMAKE_CURRENT_BINARY_DIR}/shader CACHE PATH "Path to shader directory")
set(MEDIA_PATH ${CMAKE_BINARY_DIR}/media CACHE PATH "Path to media directory")

set( real_time_glint_SOURCES
	main.cpp
	sceneglint.cpp sceneglint.h )

option(BUNDLE_MAC "Compile to App bundle format on OS/X" OFF)
if (BUNDLE_MAC)
	add_executable( ${PROJECT_NAME} MACOSX_BUNDLE ${real_time_glint_SOURCES} )
else()
	add_executable( ${PROJECT_NAME} ${real_time_glint_SOURCES} )
endif()

target_compile_definitions(${PROJECT_NAME}
		PRIVATE
		GLFW_INCLUDE_NONE
		-DSHADER_PATH=std::string\(\"${SHADER_PATH}/\"\)
		-DMEDIA_PATH=std::string\(\"${MEDIA_PATH}/\"\)
		)

target_link_libraries( ${PROJECT_NAME}
		PRIVATE
		opengl
		glfw
		${OPENGL_gl_LIBRARY}
		)

file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/shader DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
