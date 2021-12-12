using System;

namespace 练习10
{
    class Program
    {
        //一个控制台应用程序， 输出1~5的平方值， 要求：用for语句实现。用while语句实现。用do-while语包实现。
        static void Main(string[] args)
        {
            int a = 1;
            int num = 0;
            do
            {
                num = a * a;
                Console.WriteLine(num);
                a++;
            } while (a<6);
            Console.ReadKey();
        }
    }
}
