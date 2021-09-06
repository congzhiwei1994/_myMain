using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rendering.ExtendURP
{
    public class OutlinePassFeature : ScriptableRendererFeature
    {
        class CustomRenderPass : ScriptableRenderPass
        {
            public const string k_PassTag = "OutlinePassFeature";

            private readonly static ShaderTagId k_LightModeTag = new ShaderTagId("Outline");

            string m_ProfilerTag;
            ProfilingSampler m_ProfilingSampler;
            FilteringSettings m_FilteringSettings;

            public CustomRenderPass(RenderPassEvent renderPassEvent, int layerMask)
            {
                m_ProfilerTag = k_PassTag;
                m_ProfilingSampler = new ProfilingSampler(k_PassTag);
                this.renderPassEvent = renderPassEvent;


                m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque, layerMask);
            }

            // This method is called before executing the render pass.
            // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
            // When empty this render pass will render to the active camera render target.
            // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
            // The render pipeline will ensure target setup and clearing happens in an performance manner.
            public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
            {
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

                    SortingCriteria sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
                    DrawingSettings drawingSettings = CreateDrawingSettings(k_LightModeTag, ref renderingData, sortingCriteria);
                    drawingSettings.perObjectData = PerObjectData.None;

                    context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringSettings);
                }
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }

            /// Cleanup any allocated resources that were created during the execution of this render pass.
            public override void FrameCleanup(CommandBuffer cmd)
            {
            }
        }

        [System.Serializable]
        public class Settings
        {
            public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;

            public FilterSettings filterSettings = new FilterSettings();
        }

        [System.Serializable]
        public class FilterSettings
        {
            public LayerMask LayerMask;

            public FilterSettings()
            {
                LayerMask = 0;
            }
        }

        public Settings settings = new Settings();

        CustomRenderPass m_ScriptablePass;

        public override void Create()
        {
            FilterSettings filter = settings.filterSettings;
            m_ScriptablePass = new CustomRenderPass(settings.Event, filter.LayerMask);

            // Configures where the render pass should be injected.
            //m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        }

        // Here you can inject one or multiple render passes in the renderer.
        // This method is called when setting up the renderer once per-camera.
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(m_ScriptablePass);
        }
    }
}

