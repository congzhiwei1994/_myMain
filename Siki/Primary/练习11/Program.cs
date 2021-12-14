using System;

namespace 练习11
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("请输入5个大写字母");
    
            while (true)
            {
                bool isAllUpperChar = true;
                string str = Console.ReadLine();
                for (int i = 0; i < 5; i++)
                {
                    if (str[i] >= 'A' && str[i] <= 'Z')
                    {
                        isAllUpperChar = true;
                    }
                    else
                    {
                        isAllUpperChar = false;
                        break;
                    }
                }
                if (isAllUpperChar == true)
                {
                    Console.WriteLine("输入正确");
                    break;
                }
                else
                {
                    Console.WriteLine("输入不正确");
                }
            }
            Console.ReadKey();
        }
    }
}
