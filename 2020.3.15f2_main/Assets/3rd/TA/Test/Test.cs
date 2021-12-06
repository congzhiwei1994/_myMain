using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Test : MonoBehaviour
{
    private float score;
    TestB testB = new TestB();
}

struct TestB
{
    public float test;
    public TestB(float temp)
    {
        test = temp;
    }
}


class TestA
{
    private float score;
    public float Score
    {
        get { return score; }
        set
        {
            if (value >= 0)
            {
                score = value;
            }
            else
            {
                Debug.Log("不存在");
            }
        }
    }
}

