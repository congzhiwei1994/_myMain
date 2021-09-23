#include <iostream>  // 引入iostream库 头文件
using namespace std; // 引入命名空间

// 函数需要先声明再调用
void Num();
void Hello();
void Mul();
void WhileNum();
void WhileSub();
void ForNum();
void ForNumA();
void whileNumA();

int main()
{
    /* 函数的调用
    Num();
    Hello();
    Mul();
    WhileNum();
*/

    whileNumA();
    return 0;
}

void whileNumA()
{
    int value;
    int num = 0;
    while (cin >> value)
    {
        num += value;
    }
    cout << num << endl;
}

void WhileNum()
{
    int v1 = 50;
    int sum = 0;
    while (v1 <= 100)
    {
        sum += v1;
        ++v1;
    }
    cout << "和为 " << sum << endl;
    cin >> v1;
}

void WhileSub()
{
    int val = 10;
    int num = 0;
    while (val <= 10 && val >= 0)
    {
        num = val;
        cout << num << endl;
        --val;
    }
    cin >> val;
}

void ForNumA()
{
    int num = 0;
    for (int i = 50; i <= 100; ++i)
    {
        num += i;
    }

    cout << num << endl;
    cin >> num;
}

void ForNum()
{
    int sum = 0;
    for (int i = 1; i <= 10; ++i)
    {
        sum += i;
    }
    cout << sum << endl;
    cin >> sum;
}

void Mul()
{
    int v1, v2;
    cin >> v1 >> v2;
    cout << "积为：  " << v1 * v2 << endl;
    cin >> v1;
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
    cout << "请输入两个数字:" << endl;
    int v1 = 0, v2 = 0;
    cin >> v1 >> v2;
    cout << "the number of" << v1 << "and" << v2
         << "is " << v1 + v2 << endl;
    cin >> v1; // 输入一个数字进行关闭cmd窗口
}
