
Shader "Jefford/Hair/Kajiya Kay Hair_A"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _DarkColor("_DarkColor",color) = (0,0,0,1)
        _BaseMap("BaseMap", 2D) = "white" {}

        _AnistyMap("_AnistyMap", 2D) = "black" {}
        _SpecularColorA("_SpecularColorA",color) = (1,1,1,1)
        _DistortA("_DistortA",Range(0,5)) = 1
        _PowA("_PowA",Range(0,3)) = 1
        _IntensityA("_IntensityA",Range(0,1)) = 1
        _ShiftA("_ShiftA",Range(-1,1)) = 1
        _Atten("_Atten",float) = 1

        [Space(20)]
        _SpecularColorB("_SpecularColorB",color) = (0,0,0,0)
        _DistortB("_DistortB",Range(0,5)) = 0
        _PowB("_PowB",Range(0,3))= 1
        _IntensityB("_IntensityB",Range(0,1)) = 1
        _ShiftB("_ShiftB",Range(-1,1)) = 1
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
            Name "Unlit"
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            half4 _DarkColor;
            
            half _DistortA;
            half _PowA;
            half _IntensityA;
            half _ShiftA;
            half _Atten;
            half4 _SpecularColorA;

            half _DistortB;
            half _PowB;
            half _IntensityB;
            half _ShiftB;
            half4 _SpecularColorB;

            CBUFFER_END
            TEXTURE2D (_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D (_AnistyMap);SAMPLER(sampler_AnistyMap);

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;

            };

            struct Varyings
            {
                float4 positionCS               : SV_POSITION;
                float2 uv                       : TEXCOORD0;
                float3 viewDir                  : TEXCOORD1;
                float3 positionWS               : TEXCOORD2;
                float3 normalWS                 : TEXCOORD3;  
                float3 tangentWS                : TEXCOORD4;   
                float3 bitangentWS              : TEXCOORD5;  
            };


            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = mul(UNITY_MATRIX_VP, mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0))); 
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);

                // ------------ 法线 ------------
                half3 normalWS;
                {
                    #ifdef UNITY_ASSUME_UNIFORM_SCALING
                        normalWS = SafeNormalize(mul((float3x3)UNITY_MATRIX_M, v.normalOS));
                    #else
                        normalWS = SafeNormalize(mul(v.normalOS,(float3x3)UNITY_MATRIX_M ));
                    #endif
                }
                o.normalWS = normalWS;
                o.tangentWS = SafeNormalize(mul((float3x3)UNITY_MATRIX_M, v.tangentOS.xyz));
                half sign = v.tangentOS.w * unity_WorldTransformParams.w;
                o.bitangentWS = cross(o.normalWS, o.tangentWS) * sign;
                o.positionWS = mul(UNITY_MATRIX_M, float4(v.positionOS.xyz,1));
                o.viewDir = _WorldSpaceCameraPos - o.positionWS;
                return o;
            }

            half3 KajiyaKaySpecular(half shift, half3 T, half3 H, half3 specColor, half specPow, half intensity)
            {
                T = normalize(T + H * shift);
                half ToH = dot(T,H);
                // specPow = exp(specPow * 3);
                half kajiya_Kay = sqrt(1 - ToH * ToH);
                kajiya_Kay = pow(kajiya_Kay,specPow) * intensity;
                half3 spec = specColor * kajiya_Kay;
                return spec;
            }
            
            half4 frag(Varyings i) : SV_Target
            {

                half3 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv).rgb * _BaseColor.rgb;
                half anisMap = SAMPLE_TEXTURE2D(_AnistyMap, sampler_AnistyMap, i.uv) - 0.5;

                half3 N = i.normalWS;
                half3 T = i.bitangentWS;
                
                Light mainLight = GetMainLight();
                float3 L = mainLight.direction;

                // 暗部为0.2 亮部为 1
                half lambert = dot(N,L) * 0.4 + 0.6;
                half3 NoLColor = lerp(_DarkColor.rgb, _BaseColor.rgb, lambert);
                half3 diffuse = NoLColor * baseMap;

                float3 V = normalize(i.viewDir);
                half3 H = SafeNormalize(L + V);

                // half atten = smoothstep(-1, 0, ToH);
                half atten = pow(saturate(dot(N,V)),_Atten);

                half shiftA = _ShiftA + anisMap * _DistortA;
                half shiftB = _ShiftB + anisMap * _DistortB;

                half powA = exp(_PowA * 3);
                half powB = exp(_PowB * 3);

                half3 specA = KajiyaKaySpecular(shiftA, T, H, _SpecularColorA, powA, _IntensityA) * atten;
                half3 specB = KajiyaKaySpecular(shiftB, T, H, _SpecularColorB, powB, _IntensityB) * atten;

                half3 c =  specA + specB + diffuse;
                return half4(c,1);
            }
            ENDHLSL
        }
    }
}

