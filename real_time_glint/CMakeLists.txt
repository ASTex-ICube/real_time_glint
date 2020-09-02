
project(real_time_glint LANGUAGES CXX)
set( real_time_glint_SOURCES
	main.cpp
	sceneglint.cpp sceneglint.h )

add_executable( ${PROJECT_NAME} ${real_time_glint_SOURCES} )

target_compile_definitions(${PROJECT_NAME}
		PRIVATE
		GLFW_INCLUDE_NONE
		)

target_link_libraries( ${PROJECT_NAME}
		PRIVATE
		opengl
		glfw
		${OPENGL_gl_LIBRARY}
		)

file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/shader DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
