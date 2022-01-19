using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DualKawaseBlur : ScriptableRendererFeature
{
    [System.Serializable]
    public class DualKawaseBlurSettings
    {
        
        [Tooltip("控制开关DualKawaseBlurPass")]
        public bool bRenderDualKawaseBlur = true;
        [Tooltip("指定相关材质")]
        public Material material = null;
        [Tooltip("升/降采样Pass次数")]
        [Range(1, 6)]
        public int blurPasses = 4;
        [Tooltip("blur filter")]
        [Range(1f, 10f)]
        public float blurRadius = 1.5f;
        [Tooltip("指定pass渲染时机")]
        public RenderPassEvent renderPassEvent;
        
    }

    public DualKawaseBlurSettings settings = new DualKawaseBlurSettings();

    class DualKawaseBlurPass : ScriptableRenderPass
    {
        public DualKawaseBlurSettings settings;

        private string profilerTag; 

        int[] downSampleRT;
        int[] upSampleRT;

        public DualKawaseBlurPass(string profilerTag,DualKawaseBlurSettings settings)
        {
            this.profilerTag = profilerTag;
            this.settings = settings;
        }

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {

        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (settings.material == null)
            {
                Debug.LogErrorFormat("{0}.Execute(): Missing material. {1} render pass will not execute. Check for missing reference in the renderer resources.", GetType().Name, profilerTag);
                return;
            }

            RenderTargetIdentifier sourceRT = renderingData.cameraData.renderer.cameraColorTarget;
            CommandBuffer cmd = CommandBufferPool.Get(profilerTag);

            RenderTextureDescriptor inRTDesc = renderingData.cameraData.cameraTargetDescriptor;
            inRTDesc.depthBufferBits = 0;

            if (settings.bRenderDualKawaseBlur)
            {
                settings.material.SetFloat("_Offset", settings.blurRadius);
                int tw = (int)inRTDesc.width;
                int th = (int)inRTDesc.height;
                downSampleRT = new int[settings.blurPasses];
                upSampleRT = new int[settings.blurPasses];
                for(int i = 0; i < settings.blurPasses; i++)
                {
                    downSampleRT[i] = Shader.PropertyToID("DownSample"+i);
                    upSampleRT[i] = Shader.PropertyToID("UpSample" + i);
                }
                RenderTargetIdentifier tmpRT = sourceRT;
                //downSample
                for (int i = 0; i < settings.blurPasses;i++)
                {
                    cmd.GetTemporaryRT(downSampleRT[i], tw, th, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
                    cmd.GetTemporaryRT(upSampleRT[i], tw, th, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
                    tw = Mathf.Max(tw / 2, 1);
                    th = Mathf.Max(th / 2, 1);
                    cmd.Blit(tmpRT, downSampleRT[i], settings.material, 0);
                    tmpRT = downSampleRT[i];
                }

                //upSample
                for (int i = settings.blurPasses - 2; i >= 0; i--)
                {
                    cmd.Blit(tmpRT,upSampleRT[i], settings.material, 1);
                    tmpRT = upSampleRT[i];
                }
                //final pass
                cmd.Blit(tmpRT, sourceRT);
                //Release All tmpRT
                for(int i = 0;i < settings.blurPasses; i++)
                {
                    cmd.ReleaseTemporaryRT(downSampleRT[i]);
                    cmd.ReleaseTemporaryRT(upSampleRT[i]);
                }
            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    DualKawaseBlurPass scriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        scriptablePass = new DualKawaseBlurPass("DualKawaseBlur",settings);

        // Configures where the render pass should be injected.
        scriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;//必须等待场景渲染完全后执行
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(scriptablePass);
    }
}


