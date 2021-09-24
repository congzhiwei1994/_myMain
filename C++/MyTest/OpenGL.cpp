
#include <iostream>
#include "glfw3.h"
#include <GL/gl.h>
using namespace std;

int main()
{
  glfwInit(); // 初始化GLFW
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
  glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
  //glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);

  // 创建一个窗口对象，这个窗口对象存放了所有和窗口相关的数据，而且会被GLFW的其它函数频繁用到
  GLFWwindow *window = glfwCreateWindow(800, 600, "LearnOpenGL", NULL, NULL);
  if (window == NULL)
  {
    cout << "Faild to creat window" << endl;
  }

  return 0;
}