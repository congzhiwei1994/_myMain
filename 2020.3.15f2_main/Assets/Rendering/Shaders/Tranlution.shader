
// @ https://www.zhihu.com/people/jefford-55


Shader "Jefford/Tranlution(玉石)"
{
    Properties
    {
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        _BumpScale("Scale", Float) = 1.0
        [NoScaleOffset]_BumpMap("Normal Map", 2D) = "bump" {}

        [NoScaleOffset]_MixMap("Metallic(R) Smoothness(G) Occlusion(B) EmissionMask(A)", 2D) = "white" {}
        [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0
        _OcclusionStrength("Occlusion", Range(0.0, 1.0)) = 1.0

        _CubeMap("_CubeMap", Cube) = "white" {}

        [Space(10)]
        [Header(Tranlution)]
        _ThicknessMap("厚度纹理", 2D) = "white" {}
        _ThicknessIntensity("厚度强度",Range(0,2)) = 1
        _TranlutionDistort("透射扭曲",Range(0,1)) = 0.2
        _TranlutionRange("透射范围",Range(0,50)) = 0.2
        _TranlutionIntensity("透射强度",Range(0,5)) = 1
        
    }

    SubShader
    {
        Tags 
        {
            "Queue"="Geometry"
            "RenderType" = "Opaque" 
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
        }

        
        Pass
        {
            
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}


            HLSLPROGRAM
            
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half4 _EmissionColor;
            half _Smoothness;
            half _Metallic;
            half _BumpScale;
            half _EmissionIntensity;
            half _OcclusionStrength;

            half _TranlutionDistort;
            half _TranlutionRange;
            half _TranlutionIntensity;
            half _ThicknessIntensity;
            CBUFFER_END

            TEXTURE2D(_MixMap);             SAMPLER(sampler_MixMap);
            TEXTURE2D(_ThicknessMap);       SAMPLER(sampler_ThicknessMap);
            TEXTURECUBE(_CubeMap);       SAMPLER(sampler_CubeMap);



            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv                       : TEXCOORD0;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);             
                float3 positionWS               : TEXCOORD2;                     
                float4 normalWS                 : TEXCOORD3;    // xyz: normal, w: viewDir.x
                float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: viewDir.y
                float4 bitangentWS              : TEXCOORD5;    // xyz: bitangent, w: viewDir.z               
                half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord              : TEXCOORD7;
                #endif

                float4 positionCS               : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // ----------------------------------------------------------------------------------------------------

            half3 GlossyEnvironmentReflection1(half3 reflectVector, half perceptualRoughness, half occlusion)
            {
                half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
                half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, reflectVector, mip);
                half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
                return irradiance * occlusion;
            }
            
            half3 GlobalIllumination1(BRDFData brdfData, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS)
            {
                half3 reflectVector = reflect(-viewDirectionWS, normalWS);
                half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDirectionWS)));

                half3 indirectDiffuse = bakedGI * occlusion * brdfData.diffuse;
                half3 ibl = GlossyEnvironmentReflection1(reflectVector, brdfData.perceptualRoughness, occlusion);

                float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
                half3 indirectSpecular = surfaceReduction * ibl * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);

                half3 indirect = indirectDiffuse + indirectSpecular;
                return indirect;
            }

            half3 Translution( Light light, half3 V, half3 N, half3 albedo)
            {
                half3 L = -light.direction;
                half3 lightColor = light.color;
                half atten = light.distanceAttenuation;

                half3 H = SafeNormalize(L + N * _TranlutionDistort);
                half VoH = saturate(dot(V,H));
                VoH = max(0.001, pow(VoH, _TranlutionRange)) * _TranlutionIntensity;
                half3 color = VoH * lightColor * albedo * atten;
                return color;
            }
            

            half4 UniversalFragmentPBR1(half thickness, InputData inputData, half3 albedo, half metallic, half3 specular,
            half smoothness, half occlusion, half3 emission, half alpha)
            {
                BRDFData brdfData;
                InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);
                
                Light mainLight = GetMainLight(inputData.shadowCoord);
                MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

                half3 color = GlobalIllumination1(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS);
                color += LightingPhysicallyBased(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS);

                half3 T = Translution(mainLight, inputData.viewDirectionWS, inputData.normalWS, albedo) * thickness;
                color += T;
                #ifdef _ADDITIONAL_LIGHTS
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                    {
                        Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
                        color += LightingPhysicallyBased(brdfData, light, inputData.normalWS, inputData.viewDirectionWS);
                        color += Translution(light, inputData.viewDirectionWS, inputData.normalWS, albedo) * thickness;
                    }
                #endif

                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    color += inputData.vertexLighting * brdfData.diffuse;
                #endif

                color += emission;
                
                return half4(color, alpha);
            }

            // ----------------------------------------------------------------------------------------------------

            Varyings LitPassVertex(Attributes v)
            {
                Varyings o = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);

                o.positionWS = mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0)).xyz;
                o.positionCS = mul(UNITY_MATRIX_VP, mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0)));             

                // ------------ 法线 ------------
                half3 normalWS;
                {
                    #ifdef UNITY_ASSUME_UNIFORM_SCALING
                        normalWS = SafeNormalize(mul((float3x3)UNITY_MATRIX_M, v.normalOS));
                    #else
                        // Normal need to be multiply by inverse transpose
                        normalWS = SafeNormalize(mul(v.normalOS, (float3x3)UNITY_MATRIX_I_M));
                    #endif
                }

                // ------------ 切线 ------------
                half3 tangentWS = mul((float3x3)UNITY_MATRIX_M, v.tangentOS.xyz);
                tangentWS = SafeNormalize(tangentWS);

                // ------------ 副切线 ------------
                half sign = v.tangentOS.w * unity_WorldTransformParams.w;
                half3 bitangentWS = cross(normalWS,tangentWS) * sign;

                // ------------ 视线 ------------
                half3 viewDirWS = _WorldSpaceCameraPos - o.positionWS;

                o.normalWS = half4(normalWS, viewDirWS.x);
                o.tangentWS = half4(tangentWS, viewDirWS.y);
                o.bitangentWS = half4(bitangentWS, viewDirWS.z); 


                half3 vertexLight = VertexLighting(o.positionWS,normalWS);
                half fogFactor = ComputeFogFactor(o.positionCS.z);
                o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
                OUTPUT_SH(o.normalWS.xyz, o.vertexSH);

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    o.shadowCoord = TransformWorldToShadowCoord(o.positionWS);
                #endif

                return o;
            }

            
            half4 LitPassFragment(Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                // --------------------------------------- 纹理采样 ---------------------------------------
                half4 albedo = SampleAlbedoAlpha(i.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)) * _BaseColor;
                half4 mixMap = SAMPLE_TEXTURE2D(_MixMap, sampler_MixMap,i.uv);
                half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap,i.uv);
                half3 normapTS= UnpackNormalScale(normalMap,_BumpScale);

                half4 thickness = SAMPLE_TEXTURE2D(_ThicknessMap, sampler_ThicknessMap,i.uv);
                thickness = saturate(thickness.g * _ThicknessIntensity);
                
                // --------------------------------------- SurfaceData ---------------------------------------

                SurfaceData surfaceData;
                ZERO_INITIALIZE(SurfaceData, surfaceData);
                surfaceData.albedo = albedo.rgb;
                surfaceData.alpha = albedo.a;
                surfaceData.metallic = saturate(mixMap.r * _Metallic);
                surfaceData.specular = half3(0.0h, 0.0h, 0.0h);
                surfaceData.smoothness = saturate((1 - mixMap.g) * _Smoothness);
                surfaceData.normalTS = normapTS;
                surfaceData.occlusion = saturate(mixMap.b * _OcclusionStrength);
                surfaceData.emission = 0;

                // --------------------------------------- 数据 ---------------------------------------
                half3 viewDirWS = half3(i.normalWS.w, i.tangentWS.w, i.bitangentWS.w);
                half3x3 tbn = half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);

                // --------------------------------------- InputData ---------------------------------------
                InputData inputData;
                ZERO_INITIALIZE(InputData, inputData);
                inputData.positionWS = i.positionWS;
                
                inputData.normalWS =  mul(surfaceData.normalTS, tbn);
                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                inputData.viewDirectionWS = SafeNormalize(viewDirWS);

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = i.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif

                inputData.fogCoord = i.fogFactorAndVertexLight.x;
                inputData.vertexLighting = i.fogFactorAndVertexLight.yzw;
                inputData.bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, inputData.normalWS);

                half4 color = UniversalFragmentPBR1(thickness, inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha);

                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                return color;
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

    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    // CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.LitShader"
}
