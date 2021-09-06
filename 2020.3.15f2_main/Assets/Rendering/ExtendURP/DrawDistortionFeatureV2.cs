using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System.Collections.Generic;


namespace Rendering.ExtendURP
{
    public class DrawDistortionFeatureV2 : ScriptableRendererFeature
    {
        class CustomRenderPass : ScriptableRenderPass
        {
            private const string k_PassTag = "DrawDistortionFeature";

            private readonly static ShaderTagId k_LightModeTag = new ShaderTagId("Distort");

            string m_ProfilerTag;
            ProfilingSampler m_ProfilingSampler;
            FilteringSettings m_FilteringOpaqueSettings;
            FilteringSettings m_FilteringTransparentSettings;

            RenderTargetHandle screenTex;
            private RenderTargetIdentifier source { get; set; }

            public CustomRenderPass(Settings setting)
            {
                this.renderPassEvent = setting.Event;

                m_ProfilerTag = k_PassTag;
                m_ProfilingSampler = new ProfilingSampler(k_PassTag);
                m_FilteringOpaqueSettings = new FilteringSettings(RenderQueueRange.opaque, setting.LayerMask);
                m_FilteringTransparentSettings = new FilteringSettings(RenderQueueRange.transparent, setting.LayerMask);

                screenTex.Init("_DistortTexture");
            }

            public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
            {
                RenderTextureDescriptor _opaqueDesc = cameraTextureDescriptor;
                _opaqueDesc.colorFormat = RenderTextureFormat.Default;
                cmd.GetTemporaryRT(screenTex.id, _opaqueDesc);

                cmd.Blit(source, screenTex.Identifier());
                cmd.Blit(screenTex.Identifier(), source);
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

                    // 不透明物
                    SortingCriteria sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
                    DrawingSettings drawingSettings = CreateDrawingSettings(k_LightModeTag, ref renderingData, sortingCriteria);
                    drawingSettings.perObjectData = PerObjectData.None;
                    context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringOpaqueSettings);
                    // 透明物
                    sortingCriteria = SortingCriteria.CommonTransparent;
                    drawingSettings = CreateDrawingSettings(k_LightModeTag, ref renderingData, sortingCriteria);
                    drawingSettings.perObjectData = PerObjectData.None;
                    context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringTransparentSettings);
                }
                context.ExecuteCommandBuffer(cmd);

                CommandBufferPool.Release(cmd);
            }

            public void SetUp(RenderTargetIdentifier source)
            {
                this.source = source;
            }

            public override void FrameCleanup(CommandBuffer cmd)
            {
                cmd.ReleaseTemporaryRT(screenTex.id);
            }
        }

        [System.Serializable]
        public class Settings
        {
            public RenderPassEvent Event = RenderPassEvent.AfterRenderingTransparents;

            public LayerMask LayerMask;
        }

        public Settings settings = new Settings();

        CustomRenderPass m_ScriptablePass;

        public override void Create()
        {
            // 只调用一次
            m_ScriptablePass = new CustomRenderPass(settings);
        }

        // Here you can inject one or multiple render passes in the renderer.
        // This method is called when setting up the renderer once per-camera.
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            var _src = renderer.cameraColorTarget;
            m_ScriptablePass.SetUp(_src);

            renderer.EnqueuePass(m_ScriptablePass);
        }

    
    }
}