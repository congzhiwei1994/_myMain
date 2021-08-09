using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

//当unity发现工程使用SRP的时候，就会寻找当前使用的SRP Asset并请求一个渲染实例，该实例必须包含一个Render函数，渲染实例表示管道配置

/// <summary>
/// 实际执行渲染的类
/// </summary>
public class CustormRPInstance : RenderPipeline {

    #region[字段]
    CameraRenderer renderer = new CameraRenderer ();
    #endregion

    /// <summary>
    /// 绘制在相机视野内的所有物体,对于每种 camera类型，unity每帧调用一次这个方法,该方法是SRP的入口
    /// </summary>
    /// <param name="context">是一个command buffer对象，可以向其输入您想执行的渲染指令。
    /// context：只是把命令添加到context 缓冲队列，需要调用context.Submit()方法进行提交</param>
    /// <param name="cameras">相机对象数组，存储了参与这一帧渲染的所有相机对象。</param>
    protected override void Render (ScriptableRenderContext context, Camera[] cameras) {
        foreach (Camera camera in cameras) {
            renderer.Render (context, camera);
        }

    }

}