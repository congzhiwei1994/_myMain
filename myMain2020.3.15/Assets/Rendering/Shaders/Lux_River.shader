
Shader "Jefford/Lux_River"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}
        [NoScaleOffset]_BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Float) = 1.0
        _DetailMapScale("_DetailMapScale", Float) = 1.0
        _NormalTilling("_NormalTilling",Range(0,20)) = 1
        _Speed("_Speed",Range(0,1)) = 0.3
        _WaterDirX("_WaterDirX",Range(-1,1)) = 0.5
        _WaterDirZ("_WaterDirZ",Range(-1,1)) = 0.5

        [Space(20)]
        [Toggle] _Refract("_Refract",int) = 0
        _Refraction("_Refraction", Range(0,1)) = 1
        _EdgeBlend("_EdgeBlend", Range(0,1)) = 1

        [Space(20)]
        [Toggle] _Foam("_Foam",int) = 0
        _FoamMap("_FoamMap", 2D) = "white" {}
        _FoamTiling("_FoamTiling", Range(0, 20)) = 1
        _FoamSpeed("_FoamSpeed", Range(0,1)) = 1
        _FoamSlopStrength("_FoamSlopStrength", float) = 1
        _FoamWidth("_FoamWidth",float) = 1
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            // Blend SrcAlpha OneMinusSrcAlpha 

            Name "UniversalForward"
            Tags {"LightMode" = "UniversalForward"}
            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _REFRACT_ON
            #pragma shader_feature _FOAM_ON

            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE



            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            float _BumpScale;
            half _DetailMapScale;
            half _NormalTilling;

            half _Speed;
            half _WaterDirX;
            half _WaterDirZ;

            half _Refraction;
            half _EdgeBlend;

            half _FoamTiling;
            half _FoamSpeed;
            half _FoamSlopStrength;
            half _FoamWidth;
            CBUFFER_END

            TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D(_CameraOpaqueTexture); SAMPLER(sampler_CameraOpaqueTexture);
            TEXTURE2D(_FoamMap);            SAMPLER(sampler_FoamMap);

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 uv               : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS                 : TEXCOORD1;   
                float3 tangentWS                : TEXCOORD2;    
                float3 bitangentWS              : TEXCOORD3;            
                float3 positionWS              : TEXCOORD4;     

            };


            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.uv = v.uv;
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
                half3 tangentWS = mul((float3x3)UNITY_MATRIX_M, v.tangentOS.xyz);
                o.tangentWS = SafeNormalize(tangentWS);
                half sign = v.tangentOS.w * unity_WorldTransformParams.w;
                o.bitangentWS = cross(o.normalWS,o.tangentWS) * sign;
                o.positionWS = mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0));
                o.positionCS = mul(UNITY_MATRIX_VP, mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0))); 

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                half2 uv = i.uv;
                half2 screenUV = 0;
                {
                    screenUV = i.positionCS.xy / _ScreenParams.xy;
                    #if defined(UNITY_SINGLE_PASS_STEREO)  //  Fix screenUV for Single Pass Stereo Rendering
                        screenUV = UnityStereoTransformScreenSpaceTex(screenUV);
                    #endif
                }
                
                half3x3 tbn = half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);

                half2 waterDir = _Time.y * _Speed * half2(_WaterDirX,_WaterDirZ);
                half2 uv_normal = uv * _NormalTilling + waterDir;
                half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap,uv);
                half3 normapTS = UnpackNormalScale(normalMap,_BumpScale);
                half4 detailMap = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap,uv_normal);
                half3 detailMapTS = UnpackNormalScale(detailMap,_DetailMapScale);

                half3 blendNormalTS = normalize(half3(detailMapTS.xy + normapTS.xy, detailMapTS.z * normapTS.z));
                half3 normalWS = NormalizeNormalPerPixel(mul(blendNormalTS, tbn));
                

                float distanceFadeFactor = 1; // 距离衰减 越远值越小
                {
                    distanceFadeFactor = i.positionCS.z * _ZBufferParams.z;
                    #if UNITY_REVERSED_Z != 1  //  OpenGL
                        distanceFadeFactor = i.positionCS.z / i.positionCS.w;
                    #endif
                }
                
                #if defined _REFRACT_ON // 折射
                    float2 offset = blendNormalTS.xy * _Refraction * distanceFadeFactor;
                #else
                    float2 offset = 0;
                #endif

                half depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV + offset);
                half sceneDepth = LinearEyeDepth(depthMap, _ZBufferParams);
                half viewDepth = sceneDepth - i.positionCS.w;

                // #if defined _REFRACT_ON // 折射
                //     offset = screenUV + offset * saturate(viewDepth);
                //     depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, offset);
                //     sceneDepth = LinearEyeDepth(depthMap, _ZBufferParams);
                //     viewDepth = sceneDepth - i.positionCS.w;

                //     half3 refractMap = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, saturate(offset));
                //     refractMap = saturate(refractMap);
                // #endif

                half alpha = saturate(_EdgeBlend * viewDepth);

                #if defined _FOAM_ON
                    half foamNoise = blendNormalTS.z * 2 - 1;
                    half foamWidth = saturate(_FoamWidth * viewDepth * 100);
                    half2 uv_foam = _FoamTiling * uv + _FoamSpeed * blendNormalTS.xy;
                    half4 foamMap = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap, uv_foam);

                    half shoreFoam = (1 - foamWidth) * foamNoise;
                    shoreFoam = foamWidth - foamWidth * foamWidth;
                    
                #endif



                
                half4 c;
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                c = baseMap * _BaseColor;
                return c;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
        
    }
}

