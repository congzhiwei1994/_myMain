Shader "Hidden/KawaseBlur(模糊)"
{
	Properties
	{
		_MainTex("", 2D) = "white" {}
	}
	SubShader
	{	
		Tags 
		{ 
			"RenderPipeline" = "UniversalPipeline" 
		}
		
		Pass
		{
			Cull Off ZWrite Off ZTest Always

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"



			float4 _MainTex_TexelSize;
			uniform half _Offset;

			TEXTURE2D(_MainTex);          SAMPLER(sampler_MainTex);

			struct Attributes
			{

				float4 positionOS        : POSITION;
				float2 uv               : TEXCOORD0;

			};

			struct Varyings
			{
				float4 positionCS         : SV_POSITION;
				float2 uv                 : TEXCOORD0;
			};


			Varyings vert(Attributes v)
			{
				Varyings o = (Varyings)0;
				o.uv = v.uv;
				o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
				return o;
			}
			
			
			half4 frag(Varyings i): SV_Target
			{

				half2 uv1 = i.uv + float2(_Offset + 0.5, _Offset + 0.5) * _MainTex_TexelSize.xy;
				half2 uv2 = i.uv + float2(-_Offset - 0.5, _Offset + 0.5) * _MainTex_TexelSize.xy;
				half2 uv3 = i.uv + float2(-_Offset - 0.5, -_Offset - 0.5) * _MainTex_TexelSize.xy;
				half2 uv4 = i.uv + float2(_Offset + 0.5, -_Offset - 0.5) * _MainTex_TexelSize.xy;

				half4 o = 0;
				o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv1);
				o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv2);
				o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv3);
				o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv4);
				
				return o * 0.25;
			}
			ENDHLSL
		}
	}
}


