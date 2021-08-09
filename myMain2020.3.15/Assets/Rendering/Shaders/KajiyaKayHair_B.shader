Shader "Jefford/Hair/Kajiya Kay Hair_B"
{
    Properties
    {
        [MainColor]_BaseColor("Base Color",color) = (1,1,1,1)
        [MainTexture]_BaseMap("BaseMap", 2D) = "white" {}
        _BaseMapIntensity("_BaseMapIntensity",float) = 1
        _HairNoise("_HairNoise", 2D) = "white" {}
        
        _HairColorA("_HairColorA",Color) = (1,1,1,1)
        _HairIntensityA("_HairIntensityA",Range(0,1)) = 1
        _NoiseIntensityA("_NoiseIntensityA",Range(0,3)) = 1
        _ShininessA("_ShininessA",Range(0,1)) = 0.3
        _HairShiftA("_HairShiftA",Range(-1,1)) = -0.5

        [Space(20)]
        _HairColorB("_HairColorB",Color) = (0,0,0,0)
        _HairIntensityB("_HairIntensityB",Range(0,1)) = 0
        _NoiseIntensityB("_NoiseIntensityB",Range(0,3)) = 0
        _ShininessB("_ShininessB",Range(0,1)) = 0
        _HairShiftB("_HairShiftB",Range(-1,1)) = 0

    }

    SubShader
    {
        Tags { "Queue"="Geometry" "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Name "Unlit"
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float3 normalOS         : NORMAL;
                float4 tangentOS        :TANGENT;
                float2 uv               : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float fogCoord      : TEXCOORD1;
                half3 normalWS        : TEXCOORD2;
                half3 tangentWS       : TEXCOORD3;
                half3 bitangentWS     : TEXCOORD4;               
                half3 viewDirWS       : TEXCOORD5;
            };

            CBUFFER_START(UnityPerMaterial)
            half _BaseMapIntensity;
            half4 _BaseColor;     
            float4 _BaseMap_ST;
            float4 _HairNoise_ST;

            float _NoiseIntensityA;
            float _ShininessA;
            float4 _HairColorA;
            float _HairShiftA;
            float _HairIntensityA;

            float _NoiseIntensityB;
            float _HairShiftB;
            float _ShininessB;
            float4 _HairColorB;
            float _HairIntensityB;


            CBUFFER_END
            TEXTURE2D (_HairNoise);         SAMPLER(sampler_HairNoise);

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;
                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);

                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                half sign = v.tangentOS.w * GetOddNegativeScale();
                o.bitangentWS = cross(o.normalWS, o.tangentWS) * sign;

                o.viewDirWS = SafeNormalize(GetCameraPositionWS() - positionWS);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            half3 KayjiyaKaySpec(Light light, float3 T, float3 B, float3 V, float3 N, half shift, half shininess)
            {

                half lightAtten = light.shadowAttenuation *  light.distanceAttenuation;
                half3 lightColor = light.color * lightAtten;
                
                half3 shiftTangent = normalize(B + N * shift);
                half3 L = light.direction;
                float3 H = SafeNormalize(L + V);
                half NoV = dot(N,V);
                half BoH = dot(shiftTangent,H) / shininess;
                half ToH = dot(T,H);
                half NoH = dot(N,H);
                half NoL = dot(N,L);
                half halflambert = NoL * 0.5 + 0.5; 
                
                half noiseAtten = saturate(sqrt(max(0,halflambert / NoV)));
                half specTerm = exp(-(ToH * ToH + BoH * BoH) / (1 + NoH));
                half3 spcColor = specTerm * noiseAtten * lightColor;
                return spcColor;
            }

            
            half4 frag(Varyings i) : SV_Target
            {

                half2 baseMap_uv =  i.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseMap_uv) * _BaseColor * _BaseMapIntensity;

                half2 hairNoise_uv =  i.uv * _HairNoise_ST.xy + _HairNoise_ST.zw;
                half hairNoise= SAMPLE_TEXTURE2D(_HairNoise, sampler_HairNoise, hairNoise_uv).r;
                hairNoise  = (hairNoise * 2 - 1);
                
                Light light = GetMainLight();
                float3 B = i.bitangentWS;
                float3 T = i.tangentWS;
                float3 N = i.normalWS;
                float3 V = i.viewDirWS;

                half shiftA = _HairShiftA + hairNoise * _HairIntensityA;
                half shiftB = _HairShiftB + hairNoise * _HairIntensityB;

                half3 specA = KayjiyaKaySpec(light, T,  B, V, N, shiftA, _ShininessA);
                specA = specA * _HairColorA * _HairIntensityA;
                half3 specB = KayjiyaKaySpec(light,T,B,V, N, shiftB, _ShininessB);
                specB = specB * _HairColorB * _HairIntensityB;
                half3 specular = specA + specB;

                return half4(specular,1);
            }
            ENDHLSL
        }
    }
}