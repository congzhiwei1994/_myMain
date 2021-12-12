using System;

namespace 练习9
{
    class Program
    {
        // 编写一个掷筛子100次的程序，并打印出各种点数的出现次数。
        static void Main(string[] args)
        {
            int num1 = 0, num2 = 0, num3 = 0, num4 = 0, num5 = 0, num6 = 0;
            Random random = new Random();
            for (int i = 0; i < 100; i++)
            {
                int num = random.Next(1, 7);
                switch (num)
                {
                    case 1:
                        num1++;
                        break;
                    case 2:
                        num2++;
                        break;
                    case 3:
                        num3++;
                        break;
                    case 4:
                        num4++;
                        break;
                    case 5:
                        num5++;
                        break;
                    case 6:
                        num6++;
                        break;
                }
            }
            Console.WriteLine("1点" + ":" + num1 + " " + "2点" + ":" + num2 + " " + "3点" + ":" + num3 + " " + "4点" + ":" + num4 + " " + "5点" + ":" + num5 + " " + "6点" + ":" + num6 + " ");
            Console.ReadKey();

        }
    }
}
