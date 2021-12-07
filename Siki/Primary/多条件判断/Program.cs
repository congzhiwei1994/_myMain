using System;

namespace 多条件判断
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("你考了多少分？(0~100)");
            string readStr = Console.ReadLine();
            int sore = Convert.ToInt32(readStr);
            if (sore >= 90 && sore <= 100)
            {
                Console.WriteLine("优");
            }
            else if (sore >= 80 && sore < 90)
            {
                Console.WriteLine("良");
            }
            else if (sore >= 60 && sore < 80)
            {
                Console.WriteLine("中");
            }
            else
                Console.WriteLine("差");
            Console.ReadKey();
        }
    }
}
