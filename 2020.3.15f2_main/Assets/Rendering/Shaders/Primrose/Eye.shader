
Shader "Jefford/Primrose/EyE"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}

        _BumpScale("Scale", Float) = 1.0
        [NoScaleOffset]_BumpMap("Normal Map", 2D) = "bump" {}
        _EnvMap("_EnvMap", Cube) = "white" {}
        _Roughness("_Roughness",Range(0,1)) = 1
        _EnvlIntensity ("_EnvlIntensity",Range(0,5)) = 1

        _MatCap("_MatCap",2D) = "white"{}
        _MatCapIntensity("_MatCapIntensity",Range(0,1)) = 1
        _MaskMap("_MaskMap",2D) = "white"{}
    }

    SubShader
    {
        Tags { "Queue"="Geometry" "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "Unlit"
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            half _BumpScale;
            half _Roughness;
            half4 _EnvMap_HDR;
            half _EnvlIntensity;
            half _MatCapIntensity;
            CBUFFER_END

            TEXTURECUBE(_EnvMap);       SAMPLER(sampler_EnvMap);
            TEXTURE2D(_MatCap);       SAMPLER(sampler_MatCap);
            TEXTURE2D(_MaskMap);       SAMPLER(sampler_MaskMap);


            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float3 normalOS         : NORMAL; 
                float4 tangentOS        : TANGENT; 
            };

            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float2 uv               : TEXCOORD0;
                float3 normalWS         : TEXCOORD1;
                float3 tangentWS        : TEXCOORD2;
                float3 bitangentWS      : TEXCOORD3;
                float3 positionWS       : TEXCOORD4;
                float3 viewDirWS        : TEXCOORD5;
                half2 matCapUV          : TEXCOORD6;
            };



            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = mul(UNITY_MATRIX_VP, mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0))); 
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.positionWS = mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0)).xyz;
                half3 normalWS;
                {
                    #ifdef UNITY_ASSUME_UNIFORM_SCALING
                        normalWS = SafeNormalize(mul((float3x3)UNITY_MATRIX_M, v.normalOS));
                    #else
                        // Normal need to be multiply by inverse transpose
                        normalWS = SafeNormalize(mul(v.normalOS, (float3x3)UNITY_MATRIX_I_M));
                    #endif
                }
                o.normalWS = normalWS;
                o.tangentWS = mul((float3x3)UNITY_MATRIX_M, v.tangentOS.xyz);
                half sign = v.tangentOS.w * unity_WorldTransformParams.w;
                o.bitangentWS = cross(o.normalWS, o.tangentWS) * sign;

                o.viewDirWS = _WorldSpaceCameraPos - o.positionWS;
                o.matCapUV = SafeNormalize(mul((float3x3)UNITY_MATRIX_V, normalWS)).xy * 0.5 + 0.5;
                
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {

                float3 viewDirWS = SafeNormalize(i.viewDirWS);

                half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap,i.uv);
                half3 normapTS= UnpackNormalScale(normalMap,_BumpScale);
                half3x3 tbn = half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);
                half3 normalWS = NormalizeNormalPerPixel( mul(normapTS, tbn));

                // 反向，向内凹陷，用于做漫反射
                half3 normalWS_iris;
                {
                    normapTS.xy = -normapTS.xy;
                    normalWS_iris = NormalizeNormalPerPixel( mul(normapTS, tbn));
                }

                
                
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                half3 albedo = baseMap.rgb * _BaseColor.rgb;
                half4 matCap = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, i.matCapUV);
                half maskMap = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv).r;
                // return matCap;
                
                Light mainLight = GetMainLight();
                float3 H = SafeNormalize(mainLight.direction + viewDirWS);
                half NoL = saturate(dot(normalWS_iris, mainLight.direction)) * 0.5 + 0.5;
                half NoH = saturate(dot(normalWS, H));
                
                
                float3 R = reflect(-viewDirWS, normalWS);
                half mip = _Roughness * (1.7 - 0.7 * _Roughness) * 6;
                half4 envMap = SAMPLE_TEXTURECUBE_LOD(_EnvMap, sampler_EnvMap, R, mip);
                
                half3 envColor = DecodeHDREnvironment(envMap, _EnvMap_HDR);
                half3 envlumin = dot(envColor,float3(0.299f, 0.587f, 0.114));
                envColor = envColor * envlumin * _EnvlIntensity;

                half3 c = NoL * albedo + envColor * albedo + matCap * _MatCapIntensity * maskMap;
                return half4(c ,1);
            }
            ENDHLSL
        }
    }
}

