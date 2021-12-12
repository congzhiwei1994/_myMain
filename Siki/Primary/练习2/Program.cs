using System;

namespace 练习2
{
    class Program
    {
        // 让用户输入两个整数，然后再输入0-3之间的一个数，0代表加，1代表-.*代表乘法
        static void Main(string[] args)
        {
            Console.WriteLine("请输入两个整数");
            int num1 = Convert.ToInt32(Console.ReadLine());
            int num2 = Convert.ToInt32(Console.ReadLine());
            int num3 = 0;

            Console.WriteLine("请再输入0~3之间的一个数");
            int a = Convert.ToInt32(Console.ReadLine());

           switch(a)
            {
                case 0:
                    num3 = num1 + num2;
                    break;
                case 1:
                    num3 = num1 - num2;
                    break;
                case 2:
                    num3 = num1 * num2;
                    break;
                case 3:
                    num3 = num1 / num2;
                    break;
                default:
                    Console.WriteLine("超出取值范围");
                    break;
            }
            Console.WriteLine(num3);
            Console.ReadKey();
        }
    }
}
