
Shader "Jefford/Sky/cubemap"
{
    Properties
    {
        _SkyColor("_SkyColor",color) = (1,1,1,1)
        _SkyMap("_SkyMap",Cube) = "white" {}
        _Rotation ("Rotation", Range(0, 360)) = 0
    }

    SubShader
    {
        Tags 
        { 
            "Queue"="Background" 
            "RenderType"="Background"
            "PreviewType"="Skybox"
            "IgnoreProjector" = "True" 
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Cull Back
            Name "Unlit"
            HLSLPROGRAM
            
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            CBUFFER_START(UnityPerMaterial)
            half4 _SkyColor;
            half4 _SkyMap_HDR;
            float _Rotation;
            CBUFFER_END

            TEXTURECUBE(_SkyMap);          SAMPLER(sampler_SkyMap);

            float3 RotateAroundYInDegrees (float3 vertex, float degrees)
            {
                float alpha = degrees * 3.1415926 / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float3(mul(m, vertex.xz), vertex.y).xzy;
            }
            

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float3 normalOS     : NORMAL;
                float2 uv               : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS               : SV_POSITION;
                float2 uv                       : TEXCOORD0;
                float3 normalWS                 : TEXCOORD1;
                float3 viewDirWS                 : TEXCOORD2;
                float3 positionWS              : TEXCOORD3;
                float fogCoord      : TEXCOORD4;
            };




            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                float3 rotated = RotateAroundYInDegrees(v.positionOS, _Rotation);
                
                o.positionWS = mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0)).xyz;
                o.positionCS = mul(UNITY_MATRIX_VP, mul(UNITY_MATRIX_M, float4(rotated, 1.0))); 
                

                half3 normalWS;
                {
                    #ifdef UNITY_ASSUME_UNIFORM_SCALING
                        normalWS = SafeNormalize(mul((float3x3)UNITY_MATRIX_M, v.normalOS));
                    #else
                        // Normal need to be multiply by inverse transpose
                        normalWS = SafeNormalize(mul(v.normalOS, (float3x3)UNITY_MATRIX_I_M));
                    #endif
                }
                o.normalWS - normalWS;
                o.viewDirWS = _WorldSpaceCameraPos - o.positionWS;
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float3 viewDirWS = SafeNormalize(i.viewDirWS);
                float3 normalWS = i.normalWS;
                half3 R = reflect(-viewDirWS, normalWS);

                half4 skyMap = SAMPLE_TEXTURECUBE_LOD(_SkyMap, sampler_SkyMap, R, 0);
                half3 color = DecodeHDREnvironment(skyMap, _SkyMap_HDR) * _SkyColor.rgb;
                color = MixFog(color, i.fogCoord);
                return half4(color,1);
            }
            ENDHLSL
        }
    }
}

