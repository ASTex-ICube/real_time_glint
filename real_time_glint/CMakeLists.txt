set(target real_time_glint)
set( real_time_glint_SOURCES
	main.cpp
	sceneglint.cpp sceneglint.h )

add_executable( ${target} ${real_time_glint_SOURCES} )

target_compile_definitions(${target}
		PRIVATE
		GLFW_INCLUDE_NONE
		)

target_link_libraries( ${target}
		PRIVATE
		opengl
		glfw
		${OPENGL_gl_LIBRARY}
		)

file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/shader DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
