
Shader "Jefford/OceanLand/Flag"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}

        _MaskOffset("_MaskOffset",Range(0,1)) = 0.5
        _MaskScale("_MaskScale",Range(0,1)) = 0.5
        _Speed("_Speed",Range(0,1)) = 0.5
        _AnimationRang("_AnimationRang",Range(0,1)) = 0.5
        _AnimationFrequencu("_AnimationFrequencu",Range(0,10)) = 1
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


            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;

            half _MaskOffset;
            half _MaskScale;
            half _Speed;

            half _AnimationRang;
            half _AnimationFrequencu;

            CBUFFER_END

            TEXTURE2D (_BaseMap);SAMPLER(sampler_BaseMap);


            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float fogCoord      : TEXCOORD1;
                float3 positionWS  : TEXCOORD2;
                half mask             : TEXCOORD3;
            };




            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0)).xyz;
                half3 centerPos =  mul(UNITY_MATRIX_M, float4(0,0,0,1.0)).xyz;
                o.mask = 1 - saturate((o.positionWS.y - centerPos.y - _MaskOffset) / _MaskScale);

                half speed = sin((_Time.y * _Speed + o.mask )* _AnimationFrequencu) * _AnimationRang;
                o.positionWS.z = o.positionWS.z + speed * o.mask ;
                o.positionWS.x= o.positionWS.x + speed * o.mask ;
                
                o.positionCS = mul(UNITY_MATRIX_VP,  float4(o.positionWS.xyz, 1.0)); 
                // o.positionCS = mul(UNITY_MATRIX_VP, mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1.0))); 
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                // half a = i.mask;
                // return a;
                half4 c;
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                c = baseMap * _BaseColor;
                c.rgb = MixFog(c.rgb, i.fogCoord);
                return c;
            }
            ENDHLSL
        }
    }
}

