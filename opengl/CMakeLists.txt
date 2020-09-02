project(opengl LANGUAGES CXX)

set(opengl_SOURCES
        openglogl.h
        glutils.cpp
        mesh.h mesh.cpp
        model.h model.cpp
        camera.h
        glslprogram.cpp
        scene.h
        glad/src/glad.c
        scenerunner.h
        texture.h texture.cpp
        tinyexr.h
        stbimpl.cpp
        imgui/imgui_impl_glfw.cpp
        imgui/imgui_impl_glfw.h
        imgui/imgui_impl_opengl3.cpp
        imgui/imgui_impl_opengl3.h
        imgui/imconfig.h
        imgui/imgui.cpp
        imgui/imgui.h
        imgui/imgui_demo.cpp
        imgui/imgui_draw.cpp
        imgui/imgui_internal.h
        imgui/imgui_widgets.cpp
        imgui/imstb_rectpack.h
        imgui/imstb_textedit.h
        imgui/imstb_truetype.h)

add_library(${PROJECT_NAME} STATIC ${opengl_SOURCES})

target_include_directories(${PROJECT_NAME} PUBLIC glad/include)

target_link_libraries(${PROJECT_NAME} PUBLIC glm)

target_link_libraries(${PROJECT_NAME} PRIVATE assimp::assimp)

IF (MSVC)
    target_link_libraries(${PROJECT_NAME} PUBLIC glm)
    target_link_libraries(${PROJECT_NAME} PUBLIC assimp::assimp)
else()
    target_link_libraries(${PROJECT_NAME} PUBLIC assimp)
    target_link_libraries(${PROJECT_NAME} PUBLIC ${CMAKE_DL_LIBS})
endif()



