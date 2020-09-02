set(target opengl)

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

add_library(${target} STATIC ${opengl_SOURCES})

target_include_directories(${target} PUBLIC glad/include)

target_link_libraries(${target} PUBLIC glm)

target_link_libraries(${target} PRIVATE assimp::assimp)

if( UNIX AND NOT APPLE )
    target_link_libraries(${target} PUBLIC ${CMAKE_DL_LIBS})
endif()


