using System;

namespace 循环结构_While循环
{
    class Program
    {
        static void Main(string[] args)
        {
            string str = Console.ReadLine();
           int num = Convert.ToInt32(str);
            while (num<9)
            {
                Console.WriteLine(num);
                num++;
            }
            Console.ReadKey();
        }

    }
}
