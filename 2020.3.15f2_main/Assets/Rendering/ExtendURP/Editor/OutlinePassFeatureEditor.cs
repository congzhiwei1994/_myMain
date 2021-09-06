using System.Linq;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace Rendering.ExtendURP
{
    [CustomPropertyDrawer(typeof(OutlinePassFeature.Settings), true)]
    public class OutlinePassFeatureEditor : PropertyDrawer
    {
        internal class Styles
        {
            public static float defaultLineSpace = EditorGUIUtility.singleLineHeight + EditorGUIUtility.standardVerticalSpacing;
            public static GUIContent callback = new GUIContent("事件", "Choose at which point this render pass is executed in the frame.");

            //Headers
            public static GUIContent filtersHeader = new GUIContent("过滤Renderer条件", "Settings that control which objects should be rendered.");

            //Filters
            public static GUIContent layerMask = new GUIContent("Layer Mask", "Only render objects in a layer that match the given layer mask.");
        }

        //Headers and layout
        private HeaderBool m_FiltersFoldout;
        private const int m_FilterLines = 1;

        // Serialized Properties
        private SerializedProperty m_Callback;
        private SerializedProperty m_PassTag;
        //Filter props
        private SerializedProperty m_FilterSettings;
        private SerializedProperty m_LayerMask;

        private List<SerializedObject> m_properties = new List<SerializedObject>();


        private void Init(SerializedProperty property)
        {
            //Header bools
            var key = $"{this.ToString().Split('.').Last()}.{property.serializedObject.targetObject.name}";
            m_FiltersFoldout = new HeaderBool($"{key}.FiltersFoldout", true);

            m_Callback = property.FindPropertyRelative("Event");
            //m_PassTag = property.FindPropertyRelative("passTag");

            //Filter props
            m_FilterSettings = property.FindPropertyRelative("filterSettings");
            m_LayerMask = m_FilterSettings.FindPropertyRelative("LayerMask");

            m_properties.Add(property.serializedObject);
        }

        public override void OnGUI(Rect rect, SerializedProperty property, GUIContent label)
        {
            rect.height = EditorGUIUtility.singleLineHeight;
            EditorGUI.BeginChangeCheck();
            EditorGUI.BeginProperty(rect, label, property);

            if (!m_properties.Contains(property.serializedObject))
            {
                Init(property);
            }

            //var passName = property.serializedObject.FindProperty("m_Name").stringValue;
            //if (passName != m_PassTag.stringValue)
            //{
            //    m_PassTag.stringValue = passName;
            //    property.serializedObject.ApplyModifiedProperties();
            //}

            //Forward Callbacks
            EditorGUI.PropertyField(rect, m_Callback, Styles.callback);
            rect.y += Styles.defaultLineSpace;

            DoFilters(ref rect);

            //m_RenderFoldout.value = EditorGUI.Foldout(rect, m_RenderFoldout.value, Styles.renderHeader, true);
            //SaveHeaderBool(m_RenderFoldout);
            //rect.y += Styles.defaultLineSpace;
            //if (m_RenderFoldout.value)
            //{
            //    EditorGUI.indentLevel++;
            //    //Override material
            //    DoMaterialOverride(ref rect);
            //    rect.y += Styles.defaultLineSpace;
            //    //Override depth
            //    DoDepthOverride(ref rect);
            //    rect.y += Styles.defaultLineSpace;
            //    //Override stencil
            //    EditorGUI.PropertyField(rect, m_OverrideStencil);
            //    rect.y += EditorGUI.GetPropertyHeight(m_OverrideStencil);
            //    //Override camera
            //    DoCameraOverride(ref rect);
            //    rect.y += Styles.defaultLineSpace;

            //    EditorGUI.indentLevel--;
            //}

            EditorGUI.EndProperty();
            if (EditorGUI.EndChangeCheck())
                property.serializedObject.ApplyModifiedProperties();
        }

        public override float GetPropertyHeight(SerializedProperty property, GUIContent label)
        {
            float height = Styles.defaultLineSpace;

            Init(property);
            height += Styles.defaultLineSpace * (m_FiltersFoldout.value ? m_FilterLines : 1);

            height += Styles.defaultLineSpace; // add line for overrides dropdown
            

            return height;
        }

        void DoFilters(ref Rect rect)
        {
            m_FiltersFoldout.value = EditorGUI.Foldout(rect, m_FiltersFoldout.value, Styles.filtersHeader, true);
            SaveHeaderBool(m_FiltersFoldout);
            rect.y += Styles.defaultLineSpace;
            if (m_FiltersFoldout.value)
            {
                EditorGUI.indentLevel++;

                //Layer mask
                EditorGUI.PropertyField(rect, m_LayerMask, Styles.layerMask);
                rect.y += Styles.defaultLineSpace;
               
                EditorGUI.indentLevel--;
            }
        }

        private void SaveHeaderBool(HeaderBool boolObj)
        {
            EditorPrefs.SetBool(boolObj.key, boolObj.value);
        }

        class HeaderBool
        {
            public string key;
            public bool value;

            public HeaderBool(string _key, bool _default = false)
            {
                key = _key;
                if (EditorPrefs.HasKey(key))
                    value = EditorPrefs.GetBool(key);
                else
                    value = _default;
                EditorPrefs.SetBool(key, value);
            }
        }
    }
}