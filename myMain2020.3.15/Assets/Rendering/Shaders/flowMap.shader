
Shader "Jefford/flowMap"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}

        _FlowMap("_FlowMap", 2D) = "white" {}
        _Speed("_Speed",Range(0,1)) = 0.3
    }

    SubShader
    {
        Tags { "Queue"="Geometry" "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Name "Unlit"
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            float _Speed;
            CBUFFER_END

            TEXTURE2D (_BaseMap);    SAMPLER(sampler_BaseMap);
            TEXTURE2D (_FlowMap);    SAMPLER(sampler_FlowMap);

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float fogCoord      : TEXCOORD1;
            };

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = mul(UNITY_MATRIX_VP, mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0))); 
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                half4 c;
                half phase = frac(_Time.y * _Speed);
                // 构造周期函数
                half phase0 = frac(_Time.y * _Speed );
                //向上偏移半个相位
                half phase1 = frac(_Time.y * _Speed  + 0.5); 
                // 过滤掉中间色 灰色部分
                half4 flowMap = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, i.uv) * 2 - 1; 

                half2 flowDir = flowMap.rg * phase;
                half2 flowDir0 = flowMap.rg * phase0;
                half2 flowDir1 = flowMap.rg * phase1;


                half4 baseMap0 = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv - flowDir0);
                half4 baseMap1 = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv - flowDir1);

                half flowLerp = abs((0.5 - phase0) / 0.5); // 计算权值
                // 通过使用权值进行插值计算，否则会有跳动
                c = lerp(baseMap0, baseMap1, flowLerp) * _BaseColor;

                c.rgb = MixFog(c.rgb, i.fogCoord);
                return c;
            }
            ENDHLSL
        }
    }
}

