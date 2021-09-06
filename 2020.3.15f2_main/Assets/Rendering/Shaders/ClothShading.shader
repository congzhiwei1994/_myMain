
Shader "Jefford/Cloth Shading"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}
        _ClothCubeMap("衣服环境反射CubeMap",Cube) = "white" {}
        _ClothCubeIntensity("衣服环境反射强度",Range(0,1)) = 0.5
        [NoScaleOffset]_MaskMap("Thickness厚度:(G) AO:(B) Alpha:(A)", 2D) = "white" {}
        _OcclusionStrength("AO强度",Range(0,1)) = 1
        _SpecColor("高光颜色",color) = (1,1,1,1)
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


            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            half _OcclusionStrength;
            half4 _SpecColor;
            half _Smoothness;
            half _BumpScale;
            half4 _SheenColor;
            half _GGXAnisotropy;

            half4 _TranslucencyColor;
            half _TranslucencyPower;
            half _ThicknessStrength;
            half _ShadowStrength;
            half _Distortion;

            half4 _ClothCubeMap_HDR;
            half _ClothCubeIntensity;
            CBUFFER_END

            TEXTURE2D (_MaskMap);           SAMPLER(sampler_MaskMap);
            TEXTURECUBE(_ClothCubeMap);       SAMPLER(sampler_ClothCubeMap);



            // Ref: https://knarkowicz.wordpress.com/2018/01/04/cloth-shading/
            real D_CharlieNoPI_Lux(real NdotH, real roughness)
            {
                float invR = rcp(roughness);
                float cos2h = NdotH * NdotH;
                float sin2h = 1.0 - cos2h;
                // Note: We have sin^2 so multiply by 0.5 to cancel it
                return (2.0 + invR) * PositivePow(sin2h, invR * 0.5) / 2.0;
            }

            real D_Charlie_Lux(real NdotH, real roughness)
            {
                return INV_PI * D_CharlieNoPI_Lux(NdotH, roughness);
            }

            // We use V_Ashikhmin instead of V_Charlie in practice for game due to the cost of V_Charlie
            real V_Ashikhmin_Lux(real NdotL, real NdotV)
            {
                // Use soft visibility term introduce in: Crafting a Next-Gen Material Pipeline for The Order : 1886
                return 1.0 / (4.0 * (NdotL + NdotV - NdotL * NdotV));
            }

            // A diffuse term use with fabric done by tech artist - empirical
            real FabricLambertNoPI_Lux(real roughness)
            {
                return lerp(1.0, 0.5, roughness);
            }

            real FabricLambert_Lux(real roughness)
            {
                return INV_PI * FabricLambertNoPI_Lux(roughness);
            }

            struct AdditionalData 
            {
                half3   tangentWS;
                half3   bitangentWS;
                float   partLambdaV;
                half    roughnessT;
                half    roughnessB;
                half3   anisoReflectionNormal;
                half3   sheenColor;
            };


            half3 DirectBDRF_LuxCloth(BRDFData brdfData, Light light, AdditionalData addData, half3 normalWS, half3 viewDirectionWS)
            {

                half3 lightDirectionWS = light.direction;
                half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;
                half3 lightColor = light.color;
                half NdotL = saturate(dot(normalWS, lightDirectionWS));
                half3 radiance = lightColor * (lightAttenuation * NdotL);


                float3 halfDir = SafeNormalize(lightDirectionWS + viewDirectionWS);

                float NoH = saturate(dot(normalWS, halfDir));
                half LoH = saturate(dot(lightDirectionWS, halfDir));
                half NdotV = saturate(dot(normalWS, viewDirectionWS ));

                #if defined(_COTTONWOOL_ON)

                    //  NOTE: We use the noPI version here!!!!!!
                    float D = D_CharlieNoPI_Lux(NoH, brdfData.roughness);
                    //  Unity: V_Charlie is expensive, use approx with V_Ashikhmin instead
                    //  Unity: float Vis = V_Charlie(NdotL, NdotV, bsdfData.roughness);
                    float Vis = V_Ashikhmin_Lux(NdotL, NdotV);

                    //  Unity: Fabrics are dieletric but we simulate forward scattering effect with colored specular (fuzz tint term)
                    //  Unity: We don't use Fresnel term for CharlieD
                    //  SheenColor seemed way too dark (compared to HDRP) – so i multiply it with PI which looked ok and somehow matched HDRP
                    //  Therefore we use the noPI charlie version. As PI is a constant factor the artists can tweak the look by adjusting the sheen color.
                    float3 F = addData.sheenColor; // * PI;
                    half3 specularLighting = F * Vis * D;
                    
                    //  Unity: Note: diffuseLighting originally is multiply by color in PostEvaluateBSDF
                    //  So we do it here :)
                    //  Using saturate to get rid of artifacts around the borders.
                    half3 specularTerm = saturate(specularLighting) + brdfData.diffuse * FabricLambert_Lux(brdfData.roughness);
                    return specularTerm * radiance;
                    
                #else
                    float TdotH = dot(addData.tangentWS, halfDir);
                    float TdotL = dot(addData.tangentWS, lightDirectionWS);
                    float BdotH = dot(addData.bitangentWS, halfDir);
                    float BdotL = dot(addData.bitangentWS, lightDirectionWS);

                    float3 F = F_Schlick(brdfData.specular, LoH);
                    //float TdotV = dot(addData.tangentWS, viewDirectionWS);
                    //float BdotV = dot(addData.bitangentWS, viewDirectionWS);
                    float DV = DV_SmithJointGGXAniso( TdotH, BdotH, NoH, NdotV, TdotL, BdotL, NdotL,addData.roughnessT, addData.roughnessB, addData.partLambdaV);
                    // Check NdotL gets factores in outside as well.. correct?
                    half3 specularLighting = F * DV;
                    half3 specularTerm = specularLighting + brdfData.diffuse;
                    return specularTerm * radiance;
                #endif

            }

            half3 TranslucencyColor(Light light, half thickness, half3 normalWS, half3 viewDirWS)
            {
                // 主灯阴影衰减
                half mainLightShadowAtten = lerp(1, light.shadowAttenuation, _ShadowStrength);
                half atten = light.distanceAttenuation * mainLightShadowAtten;
                half NoL = saturate(dot(normalWS, light.direction));
                // 进行法线方向扭曲
                half transLightDir = light.direction + normalWS * _Distortion;
                half LoV = saturate(dot(transLightDir, -viewDirWS));
                // 压暗暗部，逐渐缩小透射区域
                LoV = exp2(LoV * _TranslucencyPower - _TranslucencyPower);
                LoV = LoV * (1 - NoL);
                half3 translucencyColor = LoV * light.color * atten * thickness * 4 * _TranslucencyColor.rgb;
                return translucencyColor;
            }
            

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
                float3 viewDirWS = SafeNormalize(i.viewDirWS);

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv.xy);
                half4 maskMap = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv.zw);

                float3x3 tbn = float3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);
                half4 normal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv);
                half3 normalTS = UnpackNormalScale(normal, _BumpScale);
                normalTS.z *= facing;

                #if defined(_COTTONWOOL_ON)
                    float3 normalWS = i.normalWS * facing;
                #else
                    float3 normalWS = NormalizeNormalPerPixel(mul(normalTS, tbn));
                #endif
                

                half3 sh = SampleSHPixel(i.vertexSH, normalWS);

                #if defined(_COTTONWOOL_ON)
                    half3 tangentWS = half3(0, 0, 0);
                    half3 bitangentWS = half3(0, 0, 0);
                #else
                    half3 tangentWS = i.tangentWS;
                    half3 bitangentWS = i.bitangentWS;
                #endif
                
                

                half occlusion = lerp(1 ,maskMap.b, _OcclusionStrength);
                half3 albedo = baseMap.rgb * _BaseColor.rgb;
                half smoothness = baseMap.a * _Smoothness;
                #if defined(_COTTONWOOL_ON)
                    smoothness = lerp(0.0h, 0.6h, smoothness);
                #endif
                half metallic = 0;
                half3 specular = _SpecColor;
                half alpha = maskMap.b;

                // BRDF反射率计算
                BRDFData brdfData;
                ZERO_INITIALIZE(BRDFData, brdfData);
                half reflectivity = ReflectivitySpecular(specular);
                half oneMinusReflectivity = 1.0 - reflectivity;
                half3 brdfDiffuse = albedo * (half3(1.0h, 1.0h, 1.0h) - specular);
                half3 brdfSpecular = specular;

                InitializeBRDFDataDirect(brdfDiffuse, brdfSpecular, reflectivity, oneMinusReflectivity, smoothness, alpha, brdfData);
                // 不需要计算反射率
                brdfData.diffuse = albedo;
                brdfData.specular = specular;

                AdditionalData addData;
                ZERO_INITIALIZE(AdditionalData, addData);
                addData.bitangentWS = normalize(-cross(normalWS, tangentWS));
                addData.tangentWS = cross(normalWS, addData.bitangentWS);
                addData.roughnessT = brdfData.roughness * (1 + _GGXAnisotropy);
                addData.roughnessB = brdfData.roughness * (1 - _GGXAnisotropy);

                #if defined(_COTTONWOOL_ON)
                    //  partLambdaV should be 0.0f in case of cotton wool
                    addData.partLambdaV = 0.0h;
                    addData.anisoReflectionNormal = normalWS;
                    half NoV = dot(normalWS, viewDirWS);
                #else
                    half ToV = dot(tangentWS, viewDirWS);
                    half BoV = dot(bitangentWS, viewDirWS);
                    half NoV = dot(normalWS, viewDirWS);
                    addData.partLambdaV = GetSmithJointGGXAnisoPartLambdaV(ToV, BoV, NoV, addData.roughnessT, addData.roughnessB);
                    //  Set reflection normal and roughness – derived from GetGGXAnisotropicModifiedNormalAndRoughness
                    half3 grainDirWS = (_GGXAnisotropy >= 0.0) ? bitangentWS : tangentWS;
                    half stretch = abs(_GGXAnisotropy) * saturate(1.5h * sqrt(brdfData.perceptualRoughness));
                    addData.anisoReflectionNormal = GetAnisotropicModifiedNormal(grainDirWS, normalWS, viewDirWS, stretch);
                    half iblPerceptualRoughness = brdfData.perceptualRoughness * saturate(1.2 - abs(_GGXAnisotropy));
                    //  Overwrite perceptual roughness for ambient specular reflections
                    brdfData.perceptualRoughness = iblPerceptualRoughness;
                #endif
                addData.sheenColor = _SheenColor.rgb;

                Light mainLight = GetMainLight(shadowCoord);
                half NoL = max(0.001, dot(normalWS, mainLight.direction));

                half3 indirect;
                {
                    half3 indirectDiffuse = sh * occlusion * brdfData.diffuse;
                    
                    half3 indirectSpecular;
                    {
                        half3 reflectVector = reflect(-viewDirWS, addData.anisoReflectionNormal);
                        half NdotV = saturate(dot(addData.anisoReflectionNormal, viewDirWS));
                        half fresnelTerm = Pow4(1.0 - NdotV);
                        
                        half mip = PerceptualRoughnessToMipmapLevel(brdfData.perceptualRoughness);
                        half4 envCubeMap = SAMPLE_TEXTURECUBE_LOD(_ClothCubeMap, sampler_ClothCubeMap, reflectVector, mip);
                        
                        half3 ibl = DecodeHDREnvironment(envCubeMap, _ClothCubeMap_HDR) * occlusion;
                        
                        float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
                        surfaceReduction = surfaceReduction * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);
                        indirectSpecular = ibl * surfaceReduction;
                    }

                    indirect = indirectDiffuse + indirectSpecular * _ClothCubeIntensity * NoL;
                }

                
                half3 direct = DirectBDRF_LuxCloth( brdfData, mainLight, addData, normalWS, viewDirWS);
                half3 c = indirect + direct;

                #if defined(_SCATTERING_ON)
                    // 厚度
                    half thickness = maskMap.g * _ThicknessStrength;
                    half3 translucencyColor = TranslucencyColor(mainLight, thickness, normalWS, viewDirWS);
                    c += translucencyColor;
                #endif
                

                #ifdef _ADDITIONAL_LIGHTS
                    int pixelLightCount = GetAdditionalLightsCount();
                    for (int j = 0; j < pixelLightCount; ++j)
                    {
                        Light light = GetAdditionalLight(j, i.positionWS);
                        c += DirectBDRF_LuxCloth( brdfData, light, addData, normalWS, viewDirWS);

                        #if defined(_SCATTERING)
                            c + =TranslucencyColor(light, thickness, normalWS, viewDirWS);
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

