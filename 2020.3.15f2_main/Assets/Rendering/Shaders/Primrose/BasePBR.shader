
// @ https://www.zhihu.com/people/jefford-55


Shader "Jefford/Primrose/BasePBR"
{
    Properties
    {
        [MainColor] _BaseColor("基本颜色", Color) = (1,1,1,1)
        [MainTexture] _BaseMap("固有色纹理", 2D) = "white" {}
        _BumpScale("法线缩放", Float) = 1.0
        [NoScaleOffset]_NormalMap("法线纹理", 2D) = "bump" {}
        [NoScaleOffset]_MetallicMap("金属度纹理", 2D) = "white" {}
        _Metallic("金属度强度",Range(0,1)) = 1
        [NoScaleOffset]_RoughnessMap("粗糙度纹理", 2D) = "white" {}
        _Smoothness("光滑度强度",Range(0,1)) = 1
        [NoScaleOffset]_AOMap("AO纹理", 2D) = "white" {}
        _OcclusionStrength("AO强度",Range(0,1)) = 1
        [NoScaleOffset]_ClothMaskMap("衣服遮罩(0是衣服)", 2D) = "white" {}
        [NoScaleOffset] _CubeMap("_CubeMap",Cube) = "white"{}

        [Space(10)]
        [Header(Cloth)]
        [Toggle] _COTTONWOOL("是否为绒面材质",int) = 0
        _SheenColor("绒面颜色", Color) = (0.5, 0.5, 0.5,1)
        _ClothSpecColor("各向异性高光颜色", Color) = (0.5, 0.5, 0.5,1)
        _GGXAnisotropy("GGX各向异性偏移系数", Range(-1.0, 1.0)) = 0.0

        [NoScaleOffset]_ClothCubeMap("衣服环境反射CubeMap",Cube) = "white" {}
        _ClothCubeIntensity("衣服环境反射强度",Range(0,1)) = 0.5

        [Space(10)]
        [Toggle] _Scattering("是否开启散射",int) = 0
        _TranslucencyColor("透射颜色",color) = (1,1,1,1)
        _TranslucencyPower("投射范围", Range(0.0, 32.0)) = 7.0
        _ThicknessStrength("厚度", Range(0.0, 1.0)) = 1.0
        _ShadowStrength("阴影强度", Range(0.0, 1.0)) = 0.7
        _Distortion("透射扭曲强度", Range(0.0, 0.1)) = 0.01
        

        
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

            #pragma shader_feature _COTTONWOOL_ON
            #pragma shader_feature _SCATTERING_ON

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

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
            
            #include "../ShaderLibrary/InputData.hlsl"
            #include "../ShaderLibrary/BasePBRLighting.hlsl"
            #include "../ShaderLibrary/GGX_ClothLighting.hlsl"


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

            half4 LitPassFragment(Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);


                // --------------------------------------- 纹理采样 ---------------------------------------
                half4 baseMap = SampleAlbedoAlpha(i.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)) * _BaseColor;
                half metallicMap = SAMPLE_TEXTURE2D(_MetallicMap, sampler_MetallicMap,i.uv);
                half roughnessMap = SAMPLE_TEXTURE2D(_RoughnessMap, sampler_RoughnessMap,i.uv);
                half aoMap = SAMPLE_TEXTURE2D(_AOMap,sampler_AOMap,i.uv);
                
                half clothMask = SAMPLE_TEXTURE2D(_ClothMaskMap,sampler_ClothMaskMap, i.uv).r;

                half4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv);
                half3 normalTS= UnpackNormalScale(normalMap,_BumpScale);
                half3x3 tbn = half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord = i.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                #else
                    float4 shadowCoord = float4(0, 0, 0, 0);
                #endif
                

                TextureData texData;
                ZERO_INITIALIZE(TextureData, texData);
                texData.albedo = baseMap.rgb * _BaseColor.rgb;
                texData.smoothness = saturate((1 - roughnessMap) * _Smoothness);
                texData.occlusion = lerp(1, aoMap, _OcclusionStrength );
                texData.metallic = saturate(metallicMap * _Metallic);
                texData.specular = _ClothSpecColor;
                texData.alpha = baseMap.a;

                VectorData vectorData;
                ZERO_INITIALIZE(VectorData, vectorData);
                vectorData.viewDirWS = SafeNormalize(float3(i.normalWS.w, i.tangentWS.w, i.bitangentWS.w));
                vectorData.normalWS = NormalizeNormalPerPixel(mul(normalTS, tbn));
                vectorData.tbn = tbn;


                AdditionalData addData;
                BRDFData brdfData;
                half3 normalWS = 1;

                GGX_ClothData(addData, brdfData, normalWS, vectorData, texData);
                Light mainLight = GetMainLight(shadowCoord);

                normalWS = lerp(normalWS, vectorData.normalWS, clothMask);
                half3 bakedGI = SampleSHPixel(i.vertexSH, normalWS);

                half3 clothIndirect = ClothIndirect( mainLight, bakedGI, normalWS, texData, brdfData, addData, vectorData);
                half3 clothDirect = DirectBDRF_LuxCloth( brdfData, mainLight, addData, normalWS, vectorData.viewDirWS);
                half3 clothLight = clothIndirect + clothDirect;

                texData.specular = 0;
                InitializeBRDFData(texData.albedo.rgb, texData.metallic, texData.specular, texData.smoothness, texData.alpha, brdfData);
                half3 indirect = BasePBRIndirect( mainLight, bakedGI, normalWS, texData, brdfData, vectorData);
                half3 direct = LightingPhysicallyBased1(brdfData, mainLight, normalWS, vectorData.viewDirWS);
                half3 baseLight = indirect + direct;
                
                #if defined(_SCATTERING_ON)
                    // 厚度
                    half thickness =  _ThicknessStrength;
                    half3 translucencyColor = TranslucencyColor(mainLight, thickness, normalWS, vectorData.viewDirWS);
                    clothLight += translucencyColor;
                #endif



                half3 color = lerp(clothLight, baseLight, clothMask);
                #ifdef _ADDITIONAL_LIGHTS
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                    {
                        Light light = GetAdditionalLight(lightIndex, i.positionWS);
                        color += LightingPhysicallyBased1(brdfData, light, normalWS, vectorData.viewDirWS);
                    }
                #endif

                color = ACESFilm(color);
                
                clip(texData.alpha - 0.5);
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
