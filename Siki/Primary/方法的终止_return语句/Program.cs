using System;

namespace 方法的终止_return语句
{
    class Program
    {
        static void Main(string[] args)
        {
            while(true)
            {
                int num = Convert.ToInt32(Console.ReadLine());
                if (num == 0)
                {
                    return;
                }
                Console.WriteLine("Hello World!");
            }
            Console.WriteLine("Hello World!");
        }
    }
}
