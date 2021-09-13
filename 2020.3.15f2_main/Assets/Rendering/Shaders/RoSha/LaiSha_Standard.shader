
Shader "URP/Character/LaiSha/Standard"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}
        [NoScaleOffset]_BumpMap("Normal Map", 2D) = "bump" {}
        _AOMap("_AOMap", 2D) = "white" {}
        _RampMap("_RampMap", 2D) = "white" {}

        [Header(Layer_A)]
        _Color_A("_Color_A",Color) = (1,1,1,1)
        _Color_A_Offset("_Color_A_Offset",Range(-1,1)) = 0
        _Color_A_Intensity("_Color_A_Intensity",Range(0,1)) = 1

        [Header(Layer_B)]
        _Color_B("_Color_B",Color) = (1,1,1,1)
        _Color_B_Softness("_Color_B_Softness",Range(0,1)) = 0.5
        _Color_B_Offset("_Color_B_Offset",Range(-1,1)) = 0
        _Color_B_Intensity("_Color_B_Intensity",Range(0,1)) = 0

        [Header(Specular)]
        [NoScaleOffset]_SpecualrMask("_SpecualrMask",2D) = "white" {}
        _SpecularColor("_SpecularColor",Color) = (1,1,1,1)
        _SpecularPow("_SpecularPow",float) = 1
        _SpecularIntensity("_SpecularIntensity",float) = 1

        [Header(Environment)]
        [NoScaleOffset]_EnvMap("_EnvMap",Cube) = "white"{}
        _EnvlIntensity("_EnvlIntensity",Range(0,1)) = 1
        _Roughness("_Roughness",Range(0,1)) = 1
        _FresnelColor("_FresnelColor",Color) = (1,1,1,1)
        _Fresnel_Max("_Fresnel_Max",Range(-1,1)) = 1
        _Fresnel_Min("_Fresnel_Min",Range(-1,1)) = 0

        [Header(OutLine)]
        _OutLineWidth("_OutLineWidth",Range(0,0.01)) = 0.01
        _OutLineColor("_OutLineColor",Color) = (1,1,1,1)
        
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
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;

            half4 _Color_A;
            half _Color_A_Offset;
            half _Color_A_Intensity;

            half4 _Color_B;
            half _Color_B_Softness;
            half _Color_B_Offset;
            half _Color_B_Intensity;

            half4 _SpecularColor;
            half _SpecularIntensity;
            half _SpecularPow;

            half4 _FresnelColor;
            half _EnvlIntensity;
            half _Fresnel_Min;
            half _Fresnel_Max;

            float4 _EnvMap_HDR;
            half _Roughness;

            CBUFFER_END

            TEXTURE2D (_AOMap);                          SAMPLER(sampler_AOMap);
            TEXTURE2D (_RampMap);                        SAMPLER(sampler_RampMap);
            TEXTURE2D (_SpecualrMask);                   SAMPLER(sampler_SpecualrMask);
            TEXTURECUBE (_EnvMap);                       SAMPLER(sampler_EnvMap);


            struct Attributes
            {
                float4 positionOS       : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 uv               : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS               : SV_POSITION;
                float2 uv                       : TEXCOORD0;
                float4 shadowCoord              : TEXCOORD1;
                float3 viewDir                  : TEXCOORD2;
                float3 normalWS                 : TEXCOORD3;    
                float3 tangentWS                : TEXCOORD4;   
                float3 bitangentWS              : TEXCOORD5;  
                float3 positionWS               : TEXCOORD6;  

            };


            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.uv = v.uv;

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
                o.normalWS = normalWS;
                // ------------ 切线 ------------
                half3 tangentWS = mul((float3x3)UNITY_MATRIX_M, v.tangentOS.xyz);
                o.tangentWS = SafeNormalize(tangentWS);

                half sign = v.tangentOS.w * unity_WorldTransformParams.w;
                o.bitangentWS = cross(normalWS,tangentWS) * sign;

                o.viewDir = _WorldSpaceCameraPos - o.positionWS;
                o.shadowCoord = TransformWorldToShadowCoord(o.positionWS);
                
                half3 vertexLight = VertexLighting(o.positionWS,normalWS);

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                half3 positionWS = i.positionWS;
                half4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                half3 viewDir = SafeNormalize(i.viewDir);
                half3x3 tbn = half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);
                
                
                half3 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv) * _BaseColor.rgb;
                half aoMap = SAMPLE_TEXTURE2D(_AOMap, sampler_AOMap, i.uv);
                
                half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap,i.uv);
                half3 normapTS= UnpackNormal(normalMap);
                half3 normalWS =  NormalizeNormalPerPixel(mul(normapTS, tbn));

                //  光照计算
                Light mainLight = GetMainLight(shadowCoord);
                half3 L = normalize(mainLight.direction);
                half3 N = normalWS;
                half3 H = SafeNormalize(viewDir + L);
                half3 R =  reflect(-viewDir, normalWS);
                half NoH = saturate(dot(N,H));
                half NoV = saturate(dot(N,viewDir));
                half NoL = dot(N,L) * 0.5 + 0.5;
                half diffuse = NoL * aoMap;



                half3 diffuseCol;
                {
                    half3 diffuseCol_A; // 第一层暗部颜色
                    {
                        half2 ramp_uv = half2(diffuse + _Color_A_Offset,0.5);
                        half ramp = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, ramp_uv).r;

                        diffuseCol_A = lerp(1,_Color_A,ramp * _Color_A_Intensity);
                    }

                    half3 diffuseCol_B;// 第二层暗部颜色
                    {
                        half2 ramp_uv = half2(saturate(diffuse + _Color_B_Offset),_Color_B_Softness);
                        half ramp = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, ramp_uv).g;

                        diffuseCol_B = lerp(1,_Color_B,ramp * _Color_B_Intensity);
                    }

                    diffuseCol = diffuseCol_A * diffuseCol_B * baseMap;
                }

                half4 speCMap = SAMPLE_TEXTURE2D(_SpecualrMask, sampler_SpecualrMask, i.uv);
                half specMask = speCMap.b;
                half smoothness = speCMap.a;
                
                half3 specColor;
                {
                    half specular = max(0.001,pow(NoH, _SpecularPow * smoothness )) * _SpecularIntensity * specMask;
                    specColor = (baseMap + _SpecularColor) * 0.5;
                    specColor = specColor * specular ;
                }

                half3 envColor;
                {
                    half mip = _Roughness * (1.7 - 0.7 * _Roughness) * 6;
                    half4 envMap = SAMPLE_TEXTURECUBE_LOD(_EnvMap, sampler_EnvMap, R, mip);
                    envColor = DecodeHDREnvironment(envMap, _EnvMap_HDR);

                    half fresnel = saturate(smoothstep(_Fresnel_Min, _Fresnel_Max, 1- NoV));
                    half3 fresnelColor = fresnel * _FresnelColor;

                    envColor *= fresnelColor * _EnvlIntensity * specMask;
                    
                }
                



                half3 c = diffuseCol + specColor + envColor;
                
                return half4(c,1);
            }
            ENDHLSL
        }

        Pass
        {
            Name "OutLine"
            Tags{"LightMode" = "SRPDefaultUnlit"}
            Cull Front
            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half _OutLineWidth;
            half4 _OutLineColor;
            
            CBUFFER_END

            TEXTURE2D(_DarkMap);          SAMPLER(sampler_DarkMap);
            TEXTURE2D(_ILMMap);           SAMPLER(sampler_ILMMap);
            TEXTURE2D(_DetailMap);        SAMPLER(sampler_DetailMap);

            struct Attributes
            {
                half3 normalOS           :NORMAL;
                half4 color              :COLOR;
                float4 positionOS        : POSITION;
                float2 uv               : TEXCOORD0; // 第一套uv

            };

            struct Varyings
            {
                float4 positionCS         : SV_POSITION;
                float2 uv                 : TEXCOORD0;
                half4 debug                    : TEXCOORD1;

            };


            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.uv = v.uv;
                half4 vertexColor = v.color;
                o.debug = vertexColor;

                half3 outLineVS; // 视空间下描边
                {
                    half3 positionVS = mul(UNITY_MATRIX_MV,float4(v.positionOS.xyz,1));
                    half3 normalVS = SafeNormalize(mul((float3x3)UNITY_MATRIX_MV, v.normalOS.xyz));
                    outLineVS = positionVS + normalVS * _OutLineWidth * vertexColor.a;
                    
                }

                o.positionCS = mul(UNITY_MATRIX_P,float4(outLineVS,1));


                // half3 outLineOS; // 本地空间下描边
                // {
                    //     outLineOS = v.positionOS.xyz +  v.normalOS * _OutLineWidth;
                // }

                // o.positionCS = mul(UNITY_MATRIX_VP, mul(UNITY_MATRIX_M, float4(outLineOS, 1.0)));        

                // v.positionOS.xyz = v.positionOS.xyz + normalize(v.normalOS) * _OutLineWidth;
                // v.positionOS.xyz *= v.color.a;
                // o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                // o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                // o.viewDirWS = GetCameraPositionWS() - o.positionWS;
                

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {

                // return i.debug.a;
                half3 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                half maxComponent = max(max(baseMap.r,baseMap.g), baseMap.b) - 0.004;
                half3 saturateColor = step(maxComponent.rrr, baseMap) * baseMap;
                saturateColor = lerp(baseMap, saturateColor, 0.6);

                half3 outLineColor = 0.8 * saturateColor * baseMap * _OutLineColor.rgb;
                return half4(outLineColor,1);
            }
            ENDHLSL
        }

    }
}

