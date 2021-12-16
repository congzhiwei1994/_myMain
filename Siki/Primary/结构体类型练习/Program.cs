using System;

namespace 结构体类型练习
{
    // 定义一个表示路径的结构，路径有一个方向和距离组成，假定方向只能是东西南北
    enum Dir
    {
        West,
        East,
        North,
        South
    }
    struct Path
    {
        public Dir dir;
        public float distance;
    }

    class Program
    {
        static void Main(string[] args)
        {
            Path path;
            path.dir = Dir.North;
            path.distance = 1000;
        }
    }
}
