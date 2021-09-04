
Shader "Jefford/Cloth Shading 整理"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}
        _ClothCubeMap("环境反射CubeMap",Cube) = "white" {}
        _ClothCubeIntensity("_ClothCubeIntensity",Range(0,1)) = 0.5
        [NoScaleOffset]_MaskMap("Thickness厚度:(G) AO:(B) Alpha:(A)", 2D) = "white" {}
        _OcclusionStrength("AO强度",Range(0,1)) = 1
        _ClothSpecColor("高光颜色",color) = (1,1,1,1)
        _Smoothness("光滑度",Range(0, 1)) = 1

        _BumpMap("法线",2D) = "bump"{}
        _BumpScale("_BumpScale",Range(0,1.5)) = 1

        [Toggle] _COTTONWOOL("是否为绒面材质",int) = 0
        _SheenColor("Sheen Color", Color) = (0.5, 0.5, 0.5,1)
        _GGXAnisotropy("GGX各向异性偏移系数", Range(-1.0, 1.0)) = 0.0

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
            "IgnoreProjector" = "false"
        }

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Cull off

            HLSLPROGRAM
            
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma shader_feature _COTTONWOOL_ON
            #pragma shader_feature _SCATTERING_ON

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            
            #include "ShaderLibrary/InputData.hlsl"
            #include "ShaderLibrary/GGX_ClothLighting.hlsl"


            struct Attributes
            {
                float4 positionOS               : POSITION;
                float3 normalOS                 : NORMAL;
                float4 tangentOS                : TANGENT;
                float2 uv                       : TEXCOORD0;
                
            };        
            
            struct Varyings        
            {        
                float4 positionCS               : SV_POSITION;
                float4 uv                       : TEXCOORD0;
                float positionWS                : TEXCOORD1;
                float3 normalWS                 : TEXCOORD3;    
                float3 tangentWS                : TEXCOORD4;
                float3 bitangentWS              : TEXCOORD5;
                float3 viewDirWS                : TEXCOORD6;
                half3 vertexSH                  : TEXCOORD7;
            };


            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = mul(UNITY_MATRIX_VP, mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0))); 
                o.positionWS = mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0)).xyz;
                o.uv.xy = TRANSFORM_TEX(v.uv, _BaseMap);
                o.uv.zw = v.uv;

                half3 normalWS;
                {
                    #ifdef UNITY_ASSUME_UNIFORM_SCALING
                        normalWS = SafeNormalize(mul((float3x3)UNITY_MATRIX_M, v.normalOS));
                    #else
                        normalWS = SafeNormalize(mul(v.normalOS, (float3x3)UNITY_MATRIX_I_M));
                    #endif
                }

                o.normalWS = normalWS;
                o.tangentWS = SafeNormalize(mul((float3x3)UNITY_MATRIX_M, v.tangentOS.xyz));
                half sign = v.tangentOS.w * unity_WorldTransformParams.w;
                o.bitangentWS = cross(o.normalWS, o.tangentWS) * sign;
                o.viewDirWS = _WorldSpaceCameraPos - o.positionWS;
                o.vertexSH = SampleSHVertex(o.normalWS);
                return o;
            }

            // facing: 双面渲染的情况下，正面为白色，背面为黑色
            half4 frag(Varyings i, half facing : VFACE) : SV_Target
            {
                
                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv.xy);
                half4 maskMap = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv.zw);

                float3x3 tbn = float3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);
                half4 normal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv);
                half3 normalTS = UnpackNormalScale(normal, _BumpScale);
                normalTS.z *= facing;
                
                TextureData texData;
                ZERO_INITIALIZE(TextureData, texData);
                texData.albedo = baseMap.rgb * _BaseColor.rgb;
                texData.smoothness = baseMap.a * _Smoothness;
                texData.occlusion =lerp(1 ,maskMap.b, _OcclusionStrength);
                texData.metallic = 0;
                texData.specular = _ClothSpecColor;
                texData.alpha = maskMap.b;

                VectorData vectorData;
                ZERO_INITIALIZE(VectorData, vectorData);
                vectorData.viewDirWS = SafeNormalize(i.viewDirWS);
                vectorData.normalWS = NormalizeNormalPerPixel(mul(normalTS, tbn));
                vectorData.tbn = tbn;

                AdditionalData addData;
                BRDFData brdfData;
                half3 normalWS = 0;

                GGX_ClothData(addData, brdfData, normalWS, vectorData, texData);

                half3 sh = SampleSHPixel(i.vertexSH, normalWS);


                Light mainLight = GetMainLight(shadowCoord);
                half3 indirect =  ClothIndirect( mainLight, sh, normalWS, texData, brdfData, addData, vectorData);
                half3 direct = DirectBDRF_LuxCloth( brdfData, mainLight, addData, normalWS, vectorData.viewDirWS);
                half3 c = indirect + direct;

                #if defined(_SCATTERING_ON)
                    // 厚度
                    half thickness = maskMap.g * _ThicknessStrength;
                    half3 translucencyColor = TranslucencyColor(mainLight, thickness, normalWS, vectorData.viewDirWS);
                    c += translucencyColor;
                #endif
                

                #ifdef _ADDITIONAL_LIGHTS
                    int pixelLightCount = GetAdditionalLightsCount();
                    for (int j = 0; j < pixelLightCount; ++j)
                    {
                        Light light = GetAdditionalLight(j, i.positionWS);
                        c += DirectBDRF_LuxCloth( brdfData, light, addData, normalWS, vectorData.viewDirWS);

                        #if defined(_SCATTERING)
                            c + =TranslucencyColor(light, thickness, normalWS, vectorData.viewDirWS);
                        #endif
                    }
                #endif
                
                return half4(c, 1);
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
}

