using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System.Collections.Generic;

namespace Rendering.ExtendURP
{
    public class DrawRaidialBlurFeature : ScriptableRendererFeature
    {
        class CustomRenderPass : ScriptableRenderPass
        {
            public enum RenderTarget
            {
                Color,
                RenderTexture,
            }

            public Material blurMaterial = null;

            public FilterMode filterMode { get; set; }

            private int downSample;

            private RenderTargetIdentifier source { get; set; }

            private RenderTargetHandle destination { get; set; }

            string m_ProfilerTag;

            RenderTargetHandle m_TemporaryColorTexture02;
            RenderTargetHandle m_TemporaryColorTexture03;

            public CustomRenderPass(Settings _settings, string _tag)
            {
                renderPassEvent = _settings.Event;
                blurMaterial = _settings.blurMaterial;
                downSample = _settings.downSample;

                m_ProfilerTag = _tag;

                m_TemporaryColorTexture02.Init("_TemporaryColorTexture2");
                m_TemporaryColorTexture03.Init("_TemporaryColorTexture3");  
            }

            public void SetUp(RenderTargetIdentifier source)
            {
                this.source = source;
            }

            
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                //!if(RenderMgr.PostProcessOpen) return;                            //控制后处理执行
                if (!renderingData.cameraData.postProcessEnabled) return;
                
                /*--------*/

                CommandBuffer _cmd = CommandBufferPool.Get(m_ProfilerTag);

                RenderTextureDescriptor _opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
                _opaqueDesc.width = _opaqueDesc.width >> downSample;
                _opaqueDesc.height = _opaqueDesc.height >> downSample;
                _opaqueDesc.depthBufferBits = 0;
             

                _cmd.GetTemporaryRT(m_TemporaryColorTexture02.id, _opaqueDesc, filterMode);
                _cmd.GetTemporaryRT(m_TemporaryColorTexture03.id, _opaqueDesc, filterMode);


                _cmd.BeginSample("RadialBlur");

                if ( blurMaterial != null)
                {

                    _cmd.Blit(source, m_TemporaryColorTexture03.Identifier());
                    _cmd.Blit(m_TemporaryColorTexture03.Identifier(), m_TemporaryColorTexture02.Identifier(), blurMaterial, 0);

                    _cmd.SetGlobalTexture("_BlurTex", m_TemporaryColorTexture02.Identifier());
                    _cmd.Blit(m_TemporaryColorTexture03.Identifier(), source, blurMaterial, 1);          
                    
                }
                _cmd.EndSample("RadialBlur");

                context.ExecuteCommandBuffer(_cmd);

                _cmd.ReleaseTemporaryRT(m_TemporaryColorTexture02.id);
                _cmd.ReleaseTemporaryRT(m_TemporaryColorTexture03.id);
                CommandBufferPool.Release(_cmd);    

            }

        }
        

        [System.Serializable]
        public class Settings
        {
            public RenderPassEvent Event = RenderPassEvent.AfterRenderingTransparents;
            public Material blurMaterial = null;

            [Range(1, 4)]
            public int downSample = 2;
 
        }

        public Settings settings = new Settings();

        CustomRenderPass renderPass;

        RenderTargetHandle m_RenderTargetHandler;

        public override void Create()
        {
            renderPass = new CustomRenderPass(settings, name);

        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            var _src = renderer.cameraColorTarget;

            renderPass.SetUp(_src);
            renderer.EnqueuePass(renderPass);
        }
    }
}