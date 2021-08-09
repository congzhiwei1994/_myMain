using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

/// <summary>
/// 定义了SRP的类型和所有配置数据的设置,当unity首次执行渲染命令的时候，则会调用这个接口并返回一个可用的渲染实例,渲染实例表示管道配置。
/// </summary>
[CreateAssetMenu (menuName = "Rendering/CustormRP")]
// 
public class CustormRPAsset : RenderPipelineAsset {
    /// <summary>
    /// unity在渲染第一帧之前调用这个方法，如果Render Pipeline Asset中的设置发生变化，
    /// unity会销毁当前的Render Pipeline Instance， 并且在渲染下一帧之前重新调用这个方法。
    /// </summary>
    /// <returns></returns>
    protected override RenderPipeline CreatePipeline () {
        return new CustormRPInstance ();
    }

}