using System;

namespace 练习4
{
    class Program
    {
        // 编写一个控制台程序，分别输出1~100之间的平方、平方根
        static void Main(string[] args)
        {
            int a = 0;
            double b = 0;
            for (int i = 1; i <= 100; i++)
            {
                a = i * i;
                b = Math.Sqrt(i);
                Console.WriteLine("平方为" + a);
                Console.WriteLine("平方根为" + b);
            }
            Console.ReadKey();
        }
    }
}
