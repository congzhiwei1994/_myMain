using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteInEditMode]
public class JeffordPlanarReflection : MonoBehaviour
{
    public LayerMask layerMask = -1;
    public bool isRenderSky = false;
    public bool isHideReflectionCam = false;
    [Range(-2f, 3f)] public float reflectionPlaneOffset;


    void OnEnable()
    {
        // 在 SRP 开始 Camera 渲染之前执行每个摄像机的渲染逻辑或操作, 每帧执行一次
        // RenderPipelineManager.beginCameraRendering += DoPlanarReflections;
    }

    private void DoPlanarReflections(ScriptableRenderContext context, Camera camera)
    {

        if (camera.cameraType == CameraType.Reflection || camera.cameraType == CameraType.Preview)
            return;

        // 当前正在用于渲染的摄像机，仅用于低级别渲染控制
        Camera currentCam = Camera.current;
        if (currentCam == null)
            return;

        // 判断当前相机的Tag
#if !UNITY_EDITOR
if (!currentCam.gameObject.CompareTag("MainCamera"))
return;
#endif
        ReflectionCameraSetting(currentCam);

    }


    /// <summary>
    /// 设置反射相机
    /// </summary>
    /// <param name="cam"></param>
    /// <returns></returns>
    void ReflectionCameraSetting(Camera currentCam)
    {
        Camera refCam = IntRefCamera(currentCam);
        ReflectionTargetSetting();
        UpdateRefCamera(currentCam, refCam);
    }


    /// <summary>
    /// 初始化反射相机
    /// </summary>
    /// <param name="cam"></param>
    /// <returns></returns>
    private Camera IntRefCamera(Camera currentCam)
    {
        var go = new GameObject("", typeof(Camera));
        go.name = "Reflection Camera [" + go.GetInstanceID() + "]";

        var camData = go.AddComponent(typeof(UnityEngine.Rendering.Universal.UniversalAdditionalCameraData)) as UnityEngine.Rendering.Universal.UniversalAdditionalCameraData;
        camData.requiresColorOption = CameraOverrideOption.Off;
        camData.requiresDepthOption = CameraOverrideOption.Off;
        camData.SetRenderer(0);

        var refCamera = go.AddComponent<Camera>();
        // 不生成深度纹理
        refCamera.depthTextureMode = DepthTextureMode.None;
        refCamera.allowHDR = false;
        refCamera.useOcclusionCulling = false;
        refCamera.allowMSAA = false;
        refCamera.cullingMask = layerMask;
        refCamera.clearFlags = CameraClearFlags.SolidColor;
        refCamera.enabled = false;
        refCamera.backgroundColor = Color.black;

        // 设置反射相机的位置
        Vector3 refCamPos = currentCam.gameObject.transform.position;
        var refRotation = currentCam.gameObject.transform.rotation;
        refCamera.transform.SetPositionAndRotation(refCamPos, refRotation);

        return refCamera;
    }


    /// <summary>
    /// 设置反射平面
    /// </summary>
    void ReflectionTargetSetting()
    {
        // 获取当前平面
        var refTarget = this.transform;
        Vector3 pos = Vector3.zero;
        pos = refTarget.position + Vector3.up * reflectionPlaneOffset;
        pos.y = refTarget.position.y;

        Vector3 normal = refTarget.transform.up;

        var d = -Vector3.Dot(normal, pos);
        var refPlane = new Vector4(normal.x, normal.y, normal.z, d);

        var reflection = Matrix4x4.identity;
        reflection *= Matrix4x4.Scale(new Vector3(1, -1, 1));

    }


    void UpdateRefCamera(Camera currentCam, Camera refCam)
    {
        // 复制原相机设置
        refCam.CopyFrom(currentCam);
        // 渲染期间，摄像机是否使用遮挡剔除
        refCam.useOcclusionCulling = false;

        // 反射相机是否有 UniversalAdditionalCameraData组件
        if (refCam.gameObject.TryGetComponent(out UniversalAdditionalCameraData cameraData))
        {
            // 不渲染阴影
            cameraData.renderShadows = false;
            // 控制反射相机是否渲染天空盒
            if (isRenderSky)
            {
                refCam.clearFlags = CameraClearFlags.Skybox;
            }
            else
            {
                refCam.clearFlags = CameraClearFlags.SolidColor;
                refCam.backgroundColor = Color.black;
            }
        }

        refCam.gameObject.hideFlags = isHideReflectionCam ? HideFlags.HideAndDontSave : HideFlags.DontSave;

    }



    public static void CalculateReflectionMatrix(ref Matrix4x4 reflectionMatrix, Vector4 plane)
    {
        reflectionMatrix.m00 = (1F - 2F * plane[0] * plane[0]);
        reflectionMatrix.m01 = (-2F * plane[0] * plane[1]);
        reflectionMatrix.m02 = (-2F * plane[0] * plane[2]);
        reflectionMatrix.m03 = (-2F * plane[3] * plane[0]);

        reflectionMatrix.m10 = (-2F * plane[1] * plane[0]);
        reflectionMatrix.m11 = (1F - 2F * plane[1] * plane[1]);
        reflectionMatrix.m12 = (-2F * plane[1] * plane[2]);
        reflectionMatrix.m13 = (-2F * plane[3] * plane[1]);

        reflectionMatrix.m20 = (-2F * plane[2] * plane[0]);
        reflectionMatrix.m21 = (-2F * plane[2] * plane[1]);
        reflectionMatrix.m22 = (1F - 2F * plane[2] * plane[2]);
        reflectionMatrix.m23 = (-2F * plane[3] * plane[2]);

        reflectionMatrix.m30 = 0F;
        reflectionMatrix.m31 = 0F;
        reflectionMatrix.m32 = 0F;
        reflectionMatrix.m33 = 1F;
    }



}
