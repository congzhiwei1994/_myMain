using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

/// <summary>
/// 此类为相机管理类，进行单个相机的单独渲染，把渲染的处理逻辑封装到此类。
/// </summary>
public class CameraRenderer {
    ScriptableRenderContext context;
    Camera camera;

    const string bufferName = "Render Camera";

    // 创建一个CommandBuffer实例来获得缓冲区，只需一个缓冲区即可。
    // 实例时给CommandBuffer起个名字，用于在Frane Debugger识别
    CommandBuffer buffer = new CommandBuffer {
        name = bufferName
    };

    // 储存剔除后的结果数据
    CullingResults cullingResults;

    // 获取pass名为SRPDefaultUnlit的着色器标识ID
    ShaderTagId unlitShaderTagId = new ShaderTagId ("SRPDefaultUnlit");

    ///////////////////////////////////////////////////////////////////////////////
    //                            方法
    //////////////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// 此方法为相机的Render方法。用来绘制在相机视野内的所有物体。
    /// </summary>
    /// <param name="context">是一个command buffer对象，可以向其输入您想执行的渲染指令。
    /// context：只是把命令添加到context 缓冲队列，需要调用context.Submit()方法进行提交</param>
    /// <param name="cameras"></param>
    public void Render (ScriptableRenderContext context, Camera camera) {
        this.context = context;
        this.camera = camera;

        if (!Cull ()) {
            return;
        }

        Setup ();
        DrawVisibleGeometry ();
        Submit ();
    }

    /// <summary>
    /// 绘制所有Camera可见的几何体
    /// </summary>
    void DrawVisibleGeometry () {
        // 排序设置,确定相机的透明排序模式是否使用正交或基于距离的排序
        SortingSettings sortingSettings = new SortingSettings (camera) {
            // 排序的条件，此处使用不透明对象排序模式
            criteria = SortingCriteria.CommonOpaque
        };
        // 绘制设置
        DrawingSettings drawingSettings = new DrawingSettings (unlitShaderTagId, sortingSettings);
        // 过滤设置,此处渲染所有渲染队列的对象
        FilteringSettings filteringSettings = new FilteringSettings (RenderQueueRange.all);
        // 图像绘制，需要在绘制天空盒之前进行
        context.DrawRenderers (cullingResults, ref drawingSettings, ref filteringSettings);
        context.DrawSkybox (camera);

    }

    /// <summary>
    ///  相机剔除
    /// </summary>
    bool Cull () {
        // 跟裁剪相关的数据是各种相机设置和矩阵参数，这些数据存储此结构体
        ScriptableCullingParameters p;
        // 是否得到需要进行剔除检查的所有物体
        if (camera.TryGetCullingParameters (out p)) {
            // 正式执行剔除操作
            cullingResults = context.Cull (ref p);
            return true;
        }
        return false;
    }

    void Setup () {
        // 设置相机的矩阵和其它属性，渲染时需要放在绘制物体的前面调用
        context.SetupCameraProperties (camera);
        // 为保证下一帧绘制的图像正确，需要清除渲染目标，清除旧的目标。
        buffer.ClearRenderTarget (true, true, Color.clear);

        // 开启采样过程
        buffer.BeginSample (bufferName);

        ExecuteBuffer ();

    }

    void Submit () {
        // 结束采样过程
        buffer.EndSample (bufferName);
        ExecuteBuffer ();
        context.Submit ();
    }

    /// <summary>
    /// 执行 CommandBuffer的方法：执行缓冲区命令，并且清除缓冲区。
    /// </summary>
    void ExecuteBuffer () {
        // 执行缓冲区命令,但不会清除缓冲区,如果重用buffer，一般会在执行完执行命令之后再执行清除缓冲区命令，通常执行命令和清除缓冲区命令是一起执行的。
        context.ExecuteCommandBuffer (buffer);
        buffer.Clear ();
    }

}