
Shader "Jefford/Lux_River"
{
    Properties
    {
        // _BaseColor("Base Color",color) = (1,1,1,1)
        // _BaseMap("BaseMap", 2D) = "white" {}
        _WaterColor("水体的颜色",Color) = (1, 1, 1, 1)
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Float) = 1.0
        _DetailMapScale("_DetailMapScale", Float) = 1.0
        _NormalTilling("_NormalTilling",Range(0,20)) = 1
        _Speed("_Speed",Range(0,1)) = 0.3
        _WaterDirX("_WaterDirX",Range(-1,1)) = 0.5
        _WaterDirZ("_WaterDirZ",Range(-1,1)) = 0.5

        [Space(20)]
        [Toggle] _Refract("是否开启折射",int) = 0
        _RefractDistor("折射偏移系数", Range(0,1)) = 1
        _ShoreBlend("深水到岸边的混合因子", Range(0.001,1)) = 1
        _WaterDepth("控制水深浅系数",float) = 1

        [Space(20)]
        [Header(Env)]
        _WaterSpecular("水高光颜色", COLOR) = (1, 1, 1, 1)
        _WaterSmoothness("水体光滑度", Range(0, 1)) = 1
        _FoamSmoothness("泡沫光滑度",Range(0, 1)) = 1
        _CubeMapNoiseFactor("环境高光扭曲因子",Range(0,1)) = 0.5

        [Space(20)]
        [Header(FoamLight)]
        [Toggle] _Foam("是否开启水体泡沫",int) = 0
        _FoamColor("_FoamColor",color) = (1,1,1,1)
        _FoamMap("泡沫颜色纹理", 2D) = "white" {}
        _FoamTiling("_Foam Tiling", Range(0, 20)) = 1
        _FoamScale("泡沫的强度",float) = 1
        _FoamWidth("水体泡沫的宽度",float) = 1
        _FoamSpeed("泡沫的流速", Range(0,1)) = 1
        _FoamDir_X("泡沫的X方向",Range(-1,1)) = 0.5
        _FoamDir_Z("泡沫的Z方向",Range(-1,1)) = 0.5
        _FoamSlopIntensity("斜坡泡沫的强度", float) = 1
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha 

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
            // half4 _BaseColor;
            // float4 _BaseMap_ST;
            float _BumpScale;
            float4 _BumpMap_ST;
            half _DetailMapScale;
            half _NormalTilling;

            half _Speed;
            half _WaterDirX;
            half _WaterDirZ;
            half _WaterSmoothness;
            half4 _WaterSpecular;

            half _RefractDistor;
            half _ShoreBlend;

            half4 _FoamColor;
            half _FoamTiling;
            half _FoamSpeed;
            half _FoamDir_X;
            half _FoamDir_Z;
            half _FoamSlopIntensity;
            half _FoamWidth;
            half _FoamSmoothness;
            half _FoamScale;

            half _WaterDepth;
            half4 _WaterColor;
            half _CubeMapNoiseFactor;
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
                half3 V                : TEXCOORD8;

            };


            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.uv = TRANSFORM_TEX(v.uv,_BumpMap);
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
                o.V = _WorldSpaceCameraPos - o.positionWS;
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
                // 阴影坐标
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord = i.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                #else
                    float4 shadowCoord = float4(0, 0, 0, 0);
                #endif
                
                half3 SH = i.SH;
                half3 vertexLight = i.vertexLight;
                half3 V = SafeNormalize(i.V);

                // -----------------------------------------------------------------------

                half3x3 tbn = half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);

                half2 waterDir = _Time.y * _Speed * half2(_WaterDirX,_WaterDirZ);
                half2 uv_normal = uv * _NormalTilling + waterDir;

                half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap,uv);
                half3 normapTS = UnpackNormalScale(normalMap,_BumpScale);
                half4 detailMap = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap,uv_normal);
                half3 detailMapTS = UnpackNormalScale(detailMap,_DetailMapScale);
                // 法线混合
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
                    // 折射偏移系数随着镜头距离拉远，偏移值逐渐变小
                    float2 offset = blendNormalTS.xy * _RefractDistor * distanceFadeFactor;
                #else
                    float2 offset = 0;
                #endif

                half depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV + offset);
                half sceneDepth = LinearEyeDepth(depthMap, _ZBufferParams);
                // 深度差，边缘为0
                half depth = sceneDepth - i.positionCS.w; 


                // 折射纹理采样
                half3 refractColor = 0;
                #if defined _REFRACT_ON 
                    offset = screenUV + offset * saturate(depth);
                    depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, offset);
                    sceneDepth = LinearEyeDepth(depthMap, _ZBufferParams);
                    depth = sceneDepth - i.positionCS.w;

                    // 折射纹理采样
                    refractColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, saturate(offset));
                    refractColor = saturate(refractColor);
                #endif
                half3 refractMap = refractColor;

                // 0 - 1 之间的曲线过渡 , 岸边是0 中间是1
                half waterDepth = saturate(1 - exp(-depth * _WaterDepth));
                half underWaterFactor = waterDepth;
                

                half smoothness = _WaterSmoothness;
                #if defined _FOAM_ON
                    // 泡沫的宽度
                    half foamWidth = saturate(_FoamWidth * depth);
                    // 泡沫的噪点
                    half foamNoise = blendNormalTS.z * 2 - 1;
                    // 岸边的泡沫, 反向之后 * 泡沫的噪点，即只有边缘地方有泡沫
                    half shoreFoam = saturate((1 - foamWidth) * (1 + foamNoise));
                    // 深水和浅水区域为 0
                    half shoreFoamMask = saturate(foamWidth - foamWidth * foamWidth);
                    shoreFoam *= shoreFoamMask;

                    half2 foamDir = _FoamSpeed * _Time.y * half2(_FoamDir_X,_FoamDir_Z);
                    half2 uv_foam = _FoamTiling * uv + foamDir + blendNormalTS.xy * 0.02;
                    half4 foamColor = half4(_FoamColor.rgb,1);
                    half4 foamMap = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap, uv_foam) * foamColor;
                    
                    // 斜坡区域的泡沫
                    half slopeMask = saturate(1 - i.normalWS.y);
                    half slopeFoam = slopeMask * _FoamSlopIntensity;
                    // 岸边泡沫和斜坡泡沫相加
                    shoreFoam += slopeFoam;

                    foamMap.a = saturate(foamMap.a * shoreFoam * _FoamScale  * ( 1 - (blendNormalTS.x + blendNormalTS.y) * 4) );
                    
                    // 获得泡沫的光滑度
                    half a = 0.8 - foamMap.a;    // (-0.2 - 0.8)
                    half b = 1.6 - foamMap.a;   //  0.6 - 1.6
                    foamMap.a = foamMap.a * smoothstep(a, b, foamMap.a);
                    smoothness = lerp(smoothness, _FoamSmoothness, foamMap.a);
                #endif


                half reflectivity = ReflectivitySpecular(_WaterSpecular);
                half oneMinusReflectivity = 1.0 - reflectivity;
                half perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
                half roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
                half roughness2 = roughness * roughness;
                half normalizationTerm = roughness * 4.0h + 2.0h;

                Light mainLight = GetMainLight(shadowCoord);
                half3 lightColAtten = mainLight.color * mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                half NdotL = saturate(dot( i.normalWS, mainLight.direction));
                
                half3 SH_VertexLight = SH + vertexLight;
                half3 waterDiffuse = 0;
                {
                    half3 underWater_NoL = saturate(dot(half3(0,1,0), mainLight.direction));
                    // 通过水的深度来衰减主灯阴影 
                    half waterShadow = lerp(mainLight.shadowAttenuation, 1, underWaterFactor); 
                    
                    waterDiffuse = underWater_NoL * mainLight.color * mainLight.distanceAttenuation ;
                    waterDiffuse = _WaterColor * (waterDiffuse * waterShadow + SH_VertexLight);
                }
                

                // Foam Diffuse
                half3 foamDiffuse = 0;
                {
                    #if defined _FOAM_ON
                        foamDiffuse = foamMap.rgb * (lightColAtten * NdotL + SH_VertexLight);
                    #endif
                    
                }
                
                
                // 直接光 高光
                half3 directSpecular = 1;
                {
                    float3 H = SafeNormalize(float3(mainLight.direction) + float3(V));
                    float NoH = saturate(dot(normalWS, H));
                    half LoH = saturate(dot(mainLight.direction, H));
                    float d = NoH * NoH * (roughness2 - 1.h) + 1.0001f;
                    half LoH2 = LoH * LoH;
                    half specularTerm = roughness2 / ((d * d) * max(0.1h, LoH2) * normalizationTerm );
                    #if defined (SHADER_API_MOBILE)
                        specularTerm = specularTerm - HALF_MIN;
                        specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
                    #endif
                    directSpecular = specularTerm * _WaterSpecular * lightColAtten;
                    directSpecular *= NdotL;
                }
                // 环境高光
                half3 indirectSpecular = 0;
                {
                    half3 reflectionNormal = lerp( i.normalWS.xyz, normalWS, _CubeMapNoiseFactor);
                    half3 reflectionVector = reflect(-V, reflectionNormal);
                    half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, V)));
                    half occlusion = 1;
                    indirectSpecular = GlossyEnvironmentReflection(reflectionVector, perceptualRoughness, occlusion);
                    float surfaceReduction = 1.0 / (roughness2 + 1.0);
                    half grazingTerm = saturate(smoothness + reflectivity);
                    indirectSpecular = indirectSpecular * surfaceReduction * lerp(_WaterSpecular, grazingTerm, fresnelTerm);
                }
                
                half3 specular = directSpecular + indirectSpecular;
                
                
                #ifdef _ADDITIONAL_LIGHTS
                    int pixelLightCount = GetAdditionalLightsCount();
                #endif
                
                // 额外灯计算
                #ifdef _ADDITIONAL_LIGHTS 
                    
                    for (int j = 0; j < pixelLightCount; ++j)
                    {
                        Light light = GetAdditionalLight(j, i.positionWS);
                        NdotL = saturate(dot(normalWS, light.direction));
                        half diffuse_nl = saturate(dot(half3(0,1,0), light.direction));
                        
                        half3 addLightColorAndAttenuation = light.color * light.distanceAttenuation * light.shadowAttenuation;
                        waterDiffuse += _WaterColor.rgb * addLightColorAndAttenuation * diffuse_nl;
                        #if defined(_FOAM)
                            foamDiffuse += foamMap.rgb * addLightColorAndAttenuation * NdotL;
                        #endif
                        
                        float3 H = SafeNormalize(float3(light.direction) + float3(V));
                        float NoH = saturate(dot(normalWS, H));
                        float LoH = saturate(dot(light.direction, H));
                        float d = NoH * NoH * (roughness2 - 1.h) + 1.0001f;
                        float LoH2 = LoH * LoH;
                        float specularTerm = roughness2 / ((d * d) * max(0.1h, LoH2) * normalizationTerm );
                        #if defined (SHADER_API_MOBILE)
                            specularTerm = specularTerm - HALF_MIN;
                            specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
                        #endif
                        specular += specularTerm * _WaterSpecular * addLightColorAndAttenuation;
                    }
                #endif

                // 计算折射颜色
                #if defined _REFRACT_ON
                    refractColor = lerp(refractColor, waterDiffuse, underWaterFactor);
                #else
                    refractColor = waterDiffuse * (underWaterFactor);
                #endif
                

                half3 color = refractColor;
                #if defined _FOAM_ON
                    color = lerp(color, foamDiffuse, foamMap.a);
                #endif
                
                
                color += specular;
                half alpha = 1;
                half shoreBlendFactor = saturate(depth / _ShoreBlend );
                #if defined _REFRACT_ON
                    color = lerp(refractMap, color, shoreBlendFactor);
                #else
                    #if defined _FOAM_ON
                        float visibility = saturate(underWaterFactor + foamMap.a) * oneMinusReflectivity + reflectivity;
                    #else
                        float visibility = underWaterFactor * oneMinusReflectivity + reflectivity;
                    #endif
                    color.rgb *= shoreBlendFactor;
                    alpha = shoreBlendFactor * visibility;
                #endif

                return half4(color,alpha);


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

