using System;

namespace 三元运算符
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello World!");
            int sore = 20;
            string str = (sore < 10) ? "小于10" : "大于10";
            Console.WriteLine(str);
            Console.ReadKey();
        }
    }
}
