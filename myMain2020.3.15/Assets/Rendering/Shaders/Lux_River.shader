
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
        _WaterSmoothness("_WaterSmoothness", Range(0, 1)) = 1
        _WaterSpecularColor("_WaterSpecularColor", Color) = (0.5, 0.5, 0.5, 1)

        [Space(20)]
        [Toggle] _Refract("_Refract",int) = 0
        _Refraction("_Refraction", Range(0,1)) = 1
        _EdgeBlend("_EdgeBlend", Range(0,1)) = 1

        [Space(20)]
        [Header(FoamLight)]
        [Toggle] _Foam("_Foam",int) = 0
        _FoamWidth("_Foam Width",float) = 1
        _FoamMap("_FoamMap", 2D) = "white" {}
        _FoamTiling("_Foam Tiling", Range(0, 20)) = 1
        _FoamSpeed("_Foam Speed", Range(0,1)) = 1
        _FoamSlopIntensity("_FoamSlop Intensity", float) = 1
        _FoamSmoothness("_FoamSmoothness",Range(0, 1)) = 1


        [Space(20)]
        [Header(UnderWater)]
        _Density_UnderWater("_Density_UnderWater",float) = 1
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
            half _WaterSmoothness;
            half _WaterSpecularColor;

            half _Refraction;
            half _EdgeBlend;

            half _FoamTiling;
            half _FoamSpeed;
            half _FoamSlopIntensity;
            half _FoamWidth;
            half _FoamSmoothness;

            half _Density_UnderWater;
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
                float4 positionCS              : SV_POSITION;
                float2 uv                      : TEXCOORD0;
                float3 normalWS                : TEXCOORD1;   
                float3 tangentWS               : TEXCOORD2;    
                float3 bitangentWS             : TEXCOORD3;            
                float3 positionWS              : TEXCOORD4;   
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord         : TEXCOORD5;
                #endif  
                half3 vertexLight              : TEXCOORD6;
                half3 SH                       : TEXCOORD7;
                half3 viewDirWS                : TEXCOORD8;

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

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    o.shadowCoord = TransformWorldToShadowCoord(o.positionWS);
                #endif

                o.vertexLight = VertexLighting(o.positionWS, o.normalWS);
                o.SH = SampleSHVertex(o.normalWS);
                o.viewDirWS = _WorldSpaceCameraPos - o.positionWS;
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

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord = i.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                #else
                    float4 shadowCoord = float4(0, 0, 0, 0);
                #endif
                
                half3 SH = i.SH;
                half3 vertexLight = i.vertexLight;
                half3 viewDirWS = SafeNormalize(i.viewDirWS);

                // -----------------------------------------------------------------------

                half3x3 tbn = half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);

                half2 waterDir = _Time.y * _Speed * half2(_WaterDirX,_WaterDirZ);
                half2 uv_normal = uv * _NormalTilling + waterDir;
                half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap,uv);
                half3 normapTS = UnpackNormalScale(normalMap,_BumpScale);
                half4 detailMap = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap,uv_normal);
                half3 detailMapTS = UnpackNormalScale(detailMap,_DetailMapScale);

                half3 blendNormalTS = normalize(half3(detailMapTS.xy + normapTS.xy, detailMapTS.z * normapTS.z));
                half3 normalWS = NormalizeNormalPerPixel(mul(blendNormalTS, tbn));
                

                float distanceFadeFactor = 1; // 距离衰减， 越远值越小越暗
                {
                    distanceFadeFactor = i.positionCS.z * _ZBufferParams.z;
                    #if UNITY_REVERSED_Z != 1  //  OpenGL
                        distanceFadeFactor = i.positionCS.z / i.positionCS.w;
                    #endif
                }
                
                // 折射
                #if defined _REFRACT_ON 
                    // distanceFadeFactor： 越远越接近0，则 offset 越等于零
                    float2 offset = blendNormalTS.xy * _Refraction * distanceFadeFactor;
                #else
                    float2 offset = 0;
                #endif

                half depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV + offset);
                half sceneDepth = LinearEyeDepth(depthMap, _ZBufferParams);
                // 计算深度差
                half viewDepth = sceneDepth - i.positionCS.w; 

                // 折射
                #if defined _REFRACT_ON 
                    offset = screenUV + offset * saturate(viewDepth);
                    depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, offset);
                    sceneDepth = LinearEyeDepth(depthMap, _ZBufferParams);
                    viewDepth = sceneDepth - i.positionCS.w;
                    
                    half3 refractMap = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, saturate(offset));
                    refractMap = saturate(refractMap);
                #endif


                half alpha = saturate(_EdgeBlend * viewDepth);

                // 0 - 1 之间的曲线过渡
                half viewAtten = saturate(1 - exp(-viewDepth * _Density_UnderWater));
                half underWaterDensity = viewAtten;


                half smoothness = _WaterSmoothness;
                #if defined _FOAM_ON
                    // 泡沫的宽度
                    half foamWidth = saturate(_FoamWidth * viewDepth);
                    // 泡沫的噪点
                    half foamNoise = blendNormalTS.z * 2 - 1;
                    // 岸边的泡沫, 反向之后 * 泡沫的噪点，即只有边缘地方有泡沫
                    half shoreFoam = (1 - foamWidth) * foamNoise;
                    // 深水和浅水区域为 0
                    half shoreFoamMask = saturate(foamWidth - foamWidth * foamWidth);
                    shoreFoam *= shoreFoamMask;

                    // 斜坡区域的泡沫
                    half slopeMask = saturate(1 - i.normalWS.y);
                    half slopeFoam = slopeMask * _FoamSlopIntensity;

                    // 岸边泡沫和斜坡泡沫相加
                    shoreFoam += slopeMask;


                    half2 uv_foam = _FoamTiling * uv + _FoamSpeed * blendNormalTS.xy;
                    half4 foamMap = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap, uv_foam);

                    // 获得泡沫的光滑度
                    half a = 0.8 - foamMap.a;    // (-0.2 - 0.8)
                    half b = 1.6 - foamMap.a;   //  0.6 - 1.6
                    foamMap.a = foamMap.a * smoothstep(a, b, foamMap.a);
                    smoothness = lerp(smoothness, _FoamSmoothness, foamMap.a);
                #endif


                half reflectivity = ReflectivitySpecular(_WaterSpecularColor);
                half oneMinusReflectivity = 1.0 - reflectivity;
                half perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
                half roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
                half roughness2 = roughness * roughness;
                half normalizationTerm = roughness * 4.0h + 2.0h;

                Light mainLight = GetMainLight(shadowCoord);
                half3 lightColAtten = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
                

                // UnderWater Diffuse
                half underWaterDiffu = saturate(dot(half3(0,1,0), mainLight.direction));

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

