using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;
using System.IO;

namespace FastOpenScene
{
    public class FastOpenSceneWin : EditorWindow
    {
        private ScenePathList pathList;
        private string m_SearchContent = "";
        private Vector2 m_ScPos = Vector2.zero;
        private OpenSceneMode m_OpenMode = OpenSceneMode.Single;
        private Dictionary<string, string> m_SceneDict = new Dictionary<string, string>();
        private int m_CurrPickerControlID = -1;

        [MenuItem("Tools/Fast Open Scene Window &s")]
        public static void InitWinEditor()
        {
            var window = (FastOpenSceneWin)EditorWindow.GetWindow<FastOpenSceneWin>();
            window.titleContent = new GUIContent("Fast Open Scene");
            window.Show();
        }

        private void OnEnable()
        {
            pathList = ScenePathList.Load();

            InitSceneAssets();
        }

        private void InitSceneAssets()
        {
            m_SceneDict.Clear();
            for (var i = pathList.assetList.Count - 1; i >= 0; i--)
            {
                var asset = pathList.assetList[i];
                if (asset == null)
                {
                    pathList.assetList.RemoveAt(i);
                }
                else
                {
                    m_SceneDict.Add(asset.name, AssetDatabase.GetAssetPath(asset));
                }
            }
        }

        private void OnDisable()
        {
            m_SearchContent = "";
            if (m_SceneDict != null)
            {
                m_SceneDict.Clear();
            }
        }

        private void OnGUI()
        {
            DrawSceneListGUI();
            HandleObjectPickEvent();
        }

        void DrawSceneListGUI()
        {
            EditorGUILayout.BeginVertical();
            {
                m_SearchContent = EditorGUILayout.TextField("Search", m_SearchContent).ToLower();
                m_OpenMode = (OpenSceneMode)EditorGUILayout.EnumPopup("Open Mode", m_OpenMode);

                m_ScPos = EditorGUILayout.BeginScrollView(m_ScPos);
                {
                    foreach (var item in m_SceneDict)
                    {
                        if (item.Key.ToLower().Contains(m_SearchContent))
                        {
                            EditorGUILayout.BeginHorizontal();
                            EditorGUILayout.LabelField(item.Key, GUILayout.Width(120));
                            GUILayout.FlexibleSpace();
                            if (GUILayout.Button("Ping", GUILayout.Width(50)))
                            {
                                var sceneObject = AssetDatabase.LoadMainAssetAtPath(item.Value);
                                Selection.activeObject = sceneObject;
                                EditorGUIUtility.PingObject(sceneObject);
                            }
                            if (GUILayout.Button("Open", GUILayout.Width(50)))
                            {
                                EditorSceneManager.OpenScene(item.Value, m_OpenMode);
                            }
                            EditorGUILayout.EndHorizontal();

                            var rect = GUILayoutUtility.GetLastRect();
                            rect.y += rect.height;
                            rect.height = 1;
                            EditorGUI.DrawRect(rect, new Color(0.66f, 0.66f, 0.66f, 1));
                        }
                    }

                    EditorGUILayout.BeginHorizontal();
                    {
                        GUILayout.FlexibleSpace();

                        if (GUILayout.Button(new GUIContent("◕", "Refresh"), GUILayout.Width(23)))
                        {
                            InitSceneAssets();
                        }

                        if (GUILayout.Button(new GUIContent("+", "Add"), GUILayout.Width(23)))
                        {
                            m_CurrPickerControlID = EditorGUIUtility.GetControlID(FocusType.Passive) + 100;
                            EditorGUIUtility.ShowObjectPicker<SceneAsset>(null, false, "", m_CurrPickerControlID);
                            return;
                        }
                    }
                    EditorGUILayout.EndHorizontal();
                }
                EditorGUILayout.EndScrollView();
            }
            EditorGUILayout.EndVertical();
        }

        void HandleObjectPickEvent()
        {
            var commandName = Event.current.commandName;
            if (commandName == "ObjectSelectorUpdated")
            {
                Repaint();
            }
            
            if (commandName != "ObjectSelectorClosed" && EditorGUIUtility.GetObjectPickerControlID() != m_CurrPickerControlID)
            {
                return;
            }

            m_CurrPickerControlID = -1;

            var asset = EditorGUIUtility.GetObjectPickerObject() as SceneAsset;
            if (asset == null)
            {
                return;
            }

            if (m_SceneDict.ContainsKey(asset.name))
            {
                return;
            }

            m_SceneDict[asset.name] = AssetDatabase.GetAssetPath(asset);

            pathList.assetList.Add(asset);
            EditorUtility.SetDirty(pathList);
        }
    }
}