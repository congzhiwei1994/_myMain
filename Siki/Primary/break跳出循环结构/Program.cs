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
                    //  结束循环
                    break;
                }
                Console.WriteLine(num);
            }
         
        }
    }
}
