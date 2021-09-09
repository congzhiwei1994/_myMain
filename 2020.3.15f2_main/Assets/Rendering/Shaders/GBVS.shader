
Shader "Jefford/GBVS/Body(二次元碧蓝幻想)"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}
        _DarkMap("_DarkMap", 2D) = "white" {}
        _ILMMap("_ILMMap", 2D) = "white" {}
        _DetailMap("_DetailMap", 2D) = "white" {}

        _ToonThesHold("_ToonThesHold",Range(0,1)) = 0.5 // 控制暗部和亮部的范围
        _ToonHardness("_ToonHardness",Range(0,50)) = 10 // 控制边界的软硬程度,越大边界越硬朗

        [Header(Specular)]
        _SpecularPow("_SpecularPow",Range(0,1)) = 0.1
        _SpecScale("_SpecScale",float) = 1
        _SpecularColor("_SpecularColor",Color) = (1,1,1,1)

        [Header(OutLine)]
        _OutLineWidth("_OutLineWidth",Range(0,0.01)) = 0.01
        _OutLineColor("_OutLineColor",Color) = (1,1,1,1)

        [Header(Rim)]
        _RimColor("_RimColor",Color) = (1,1,1,1)
        _RimLightDir("_RimLightDir",vector) = (1,0,-1,0) 
        _RimIntensity("_RimIntensity",Range(0,1)) = 1

    }

    SubShader
    {
        Tags 
        { 
            "Queue"="Geometry"
            "RenderType" = "Opaque" 
            "IgnoreProjector" = "True" 
            "RenderPipeline" = "UniversalPipeline" 
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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half _ToonThesHold;
            half _ToonHardness;
            half _SpecularPow;
            half _SpecScale;
            half4 _SpecularColor;

            half _RimIntensity;
            half4 _RimLightDir;
            half4 _RimColor;
            CBUFFER_END

            TEXTURE2D(_DarkMap);          SAMPLER(sampler_DarkMap);
            TEXTURE2D(_ILMMap);           SAMPLER(sampler_ILMMap);
            TEXTURE2D(_DetailMap);        SAMPLER(sampler_DetailMap);

            struct Attributes
            {
                half3 normalOS           :NORMAL;
                half4 color              :COLOR;
                float4 positionOS        : POSITION;
                float2 uv1               : TEXCOORD0; // 第一套uv
                float2 uv2               : TEXCOORD1; // 第二套uv
            };

            struct Varyings
            {
                float4 positionCS         : SV_POSITION;
                float4 uv                 : TEXCOORD0;
                half3 positionWS          : TEXCOORD1;
                half3 viewDirWS           : TEXCOORD2;
                half3 normalWS            : TEXCOORD3;
                half4 color               : TEXCOORD4;
            };


            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.uv = half4(v.uv1,v.uv2);;
                o.color = v.color;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.viewDirWS = GetCameraPositionWS() - o.positionWS;
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {

                half4 vertexColor = i.color;
                half ao = vertexColor.r;
                half2 uv1 = i.uv.xy;
                half2 uv2 = i.uv.zw;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv1);
                half mask = baseMap.a; // 材质区分
                half3 baseColor = baseMap.rgb * _BaseColor.rgb;
                
                half detailMap = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, uv2).r; // 细节描边
                
                
                half4 darkMap = SAMPLE_TEXTURE2D(_DarkMap, sampler_DarkMap, uv1); // 暗部贴图
                half rimIntensity = darkMap.a;  // 不同物体边缘光的强度控制
                half3 darkColor = darkMap.rgb; // 暗部纹理

                // ILM贴图
                half4 ilmMap = SAMPLE_TEXTURE2D(_ILMMap, sampler_ILMMap, uv1);
                half specIntensity = ilmMap.r;  // 高光的强度
                half specSize = 1 - ilmMap.b;   // 高光的面积
                half diffuseOffset = ilmMap.g * 2 - 1;  //进行光照的偏移,映射到（-1,1）
                half innerLine = ilmMap.a;     // 内描线
                innerLine *= detailMap;  // 内描线融合

                // -----------------------------------------------------------------------------------------------------
                // 光照计算
                // -----------------------------------------------------------------------------------------------------
                Light mainLight = GetMainLight();
                half3 lightColor = mainLight.color;
                half3 posWS = i.positionWS;
                half3 N = SafeNormalize(i.normalWS);
                half3 V = SafeNormalize(i.viewDirWS);
                half3 L = mainLight.direction;
                half3 H = SafeNormalize(V + L);


                half NoL = dot(N,L);
                NoL = NoL * 0.5 + 0.5;
                
                half NoV = dot(N,V);
                NoV = NoV * 0.5 + 0.5;

                half NoH = dot(N,H);
                NoH = NoH * 0.5 + 0.5;


                // -----------------------------------------------------------------------------------------------------

                half diffuse;
                {
                    diffuse = NoL * ao + diffuseOffset;
                    diffuse = (diffuse - _ToonThesHold) * _ToonHardness; // 进行颜色分级
                }

                half3 diffuseColor;
                {
                    
                    diffuse = saturate(diffuse);
                    diffuse *= innerLine; 

                    darkColor = lerp(darkColor * 0.35, darkColor,innerLine);
                    diffuseColor = lerp(darkColor,baseColor,diffuse);
                }


                half3 specColor;
                {
                    half specular; 
                    {
                        // NoH = NoL * 0.9 + NoV * 0.1;
                        specular = NoH * ao;
                        specular += diffuseOffset;
                        
                        specular = specular - specSize * _SpecularPow;
                        specular = specular * _SpecScale;
                        specular = saturate(specular) * specIntensity;
                    }
                    return specular;
                    
                    specColor = (_SpecularColor.rgb + baseColor) * 0.5;
                    specColor = specular * specColor;
                    specColor *= innerLine;
                    
                }
                
                
                
                // 风格化补光
                half3 rimColor;
                {

                    half3 rimLightDir = _RimLightDir.xyz;
                    rimLightDir = mul((float3x3)UNITY_MATRIX_I_V,rimLightDir); // 补光方向根据视方向进行偏移
                    rimLightDir = normalize(rimLightDir);

                    half NoR = dot(N,rimLightDir);
                    NoR = (NoR - _ToonThesHold) * 20; // 补光阶层化
                    NoR = saturate(NoR);
                    
                    rimColor = NoR * (baseColor + _RimColor) * 0.5; //应用颜色
                    rimColor *= _RimIntensity;
                    rimColor *= mask; // 遮罩 去掉皮肤和头发的补光
                    rimColor *= diffuse; // 只在亮部生成
                    rimColor *= rimIntensity;
                    
                }
                
                half3 c;
                {
                    c = diffuseColor + specColor + rimColor;
                    // c *= innerLine;
                    c = sqrt(max(exp2(log2(max(c,0)) * 2.2), 0.0)); //GGX 中的 ToneMaping处理
                    
                }
                
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

