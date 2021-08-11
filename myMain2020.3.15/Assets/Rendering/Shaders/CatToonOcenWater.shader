
Shader "Jefford/CatToonOcenWater"
{
    Properties
    {
        // _BaseColor("Base Color",color) = (1,1,1,1)
        // _BaseMap("BaseMap", 2D) = "white" {}
        _ShallowColor("_ShallowColor",Color) = (0,0,0,1)
        _DeepColor("_DeepColor",Color) = (0,0,0,1)
        _FresnelColor("_FresnelColor",Color) = (1,1,1,1)
        _DepthRange("_DepthRange",Range(0,1)) = 1
        _FresnelRange("_FresnelRange",float) = 1

        [Space(15)]
        [Header(SurFaceNormal)]
        _Tilling("_Tilling",float) = 1
        _SurFaceNormal("SurFaceNormal",2D) = "bump"{}
        _WaterSpeed("_WaterSpeed",Range(0,1)) = 1
        _WaterDix_X("_WaterDix_X",Range(-1,1)) = 1
        _WaterDix_Z("_WaterDix_Z",Range(-1,1)) = 1

        [Space(15)]
        [Header(Env)]
        _EnvMap("_EnvMap",Cube) = "white"{}
        _EnvNoiseIntensity("_EnvNoise Intensity",Range(0,1)) = 1
        _ReflectionIntensity("_Reflection Intensity", Range(0,2)) = 1
        _ReflectionPow("_Reflection Pow", Range(0,2)) = 1

        [Space(15)]
        [Header(UnderWater)]
        _UnderWaterDistort("_UnderWaterDistort",Range(0,1)) = 0.3

        [Space(15)]
        [Header(Caustic)]
        _CausticMap("_CausticMap",2D) = "white"{}
        _CausticTilling("_CausticTilling", float) = 1
        _CausticIntensity("_CausticIntensity", Range(0,3)) = 1.5
        _CausticRange("_CausticRange", Range(0,5)) = 1

        [Space(15)]
        [Header(Shore)]
        _ShoreColor("_ShoreColor",color) = (1,1,1,1)
        _ShoreRange("_ShoreRange",float) = 1
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

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;

            half4 _ShallowColor;
            half4 _DeepColor;
            half _DepthRange;
            half _FresnelRange;
            half4 _FresnelColor;

            half _Tilling;
            half _WaterSpeed;
            half _WaterDix_X;
            half _WaterDix_Z;

            // Env
            half _EnvNoiseIntensity;
            half4 _EnvMap_HDR;
            half _ReflectionIntensity;
            half _ReflectionPow;

            //UnderWater
            half _UnderWaterDistort;

            // Caustics
            half _CausticTilling;
            half _CausticIntensity;
            half _CausticRange;

            // Shore
            half4 _ShoreColor;
            half _ShoreRange;
            
            CBUFFER_END

            TEXTURE2D (_BaseMap);                                        SAMPLER(sampler_BaseMap);
            TEXTURE2D (_SurFaceNormal);                                  SAMPLER(sampler_SurFaceNormal);
            TEXTURECUBE(_EnvMap);                                        SAMPLER(sampler_EnvMap);
            TEXTURE2D(_CausticMap);                                     SAMPLER(sampler_CausticMap);
            
            
            TEXTURE2D(_CameraDepthTexture);                              SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D(_CameraOpaqueTexture);                             SAMPLER(sampler_CameraOpaqueTexture);

            
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
                float2 uv                : TEXCOORD0;
                float3 positionWS       : TEXCOORD1;
                float3 viewDirWS            : TEXCOORD2;
                float3 normalWS                 : TEXCOORD3;  
                float3 tangentWS                : TEXCOORD4;    
                float3 bitangentWS              : TEXCOORD5;
                float3 positionVS               : TEXCOORD6;
                

            };


            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
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
                o.tangentWS = SafeNormalize(mul((float3x3)UNITY_MATRIX_M, v.tangentOS.xyz));
                half sign = v.tangentOS.w * unity_WorldTransformParams.w;
                o.bitangentWS = cross(o.normalWS,o.tangentWS) * sign;


                o.positionWS = mul(UNITY_MATRIX_M,float4(v.positionOS.xyz, 1));
                o.positionVS = mul(UNITY_MATRIX_V,float4(o.positionWS.xyz, 1)).xyz;
                o.viewDirWS = _WorldSpaceCameraPos - o.positionWS; 
                o.positionCS = mul(UNITY_MATRIX_VP, mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0)));
                
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float3 positionWS = i.positionWS;
                float3 V = SafeNormalize(i.viewDirWS);
                
                half NoV = saturate(dot(i.normalWS,V));

                half fresnel = 1 - NoV;


                half2 screenUV = i.positionCS.xy / _ScreenParams.xy;
                half depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                half sceneDepth = LinearEyeDepth(depthMap, _ZBufferParams);
                half viewDepth = sceneDepth - i.positionCS.w;
                

                // Water Color
                half waterDepth = saturate(exp(-viewDepth / _DepthRange));
                half3 waterColor = lerp(_DeepColor, _ShallowColor, waterDepth);
                waterColor = lerp(waterColor, _FresnelColor, saturate( pow(fresnel,  _FresnelRange)));

                // Normal
                half2 waterDir = half2(_WaterDix_X, _WaterDix_Z) * _WaterSpeed * _Time.y;
                half2 worldUV_A = positionWS.xz * _Tilling + waterDir;
                half4 normalMap_A = SAMPLE_TEXTURE2D(_SurFaceNormal, sampler_SurFaceNormal, worldUV_A);
                half3 normalTS_A = UnpackNormal(normalMap_A);
                half2 worldUV_B = positionWS.xz * _Tilling * 2 + waterDir * -0.5;
                half4 normalMap_B = SAMPLE_TEXTURE2D(_SurFaceNormal, sampler_SurFaceNormal, worldUV_B);
                half3 normalTS_B = UnpackNormal(normalMap_B);
                half3 normalTS = BlendNormal(normalTS_A, normalTS_B);
                half3x3 tbn = half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);
                half3 normalWS = NormalizeNormalPerPixel(mul(normalTS, tbn));
                

                // Env
                half3 normal_Env = lerp(half3(0,0,1), normalWS, _EnvNoiseIntensity * 0.1);
                float3 R = reflect(-V,normal_Env);
                half4 envMap = SAMPLE_TEXTURECUBE_LOD(_EnvMap, sampler_EnvMap, R, 0);
                half3 envColor = DecodeHDREnvironment(envMap, _EnvMap_HDR);
                envColor *= saturate(pow(fresnel, _ReflectionPow) * _ReflectionIntensity);
                

                // UnderWater 水低
                half2 distor = _UnderWaterDistort * normalWS.xy * 0.01;
                half3 opaqueTex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV + distor);



                // Caustic
                // 深度重建观察空间坐标
                float4 depthVS = 1;
                depthVS.xy = i.positionVS.xy * sceneDepth / -i.positionVS.z;
                depthVS.z = sceneDepth;
                float3 depthWS = mul(unity_CameraToWorld,depthVS).rgb;
                half causticMask = saturate(exp(-viewDepth / _CausticRange));
                
                half2 caustic_uv = depthWS.xz * _CausticTilling + depthWS.y * 0.2;
                half3 causticMap01 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, caustic_uv + waterDir);
                half3 causticMap02 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, -caustic_uv + waterDir);
                half3 causticMap = min(causticMap01, causticMap02) * _CausticIntensity * causticMask;
                half3 underWaterColor = causticMap + opaqueTex;

                // Shore : 岸边





                waterColor = waterColor + envColor;
                half3 color = lerp(waterColor, underWaterColor, waterDepth);

                return half4(color,1);
            }
            ENDHLSL
        }
    }
}

