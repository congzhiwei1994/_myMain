using System;

namespace 练习1
{
    class Program
    {
        // 编写一个程序，对输入的4个整数，求出其中的最大值和最小值，并显示出来。
        static void Main(string[] args)
        {
            int maxNum;
            int minNum;
            int num1 = Convert.ToInt32(Console.ReadLine());
            int num2 = Convert.ToInt32(Console.ReadLine());
            int num3 = Convert.ToInt32(Console.ReadLine());
            int num4 = Convert.ToInt32(Console.ReadLine());
            if (num1 > num2)
            {
                maxNum = num1;
                minNum = num2;
            }
            else
            {
                maxNum = num2;
                minNum = num1;
            }
            if (num3 > maxNum)
            {
                maxNum = num3;
            }
            if (num3 < minNum)
            {
                minNum = num3;
            }

            if (num4 > maxNum)
            {
                maxNum = num4;
            }
            if (num4 < minNum)
            {
                minNum = num4;
            }
            Console.WriteLine("最大值是" + maxNum + "最小值是" + minNum);
            Console.ReadKey();
        }
    }
}
