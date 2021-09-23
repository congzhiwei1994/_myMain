#include <iostream>  // 引入iostream库 头文件
using namespace std; // 引入命名空间

void Num();
void Hello();

int main()
{
    Num();
    Hello();

    return 0;
}

void Hello()
{
    int v1;
    cin >> v1;
    cout << "Hello World";
    cin >> v1;
}

void Num()
{
    cout << "Enter two numbers:" << endl;
    int v1 = 0, v2 = 0;
    cin >> v1 >> v2;
    cout << "the number of" << v1 << "and" << v2
         << "is " << v1 + v2 << endl;
    cin >> v1; // 输入一个数字进行关闭cmd窗口
}
