using System;

namespace 练习6
{
    class Program
    {
        // 编程输出1~100中能被3整除但不能被5整除的数，并统计有多少个这样的数
        static void Main(string[] args)
        {
            for (int i = 1; i <= 100; i++)
            {
                if (i % 3 == 0 && i % 5 != 0)
                {
                    Console.WriteLine(i);
                }
            }
            Console.ReadKey();
        }
    }
}
