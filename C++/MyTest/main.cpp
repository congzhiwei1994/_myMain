#include <iostream>
#include <GL/gl.h>
#include "glfw3.h"

int main()
{
    intGLFW();
}

// 实例化GLFW窗口
int intGLFW()
{
    glfwInit();
    // 配置GLFW
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR,3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR,3);
    glfwWindowHint(GLFW_OPENGL_PROFILE,GLFW_OPENGL_CORE_PROFILE);
    return 0;
}

// 绘制三角形
int DrawTriangle()
{
    GLFWwindow *window;

    if (!glfwInit())
        return -1;

    window = glfwCreateWindow(480, 320, "TestOpenGL", NULL, NULL);

    if (!window)
    {
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);

    while (!glfwWindowShouldClose(window))
    {
        glBegin(GL_TRIANGLES);

        glColor3f(1.0, 0.0, 0.0);
        glVertex3f(0.0, 1.0, 0.0);

        glColor3f(0.0, 1.0, 0.0);
        glVertex3f(-1.0, -1.0, 0.0);

        glColor3f(1.0, 0.0, 1.0);
        glVertex3f(1.0, -1.0, 0.0);

        glEnd();

        glfwSwapBuffers(window);

        glfwPollEvents();
    }

    glfwTerminate();

    return 0;
}