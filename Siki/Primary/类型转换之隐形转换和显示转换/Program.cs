using System;

namespace 类型转换之隐形转换和显示转换
{
    class Program
    {
        static void Main(string[] args)
        {
            byte myByte = 123;
            // 把一个小类型的数据赋值给大类型的变量时，编译器会自动进行类型转换。
            int myInt = myByte;

            // 把一个大类型的变量赋值给小类型的变量的时候，需要进行显示转换(强制类型换砖)
            // 就是加上括号，里面写需要转换的类型
            myByte = (byte)myInt;

        }
    }
}
