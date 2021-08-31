
// @ https://www.zhihu.com/people/jefford-55


Shader "Jefford/Primrose/BasePBR"
{
    Properties
    {
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        _BumpScale("Scale", Float) = 1.0
        [NoScaleOffset]_NormalMap("NormalMap", 2D) = "bump" {}
        [NoScaleOffset]_MetallicMap("_MetallicMap", 2D) = "white" {}
        _Metallic("_Metallic",Range(0,1)) = 1
        [NoScaleOffset]_RoughnessMap("_RoughnessMap", 2D) = "white" {}
        _Roughness("_Roughness",Range(0,1)) = 1
        [NoScaleOffset]_AOMap("_AOMap", 2D) = "white" {}
        _AO("_AO",Range(0,1)) = 1
        [NoScaleOffset] _CubeMap("_CubeMap",Cube) = "white"{}
        
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
            half _Roughness;
            half _Metallic;
            half _BumpScale;
            half _AO;

            CBUFFER_END

            TEXTURE2D(_MetallicMap);          SAMPLER(sampler_MetallicMap);
            TEXTURE2D(_RoughnessMap);         SAMPLER(sampler_RoughnessMap);
            TEXTURE2D(_AOMap);                SAMPLER(sampler_AOMap);
            TEXTURE2D(_NormalMap);            SAMPLER(sampler_NormalMap);
            TEXTURECUBE(_CubeMap);            SAMPLER(sampler_CubeMap);


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

            
            half3 LightingPhysicallyBased1(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
            {
                half3 lightColor = light.color;
                half3 lightDirectionWS = light.direction;
                half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;

                half NdotL = saturate(dot(normalWS, lightDirectionWS)) * 0.8 + 0.2;
                half3 radiance = lightColor * (lightAttenuation * NdotL);

                half3 brdf = brdfData.diffuse;
                
                brdf += brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);

                return brdf * radiance;
            }



            half4 LitPassFragment(Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);


                // --------------------------------------- 纹理采样 ---------------------------------------
                half4 baseMap = SampleAlbedoAlpha(i.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)) * _BaseColor;
                half metallicMap = SAMPLE_TEXTURE2D(_MetallicMap, sampler_MetallicMap,i.uv);
                half roughnessMap = SAMPLE_TEXTURE2D(_RoughnessMap, sampler_RoughnessMap,i.uv);
                half aoMap = SAMPLE_TEXTURE2D(_AOMap,sampler_AOMap,i.uv);

                half4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv);
                half3 normapTS= UnpackNormalScale(normalMap,_BumpScale);

                half3x3 tbn = half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);
                half3 normalWS = NormalizeNormalPerPixel( mul(normapTS, tbn));

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord = i.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                #else
                    float4 shadowCoord = float4(0, 0, 0, 0);
                #endif
                
                // ---------------------------------------
                half3 albedo = baseMap.rgb;
                half alpha = baseMap.a;
                half metallic = saturate(metallicMap * _Metallic);
                half smoothness = saturate((1 - roughnessMap) * _Roughness);
                half occlusion = saturate((1 - aoMap) * _AO);
                half3 emission = 0;
                half3 specular = 0;

                half3 bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, normalWS);
                float3 viewDirWS = SafeNormalize(float3(i.normalWS.w, i.tangentWS.w, i.bitangentWS.w));

                BRDFData brdfData;
                InitializeBRDFData(albedo.rgb, metallic, specular, smoothness, alpha, brdfData);
                
                Light mainLight = GetMainLight(shadowCoord);
                MixRealtimeAndBakedGI(mainLight, normalWS, bakedGI, half4(0, 0, 0, 0));


                half3 indirect = 1;
                {
                    half3 indirectDiffuse = bakedGI * occlusion * brdfData.diffuse;

                    half3 reflectVector = reflect(-viewDirWS, normalWS);
                    half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDirWS)));

                    half mip = PerceptualRoughnessToMipmapLevel(brdfData.perceptualRoughness);
                    half4 cubeMap = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, reflectVector, mip);
                    half3 ibl = DecodeHDREnvironment(cubeMap, unity_SpecCube0_HDR) * occlusion;

                    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
                    half3 indirectSpecular = surfaceReduction * ibl * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);
                    indirect = indirectDiffuse + indirectSpecular;
                }

                
                half3 color = indirect;
                color += LightingPhysicallyBased1(brdfData, mainLight, normalWS, viewDirWS);

                #ifdef _ADDITIONAL_LIGHTS
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                    {
                        Light light = GetAdditionalLight(lightIndex, i.positionWS);
                        color += LightingPhysicallyBased1(brdfData, light, normalWS, viewDirWS);
                    }
                #endif
                
                clip(alpha - 0.5);
                return half4(color,1);
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

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMeta

            #pragma shader_feature _SPECULAR_SETUP
            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICSPECGLOSSMAP
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma shader_feature _SPECGLOSSMAP

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"

            ENDHLSL
        }



    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    // CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.LitShader"
}
