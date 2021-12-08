using System;

namespace 循环结构_do_while循环
{
    class Program
    {
        static void Main(string[] args)
        {
            string str = Console.ReadLine();
            int num = Convert.ToInt32(str);

            do
            {
                Console.WriteLine(num);
                num++;
            } while (num < 9);

            Console.ReadKey();
        }
    }
}
