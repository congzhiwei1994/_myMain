using System;

namespace 循环结构_for循环
{
    class Program
    {
        static void Main(string[] args)
        {
            string str = Console.ReadLine();
            int num = Convert.ToInt32(str);

            for (int index = 0; index <= 9; index++)
            {
                Console.WriteLine(index);
            }

            Console.ReadKey();
        }
    }
}
