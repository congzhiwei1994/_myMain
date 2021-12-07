using System;

namespace Switch语句
{
    class Program
    {
        // 定义一个int类型储存游戏状态，0代表开始界面，1战斗中，2暂停，3游戏胜利，4游戏失败
        static void Main(string[] args)
        {
            string str = Console.ReadLine();
            int state = Convert.ToInt32(str);
            switch (state)
            {
                case 0:
                    Console.WriteLine("开始");
                    break;
                case 1:
                    Console.WriteLine("战斗中");
                    break;
                case 2:
                    Console.WriteLine("暂停");
                    break;
                case 3:
                    Console.WriteLine("游戏胜利");
                    break;
                case 4:
                    Console.WriteLine("游戏失败");
                    break;
                default:
                    Console.WriteLine("超出取值范围");
                    break;
            }
            Console.ReadKey();
        }
    }
}
