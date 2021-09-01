
Shader "Jefford/Terrian/4M BilinPhong"
{
    Properties
    {
        [Toggle]_IsVertex("是否开启顶点色控制",float) = 0
        _BlendMap("混合控制图", 2D) = "white" {}
        _BlendContract_All("混合对比度",Range(0.001,1)) = 0.1
        _ShadowColor("阴影颜色",color) = (0.1,0.1,0.1,1)
        _MainShadow("阴影强度",Range(0,1)) = 0.5

        [Header(Layer1)]
        _Layer1_BaseColor("第一层纹理颜色",color) = (1,1,1,1)
        _Layer1_BaseMap("第一层颜色纹理(RGB), 光滑度(A)", 2D) = "white" {}
        [NoScaleOffset]_Layer1_NormalMap("第一层法线纹理", 2D) = "bump" {}
        [NoScaleOffset]_Layer1_MaskMap("第一层遮罩纹理,高度(R)", 2D) = "black" {}
        _Layer1_BlendContract("Layer1高度对比度",Range(0,1)) = 0.2
        _Layer1_SpecularColor("第一层高光颜色",color) = (1,1,1,1)
        _Layer1_Smoothness("第一层粗糙度",Range(0,5)) = 1
        _Layer1_SpecularIntensity("第一层高光强度",Range(0,5)) = 1

        [Space20]
        [Header(Layer2)]
        _Layer2_BaseColor("第二层纹理颜色",color) = (1,1,1,1)
        _Layer2_BaseMap("第二层颜色纹理(RGB), 光滑度(A)", 2D) = "white" {}
        [NoScaleOffset]_Layer2_NormalMap("第二层法线纹理", 2D) = "bump" {}
        [NoScaleOffset]_Layer2_MaskMap("第二层遮罩纹理,高度(R)", 2D) = "black" {}
        _Layer2_BlendContract("Layer2高度对比度",Range(0,1)) = 0.2
        _Layer2_SpecularColor("第二层高光颜色",color) = (1,1,1,1)
        _Layer2_Smoothness("第二层粗糙度",Range(0,5)) = 1
        _Layer2_SpecularIntensity("第二层高光强度",Range(0,5)) = 1

        [Space20]
        [Header(Layer3)]
        _Layer3_BaseColor("第三层纹理颜色",color) = (1,1,1,1)
        _Layer3_BaseMap("第三层颜色纹理(RGB), 光滑度(A)", 2D) = "white" {}
        [NoScaleOffset]_Layer3_NormalMap("第三层法线纹理", 2D) = "bump" {}
        [NoScaleOffset]_Layer3_MaskMap("第三层遮罩纹理,高度(R)", 2D) = "black" {}
        _Layer3_BlendContract("Layer3高度对比度",Range(0,1)) = 0.2
        _Layer3_SpecularColor("第三层高光颜色",color) = (1,1,1,1)
        _Layer3_Smoothness("第三层粗糙度",Range(0,5)) = 1
        _Layer3_SpecularIntensity("第三层高光强度",Range(0,5)) = 1

        [Space20]
        [Header(Layer4)]
        _Layer4_BaseColor("第四层纹理颜色",color) = (1,1,1,1)
        _Layer4_BaseMap("第四层颜色纹理(RGB), 光滑度(A)", 2D) = "white" {}
        [NoScaleOffset]_Layer4_NormalMap("第四层法线纹理", 2D) = "bump" {}
        [NoScaleOffset]_Layer4_MaskMap("第四层遮罩纹理,高度(R)", 2D) = "black" {}
        _Layer4_BlendContract("Layer4高度对比度",Range(0,1)) = 0.2
        _Layer4_SpecularColor("第四层高光颜色",color) = (1,1,1,1)
        _Layer4_Smoothness("第四层粗糙度",Range(0,5)) = 1
        _Layer4_SpecularIntensity("第四层高光强度",Range(0,5)) = 1

        
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit" 
            "IgnoreProjector" = "True"
        }

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _ISVERTEX_ON
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            
            CBUFFER_START(UnityPerMaterial)
            half _BlendContract_All;
            half4 _ShadowColor;
            half _MainShadow;
            
            half4 _Layer1_BaseColor;
            half4 _Layer1_BaseMap_ST;
            half4 _Layer1_SpecularColor;
            half _Layer1_Smoothness;
            half _Layer1_SpecularIntensity;
            half _Layer1_BlendContract;

            half4 _Layer2_BaseColor;
            half4 _Layer2_BaseMap_ST;
            half4 _Layer2_SpecularColor;
            half _Layer2_Smoothness;
            half _Layer2_SpecularIntensity;
            half _Layer2_BlendContract;

            half4 _Layer3_BaseColor;
            half4 _Layer3_BaseMap_ST;
            half4 _Layer3_SpecularColor;
            half _Layer3_Smoothness;
            half _Layer3_SpecularIntensity;
            half _Layer3_BlendContract;

            half4 _Layer4_BaseColor;
            half4 _Layer4_BaseMap_ST;
            half4 _Layer4_SpecularColor;
            half _Layer4_Smoothness;
            half _Layer4_SpecularIntensity;
            half _Layer4_BlendContract;

            CBUFFER_END
            

            TEXTURE2D (_Layer1_BaseMap);                  SAMPLER(sampler_Layer1_BaseMap);
            TEXTURE2D (_Layer1_NormalMap);                SAMPLER(sampler_Layer1_NormalMap);
            TEXTURE2D (_Layer1_MaskMap);                  SAMPLER(sampler_Layer1_MaskMap);

            TEXTURE2D (_Layer2_BaseMap);                  SAMPLER(sampler_Layer2_BaseMap);
            TEXTURE2D (_Layer2_NormalMap);                SAMPLER(sampler_Layer2_NormalMap);
            TEXTURE2D (_Layer2_MaskMap);                  SAMPLER(sampler_Layer2_MaskMap);

            TEXTURE2D (_Layer3_BaseMap);                  SAMPLER(sampler_Layer3_BaseMap);
            TEXTURE2D (_Layer3_NormalMap);                SAMPLER(sampler_Layer3_NormalMap);
            TEXTURE2D (_Layer3_MaskMap);                  SAMPLER(sampler_Layer3_MaskMap);

            TEXTURE2D (_Layer4_BaseMap);                  SAMPLER(sampler_Layer4_BaseMap);
            TEXTURE2D (_Layer4_NormalMap);                SAMPLER(sampler_Layer4_NormalMap);
            TEXTURE2D (_Layer4_MaskMap);                  SAMPLER(sampler_Layer4_MaskMap);
            

            TEXTURE2D (_BlendMap);                        SAMPLER(sampler_BlendMap);
            

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float3 normalOS         : NORMAL;
                float4 tangentOS        : TANGENT;
                float4 color            : COLOR;
            };

            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float3 positionWS       : TEXCOORD0;
                float3 normalWS         : TEXCOORD1;
                float3 tangentWS        : TEXCOORD2;
                float3 bitangentWS      : TEXCOORD3;

                float2 layer1_UV        : TEXCOORD4;
                float2 layer2_UV        : TEXCOORD5;
                float2 layer3_UV        : TEXCOORD6;
                float2 blend_UV         : TEXCOORD7;
                float3 viewDirWS        : TEXCOORD8;
                float2 layer4_UV        : TEXCOORD9;
                half4 color             : TEXCOORD10;


            };



            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = mul(UNITY_MATRIX_VP, mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0))); 
                o.layer1_UV = TRANSFORM_TEX(v.uv,_Layer1_BaseMap);
                o.layer2_UV = TRANSFORM_TEX(v.uv,_Layer2_BaseMap);
                o.layer3_UV = TRANSFORM_TEX(v.uv,_Layer3_BaseMap);
                o.layer4_UV = TRANSFORM_TEX(v.uv,_Layer4_BaseMap);
                o.blend_UV = v.uv;
                
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
                o.positionWS = mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0));
                o.viewDirWS = _WorldSpaceCameraPos - o.positionWS;
                o.color = v.color;

                

                return o;
            }

            float3 TerrainNormalWS(half4 normalMap, float3x3 tbn)
            {
                half3 normalTS = UnpackNormal(normalMap);
                float3 normalWS = NormalizeNormalPerPixel(mul(normalTS, tbn));
                return normalWS;
            }

            float3 ACESFilm(float3 x)
            {
                float a = 2.51f;
                float b = 0.03f;
                float c = 2.43f;
                float d = 0.59f;
                float e = 0.14f;
                return saturate((x*(a*x + b))/(x*(c*x+d) + e));
            }
            
            // 高度混合因子
            half4 BlendWeight(half4 blendMap, half layer1Height, half layer2Height, half layer3Height, half layer4Height, half BlendContract)
            {
                half R = layer1Height + blendMap.r;
                half G = layer2Height + blendMap.g;
                half B = layer3Height + blendMap.b;
                half A = layer4Height + blendMap.a;

                half m = max(max(max(R,G),B),A);
                half heright = m - BlendContract;
                R = max(0, (R - heright));
                G = max(0, (G - heright));
                B = max(0, (B - heright));
                A = max(0, (A - heright));

                half4 blendFactor = half4( R,G,B,A);
                blendFactor = blendFactor / (R + G + B + A);
                return blendFactor;
            }

            half BlendContract(half blendContract_layer, half height_layer)
            {
                half blendContract = lerp(0 - blendContract_layer, 1 + blendContract_layer, height_layer );
                blendContract = saturate(blendContract);
                return blendContract;
            }


            half4 Blend(half high1 ,half high2,half high3,half high4 , half4 control) 
            {
                half4 blend ;

                blend.r = high1 * control.r;
                blend.g = high2 * control.g;
                blend.b = high3 * control.b;
                blend.a = high4 * control.a;

                half ma = max(blend.r, max(blend.g, max(blend.b, blend.a)));
                blend = max(blend - ma + _BlendContract_All , 0) * control;
                blend = blend/(blend.r + blend.g + blend.b + blend.a);
                return (blend);
            }






            half4 frag(Varyings i) : SV_Target
            {
                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                float3 viewDirWS = SafeNormalize(i.viewDirWS);
                
                half3x3 tbn = half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);
                // layer1
                half4 layer1_BaseMap = SAMPLE_TEXTURE2D(_Layer1_BaseMap, sampler_Layer1_BaseMap, i.layer1_UV);
                half4 layer1_NormalMap = SAMPLE_TEXTURE2D(_Layer1_NormalMap, sampler_Layer1_NormalMap, i.layer1_UV);
                float3 layer1_NormalWS = TerrainNormalWS(layer1_NormalMap, tbn);
                half layer1_Height = SAMPLE_TEXTURE2D(_Layer1_MaskMap, sampler_Layer1_MaskMap, i.layer1_UV);
                layer1_Height = BlendContract(_Layer1_BlendContract, layer1_Height);

                half3 layer1_albedo = layer1_BaseMap.rgb * _Layer1_BaseColor.rgb;
                half layer1_Smoothness = layer1_BaseMap.a * _Layer1_Smoothness;

                // layer2
                half4 layer2_BaseMap = SAMPLE_TEXTURE2D(_Layer2_BaseMap, sampler_Layer2_BaseMap, i.layer2_UV);
                half4 layer2_NormalMap = SAMPLE_TEXTURE2D(_Layer2_NormalMap, sampler_Layer2_NormalMap, i.layer2_UV);
                float3 layer2_NormalWS = TerrainNormalWS(layer2_NormalMap, tbn);
                half layer2_Height = SAMPLE_TEXTURE2D(_Layer2_MaskMap, sampler_Layer2_MaskMap, i.layer2_UV);
                layer2_Height = BlendContract(_Layer2_BlendContract, layer2_Height);

                half3 layer2_albedo = layer2_BaseMap.rgb * _Layer2_BaseColor.rgb;
                half layer2_Smoothness = layer2_BaseMap.a * _Layer2_Smoothness;

                // layer3
                half4 layer3_BaseMap = SAMPLE_TEXTURE2D(_Layer3_BaseMap, sampler_Layer3_BaseMap, i.layer3_UV);
                half4 layer3_NormalMap = SAMPLE_TEXTURE2D(_Layer3_NormalMap, sampler_Layer3_NormalMap, i.layer3_UV);
                float3 layer3_NormalWS = TerrainNormalWS(layer3_NormalMap, tbn);
                half layer3_Height = SAMPLE_TEXTURE2D(_Layer3_MaskMap, sampler_Layer3_MaskMap, i.layer3_UV);
                layer3_Height = BlendContract(_Layer3_BlendContract, layer3_Height);
                
                half3 layer3_albedo = layer3_BaseMap.rgb * _Layer3_BaseColor.rgb;
                half layer3_Smoothness = layer3_BaseMap.a * _Layer3_Smoothness;

                // layer4
                half4 layer4_BaseMap = SAMPLE_TEXTURE2D(_Layer4_BaseMap, sampler_Layer4_BaseMap, i.layer4_UV);
                half4 layer4_NormalMap = SAMPLE_TEXTURE2D(_Layer4_NormalMap, sampler_Layer4_NormalMap, i.layer4_UV);
                float3 layer4_NormalWS = TerrainNormalWS(layer4_NormalMap, tbn);
                half layer4_Height = SAMPLE_TEXTURE2D(_Layer4_MaskMap, sampler_Layer4_MaskMap, i.layer4_UV);
                layer4_Height = BlendContract(_Layer4_BlendContract, layer4_Height);

                
                half3 layer4_albedo = layer4_BaseMap.rgb * _Layer4_BaseColor.rgb;
                half layer4_Smoothness = layer4_BaseMap.a * _Layer4_Smoothness;

                
                half4 blendMap = SAMPLE_TEXTURE2D(_BlendMap, sampler_BlendMap, i.blend_UV);
                #if _ISVERTEX_ON
                    blendMap = i.color;
                #endif

                half4 blendFactor = BlendWeight(blendMap, layer1_Height, layer2_Height, layer3_Height, layer4_Height, _BlendContract_All);
                //  使用第二种混合方式
                // blendFactor = Blend(layer1_Height, layer2_Height, layer3_Height, layer4_Height ,blendMap);

                

                half3 albedo = layer1_albedo * blendFactor.x + layer2_albedo * blendFactor.y + layer3_albedo * blendFactor.z + layer4_albedo * blendFactor.w;
                
                half3 normalWS = layer1_NormalWS * blendFactor.x + layer2_NormalWS * blendFactor.y + layer3_NormalWS * blendFactor.z + layer4_NormalWS * blendFactor.w;
                half smoothness = layer1_Smoothness * blendFactor.x + layer2_Smoothness * blendFactor.y + layer3_Smoothness * blendFactor.z + layer4_Smoothness * blendFactor.z;
                half speculatIntensity = _Layer1_SpecularIntensity * blendFactor.x + _Layer2_SpecularIntensity * blendFactor.y + _Layer3_SpecularIntensity * blendFactor.z + _Layer4_SpecularIntensity * blendFactor.w;
                half3 specularColor = _Layer1_SpecularColor.rgb * blendFactor.x + _Layer2_SpecularColor.rgb * blendFactor.y + _Layer3_SpecularColor.rgb * blendFactor.z + _Layer4_SpecularColor.rgb * blendFactor.w;
                

                Light mainLight = GetMainLight(shadowCoord);
                float3 H = SafeNormalize(viewDirWS + mainLight.direction);
                half NoL = saturate(dot(normalWS, mainLight.direction)) * 0.5 + 0.5;
                half NoH = max(0.001, dot(normalWS, H));

                half mainShadow = lerp(1, mainLight.shadowAttenuation, _MainShadow);
                half3 shadowColor = lerp(_ShadowColor.rgb, 1, mainShadow);

                half lightAtten = mainLight.distanceAttenuation;
                half3 diffuse = NoL * mainLight.color * lightAtten * shadowColor * albedo;
                half3 specular = pow(NoH,smoothness) * speculatIntensity * smoothness * mainLight.color * albedo * specularColor * mainShadow;
                
                half3 c = diffuse + specular;
                return half4(c,1);
            }
            ENDHLSL
        }
    }
}

