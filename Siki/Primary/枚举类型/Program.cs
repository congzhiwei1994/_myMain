using System;
namespace 枚举类型
{
    // 定义枚举
    // 枚举默认是以int整型进行存储的，加 :byte 可以更改为以 byte进行存储。
    enum GameState:byte // 修改该枚举的存储类型，默认为int类型
    {
        Pause, // 默认代表 int 0
        Filed, // 默认代表 int 1
        Success, // 默认代表 int 2
        Start // 默认代表 int 3
    }
    class Program
    {
        static void Main(string[] args)
        {
            // 枚举类型的声明
            GameState gameState = GameState.Start;
            int num = (int)gameState; // 强制转换成int类型
            Console.WriteLine(gameState);
            Console.ReadKey();
        }
    }
}
 