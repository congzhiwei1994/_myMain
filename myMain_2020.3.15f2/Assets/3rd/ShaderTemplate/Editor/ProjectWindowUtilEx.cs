using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEditor.ProjectWindowCallback;
using UnityEngine;
public class ProjectWindowUtilEx {

    [MenuItem ("Assets/Create/Shader/URP/SimpleLit")]
    static void CreateUrpSimpleLitShader () {
        string path = Application.dataPath + "/3rd/ShaderTemplate/Editor/Template/SimpleLit.shader";
        ProjectWindowUtilEx.CreateScriptUtil (path, "New SimpleLit.shader");
    }

    [MenuItem ("Assets/Create/Shader/URP/LitShader")]
    static void CreateUrpLitShader () {
        string path = Application.dataPath + "/3rd/ShaderTemplate/Editor/Template/LitURPShader.shader";
        ProjectWindowUtilEx.CreateScriptUtil (path, "New LitShader.shader");
    }

    [MenuItem ("Assets/Create/Shader/URP/UnlitShader")]
    static void CreateUrpUnLitShader () {
        string path = Application.dataPath + "/3rd/ShaderTemplate/Editor/Template/UnlitURPShader.shader";
        ProjectWindowUtilEx.CreateScriptUtil (path, "New UnlitShader.shader");
    }

    public static void CreateScriptUtil (string path, string templete) {
        ProjectWindowUtil.CreateScriptAssetFromTemplateFile (path, templete);
    }

}