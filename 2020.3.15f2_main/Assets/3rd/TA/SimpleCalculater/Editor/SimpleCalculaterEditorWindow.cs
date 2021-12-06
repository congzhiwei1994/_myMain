using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


public class SimpleCalculaterEditorWindow : EditorWindow
{
    [MenuItem("TA/Simple Calculater")]
    private static void Open()
    {
        var window = GetWindow(typeof(SimpleCalculaterEditorWindow));
        window.Show();
    }

}
