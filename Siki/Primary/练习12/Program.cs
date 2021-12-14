using System;

namespace 练习12
{
    class Program
    {
        static void Main(string[] args)
        {
 
            while(true)
            {
                //bool isTrue = true;
                Console.WriteLine("请输入一个整数");
                string str = Console.ReadLine();

                int num = Convert.ToInt32(str);
                if (num > 0)
                {
                    for (int i = 1; i < num + 1; i++)
                    {
                        Console.WriteLine(i);
                    }
                    break;
                }
                if (num < 0)
                {
                    return;
                }

                if (num == 0)
                {
                    //num = 1;
                }
            }
            Console.ReadKey();
        }
    }
}
