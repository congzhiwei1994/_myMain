using UnityEngine;
using System.Collections.Generic;
using System;
using UnityEditor;

namespace FastOpenScene
{

    [CreateAssetMenu(fileName = "Assets/3rd/FastOpenScene/Editor/ScenePath.asset", menuName = "XunShan/FastOpenScene/ScenePath Asset")]
    [Serializable]
    public class ScenePathList : ScriptableObject
    {
        [SerializeField]
        public List<SceneAsset> assetList = new List<SceneAsset>();

#if UNITY_EDITOR
        public static ScenePathList Load()
        {
            string[] guids = UnityEditor.AssetDatabase.FindAssets("t:ScenePathList");
            if (guids.Length == 0)
            {
                Debug.LogWarning("Could not find ScenePathList asset. Will use default settings instead.");
                return ScriptableObject.CreateInstance<ScenePathList>();
            }
            else
            {
                string path = UnityEditor.AssetDatabase.GUIDToAssetPath(guids[0]);
                return UnityEditor.AssetDatabase.LoadAssetAtPath<ScenePathList>(path);
            }
        }
#endif
    }
}