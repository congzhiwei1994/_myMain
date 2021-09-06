using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System.Collections.Generic;

namespace Rendering.ExtendURP
{
    public class DrawAlphaFeature : ScriptableRendererFeature
    {
        private static readonly int s_UberAlphaAdjustPropID = Shader.PropertyToID("_UberAlphaAdjust");

        class CustomUberAlphaSteupPass : ScriptableRenderPass
        {
            public const string kPassTag = "UberAlphaSteup";
            ProfilingSampler m_ProfilingSampler;

            public CustomUberAlphaSteupPass()
            {
                m_ProfilingSampler = new ProfilingSampler(kPassTag);
                this.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
            }

            // Here you can implement the rendering logic.
            // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
            // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
            // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                CommandBuffer cmd = CommandBufferPool.Get(kPassTag);
                using (new ProfilingScope(cmd, m_ProfilingSampler))
                {
                    // 设置
                    cmd.SetGlobalFloat(s_UberAlphaAdjustPropID, -1f);
                    context.ExecuteCommandBuffer(cmd);
                    cmd.Clear();
                }
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
        }

        class CustomUberAlphaRestorePass : ScriptableRenderPass
        {
            public const string kPassTag = "UberAlphaRestore";
            ProfilingSampler m_ProfilingSampler;

            public CustomUberAlphaRestorePass()
            {
                m_ProfilingSampler = new ProfilingSampler(kPassTag);
                this.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
            }

            // Here you can implement the rendering logic.
            // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
            // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
            // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                CommandBuffer cmd = CommandBufferPool.Get(kPassTag);
                using (new ProfilingScope(cmd, m_ProfilingSampler))
                {
                    // 设置
                    cmd.SetGlobalFloat(s_UberAlphaAdjustPropID, 0f);
                    context.ExecuteCommandBuffer(cmd);
                    cmd.Clear();
                }
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
        }

        class CustomRenderPass : ScriptableRenderPass
        {
            private const string k_PassTag = "DrawAlphaFeature";

            private readonly static ShaderTagId k_LightModeTag = new ShaderTagId("Alpha");
            private readonly static ShaderTagId k_LightModeOutlineTag = new ShaderTagId("OutlineAlpha");

            string m_ProfilerTag;
            ProfilingSampler m_ProfilingSampler;
            FilteringSettings m_FilteringOpaqueSettings;
            FilteringSettings m_FilteringTransparentSettings;
            List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();

            public CustomRenderPass(Settings setting)
            {
                m_ProfilerTag = k_PassTag;
                m_ProfilingSampler = new ProfilingSampler(k_PassTag);
                this.renderPassEvent = setting.Event;


                m_FilteringOpaqueSettings = new FilteringSettings(RenderQueueRange.opaque, setting.LayerMask);
                m_FilteringTransparentSettings = new FilteringSettings(RenderQueueRange.transparent, setting.LayerMask);
                m_ShaderTagIdList.Add(k_LightModeTag);
                if (setting.EnableOutlineAlpha)
                {
                    m_ShaderTagIdList.Add(k_LightModeOutlineTag);
                }
            }

            // Here you can implement the rendering logic.
            // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
            // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
            // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
                using (new ProfilingScope(cmd, m_ProfilingSampler))
                {
                    context.ExecuteCommandBuffer(cmd);
                    cmd.Clear();

                    // 先要清空深度
                    cmd.ClearRenderTarget(true, false, Color.clear);
                    
                   
                    // 不透明物
                    SortingCriteria sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
                    DrawingSettings drawingSettings = CreateDrawingSettings(m_ShaderTagIdList, ref renderingData, sortingCriteria);
                    drawingSettings.perObjectData = PerObjectData.None;
                    context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringOpaqueSettings);
                    // 透明物
                    sortingCriteria = SortingCriteria.CommonTransparent;
                    drawingSettings = CreateDrawingSettings(m_ShaderTagIdList, ref renderingData, sortingCriteria);
                    drawingSettings.perObjectData = PerObjectData.None;
                    context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringTransparentSettings);
                }
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
        }


        [System.Serializable]
        public class Settings
        {
            public RenderPassEvent Event = RenderPassEvent.AfterRenderingPostProcessing;

            public LayerMask LayerMask;
            public bool EnableOutlineAlpha = false;

        }

        public Settings settings = new Settings();

        CustomRenderPass m_ScriptablePass;
        CustomUberAlphaSteupPass m_UberAlphaSetupPass;
        CustomUberAlphaRestorePass m_UberAlphaRestorePass;

        public override void Create()
        {
            // 只调用一次
            m_ScriptablePass = new CustomRenderPass(settings);
            m_UberAlphaSetupPass = new CustomUberAlphaSteupPass();
            m_UberAlphaRestorePass = new CustomUberAlphaRestorePass();
        }

        // Here you can inject one or multiple render passes in the renderer.
        // This method is called when setting up the renderer once per-camera.
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(m_UberAlphaSetupPass);
            renderer.EnqueuePass(m_UberAlphaRestorePass);
            renderer.EnqueuePass(m_ScriptablePass);
        }
    }
}