using System;

namespace Primary
{
    class Program
    {
        static void Main(string[] args)
        {
            string readStr = Console.ReadLine();
            int score = Convert.ToInt32(readStr);
            if (score > 50)
            {
                score++;
                Console.WriteLine("您输入的分数大于50" + "  " + score);
            }
            else
            {
                score--;
                Console.WriteLine("您输入的分数小于50" + score);
            }
            Console.ReadKey();

        }
    }
}
