using System;

namespace 练习8
{
    class Program
    {
        // 编程输出九九乘法表。
        static void Main(string[] args)
        {
            for (int i = 1; i <= 9; i++)
            {
                for (int j = i; j < 10; j++)
                {
                    Console.Write(i+"*"+j+"=" +(i*j) + " ");
                }
                Console.WriteLine();
            }
            Console.ReadKey();
        }
    }
}
