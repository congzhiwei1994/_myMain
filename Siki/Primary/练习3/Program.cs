using System;

namespace 练习3
{
    class Program
    {
        // 求出1~1000之间的所有能被7整除的数，并计算和输出每5个的和。
        static void Main(string[] args)
        {
            int count = 0;
            int sum = 0;
            for (int i = 1; i <= 1000; i++)
            {
                if( i%7 == 0)
                {
                    Console.WriteLine(i);
                    count++;
                    sum += i;
                    if (count == 5)
                    {
                        Console.WriteLine("每五个的和为" + sum);
                        count = 0;
                        sum = 0;
                    }
                }
            }
            Console.ReadKey();
        }
    }
}
