using System;

namespace break跳出循环结构
{
    class Program
    {
        static void Main(string[] args)
        {

            while (true)
            {
                string str = Console.ReadLine();
                int num = Convert.ToInt32(str);
                if (num == 0)
                {
                    //  使用break跳出最近的一次循环结构
                    break;
                }
                Console.WriteLine(num);

            }
         
        }
    }
}
