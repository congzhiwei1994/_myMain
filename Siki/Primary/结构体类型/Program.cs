using System;

namespace 结构体类型
{
    class Program
    {
        // 结构体定义， 可以理解为把几个类型组成一个新的类型
        struct Position
        {
            public float x;
            public float y;
            public float z;
        }
        static void Main(string[] args)
        {
            // 声明结构体
            Position position;
            // 访问结构体里面的变量并且赋值
            position.x = 43;

            Console.WriteLine("Hello World!");
        }
    }
}
