using System;

namespace 循环的终端continue
{
    class Program
    {
        static void Main(string[] args)
        {
            int a = 1;
            while (true)
            {
                a++;
                if(a ==5)
                {
                    Console.WriteLine("consinue" + a);
                    continue;
                }
                if (a == 10)
                {
                    break;
                }
                Console.WriteLine(a);
            }
           
        }
    }
}
