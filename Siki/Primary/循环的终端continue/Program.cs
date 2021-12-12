using System;

namespace 循环的终端continue
{
    class Program
    {
        // 接受用户输入的整数，如果用户输入的是大于0的整数就像加，
        //如果用户输入的是大于0的奇数就不相加，
        // 如果用户输入的是0，就把所有偶数的和输出并且退出程序。
        static void Main(string[] args)
        {
            int a = 0;
            while (true)
            {
                string str = Console.ReadLine();
                int num = Convert.ToInt32(str);
                if (num > 0 && num % 2 == 0)
                {
                   a += num;
                    continue;
                }
                else if (num > 0 && num % 2 != 0)
                {
                    continue;
                }
                else if (num == 0)
                {
                    Console.WriteLine(a);
                    break;
                }

            }
            Console.ReadKey();
        }

    }
}
