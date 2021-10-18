
Shader "Jefford/LaiSha/Eye"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}
        [NoScaleOffset]_BumpMap("Normal Map", 2D) = "bump" {}
        [NoScaleOffset]_DecalMask("_DecalMask",2D) = "white" {}

        [Header(Environment)]
        [NoScaleOffset]_EnvMap("_EnvMap",Cube) = "white"{}
        _Rotate("_Rotate",Range(0,360)) = 0
        _EnvlIntensity("_EnvlIntensity",Range(0,2)) = 1
        _Roughness("_Roughness",Range(0,1)) = 1

        _Parallax("_Parallax(视差偏移)",float) = -0.1
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

            half _EnvlIntensity;
            half _Rotate;

            float4 _EnvMap_HDR;
            half _Roughness;
            half _Parallax;
            CBUFFER_END

            TEXTURE2D (_DecalMask);                   SAMPLER(sampler_DecalMask);
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


            float3 RotateAroundYInDegrees (float3 vertex, float degrees)
            {
                float alpha = degrees * PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float3(mul(m, vertex.xz), vertex.y).xzy;
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
                
                half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap,i.uv);
                half3 normapTS= UnpackNormal(normalMap);
                half3 normalWS =  NormalizeNormalPerPixel(mul(normapTS, tbn));
                
                float2 parallax_offset; // 视差偏移
                {
                    half mask; // 时差偏移遮罩
                    {
                        mask = distance(i.uv,float2(0.5,0.5)) / 0.2;
                        mask = smoothstep(1, 0.5, mask);  // smoothstep 第一个参数比第二个参数大，相当于做一个反向的处理
                        mask = saturate(mask);
                    }

                    
                    float3 tanViewDir = normalize(mul(tbn,viewDir )); // 切线空间的视方向
                    parallax_offset = tanViewDir.xy / (tanViewDir.z + 0.42f); // 偏移值
                    parallax_offset *= _Parallax;
                    parallax_offset *= mask;
                }


                half3 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv + parallax_offset) * _BaseColor.rgb;
                half3 decalMap = SAMPLE_TEXTURE2D(_DecalMask, sampler_DecalMask, i.uv).rgb;


                // 眼睛分为两部分，一部分是向外凸的一部分是向内凹的，向外凸出的部分用于做反射，向内凹的部分用于做漫反射
                half3 normalWS_Iris;  // 反向，用于做凹陷的部分来计算漫反射
                {
                    normapTS.xy = -normapTS.xy;
                    normalWS_Iris =  NormalizeNormalPerPixel(mul(normapTS, tbn));
                }


                //  光照计算
                Light mainLight = GetMainLight(shadowCoord);
                half3 L = normalize(mainLight.direction);
                half3 N = normalWS;
                half3 H = SafeNormalize(viewDir + L);
                
                // NoL需要saturate，否则背光的时候眼睛会变黑,因为背光的时候值域是(-1,1),
                half NoL = saturate(dot(normalWS_Iris,L)); 
                NoL = NoL * 0.5 + 0.5; 

                half3 R = reflect(-viewDir, normalWS);
                R = RotateAroundYInDegrees(R,_Rotate); // 进行旋转

                half3 diffuseCol = baseMap * NoL;
                

                half3 envColor;
                {
                    half mip = _Roughness * (1.7 - 0.7 * _Roughness) * 6;
                    half4 envMap = SAMPLE_TEXTURECUBE_LOD(_EnvMap, sampler_EnvMap, R, mip);
                    envColor = DecodeHDREnvironment(envMap, _EnvMap_HDR) ;
                    half3 envlumin = dot(envColor,float3(0.299f, 0.587f, 0.114));
                    envColor *= envlumin;
                    envColor *= _EnvlIntensity ;
                    
                }

                half3 c = diffuseCol + envColor * baseMap + decalMap;
                // c = ACESFilm(c);
                return half4(c,1);
            }
            ENDHLSL
        }


    }
}

