// 只有水的波浪顶点动画以及水波浪的颜色
Shader "Jefford/Water Wave"
{
	Properties
	{
		
		_WaveASpeedXYSteepnesswavelength("WaveA(SpeedXY,Steepness,wavelength)", Vector) = (1,1,2,50)
		_WaveB("WaveB", Vector) = (1,1,2,50)
		_WaveC("WaveC", Vector) = (1,1,2,50)
		_WaveColor("WaveColor", Color) = (0,0,0,0)


	}

	SubShader
	{
		Tags { "RenderPipeline"="UniversalPipeline"  "RenderType"="Opaque"  "Queue"="Geometry" }
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			

			HLSLPROGRAM


			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"



			CBUFFER_START(UnityPerMaterial)
			float4 _WaveASpeedXYSteepnesswavelength;
			float4 _WaveB;
			float4 _WaveC;
			float4 _WaveColor;

			CBUFFER_END
			
			

			struct appadata
			{
				float4 positionOS : POSITION;
				float3 ase_normal : NORMAL;
				

			};

			struct v2f
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
			};



			float3 GerstnerWave_A( float3 position, inout float3 tangent, inout float3 binormal, float4 wave )
			{
				float steepness = wave.z * 0.01;
				float wavelength = wave.w;
				float k = 2 * 3.1415926 / wavelength;
				float c = sqrt(9.8 / k);
				float2 d = normalize(wave.xy);
				float f = k * (dot(d, position.xz) - c * _Time.y);
				float a = steepness / k;
				
				tangent += float3(
				-d.x * d.x * (steepness * sin(f)),
				d.x * (steepness * cos(f)),
				-d.x * d.y * (steepness * sin(f))
				);
				binormal += float3(
				-d.x * d.y * (steepness * sin(f)),
				d.y * (steepness * cos(f)),
				-d.y * d.y * (steepness * sin(f))
				);
				return float3(
				d.x * (a * cos(f)),
				a * sin(f),
				d.y * (a * cos(f))
				);
			}
			
			float3 GerstnerWave_B( float3 position, inout float3 tangent, inout float3 binormal, float4 wave )
			{
				float steepness = wave.z * 0.01;
				float wavelength = wave.w;
				float k = 2 *3.1415926 / wavelength;
				float c = sqrt(9.8 / k);
				float2 d = normalize(wave.xy);
				float f = k * (dot(d, position.xz) - c * _Time.y);
				float a = steepness / k;
				
				tangent += float3(
				-d.x * d.x * (steepness * sin(f)),
				d.x * (steepness * cos(f)),
				-d.x * d.y * (steepness * sin(f))
				);
				binormal += float3(
				-d.x * d.y * (steepness * sin(f)),
				d.y * (steepness * cos(f)),
				-d.y * d.y * (steepness * sin(f))
				);
				return float3(
				d.x * (a * cos(f)),
				a * sin(f),
				d.y * (a * cos(f))
				);
			}
			
			float3 GerstnerWave_C( float3 position, inout float3 tangent, inout float3 binormal, float4 wave )
			{
				float steepness = wave.z * 0.01;
				float wavelength = wave.w;
				float k = 2 * 3.1415926 / wavelength;
				float c = sqrt(9.8 / k);
				float2 d = normalize(wave.xy);
				float f = k * (dot(d, position.xz) - c * _Time.y);
				float a = steepness / k;
				
				tangent += float3(
				-d.x * d.x * (steepness * sin(f)),
				d.x * (steepness * cos(f)),
				-d.x * d.y * (steepness * sin(f))
				);
				binormal += float3(
				-d.x * d.y * (steepness * sin(f)),
				d.y * (steepness * cos(f)),
				-d.y * d.y * (steepness * sin(f))
				);
				return float3(
				d.x * (a * cos(f)),
				a * sin(f),
				d.y * (a * cos(f))
				);
			}
			
			
			v2f vert  ( appadata v  )
			{
				v2f o = (v2f)0;
				float3 tangent = float3( 1,0,0 );
				float3 binormal = float3( 0,0,1 );

				float3 positionWS = mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1)).xyz;
				float3 gerstnerWave_A = GerstnerWave_A( positionWS , tangent , binormal , _WaveASpeedXYSteepnesswavelength );
				float3 gerstnerWave_B = GerstnerWave_B( positionWS , tangent , binormal , _WaveB );
				float3 gerstnerWave_C = GerstnerWave_C( positionWS , tangent , binormal , _WaveC );

				positionWS = ( positionWS + gerstnerWave_A + gerstnerWave_B + gerstnerWave_C );
				float3 positionOS = mul(UNITY_MATRIX_I_M, float4( positionWS,1)).xyz;
				
				o.positionWS = mul(UNITY_MATRIX_M,float4(positionOS.xyz,1) );
				o.positionCS = TransformWorldToHClip( o.positionWS );

				// float3 normalWS = normalize( cross( binormal , tangent ) );
				// float3 normalOS = mul(UNITY_MATRIX_I_M, float4( normalWS, 0 ) ).xyz;
				
				return o;
			}

			half4 frag ( v2f i  ) : SV_Target
			{

				float3 positionWS = i.positionWS;

				float3 tangent = float3( 1,0,0 );
				float3 binormal = float3( 0,0,1 );

				float3 gerstnerWave_A = GerstnerWave_A( positionWS , tangent , binormal , _WaveASpeedXYSteepnesswavelength );
				float3 gerstnerWave_B = GerstnerWave_B( positionWS , tangent , binormal , _WaveB );
				float3 gerstnerWave_C = GerstnerWave_C( positionWS , tangent , binormal , _WaveC );
				float3 gerstnerWave = positionWS + gerstnerWave_A + gerstnerWave_B + gerstnerWave_C;

				float clampResult = clamp( (gerstnerWave - positionWS).y , 0.0 , 1.0 );
				float4 WaveColor = clampResult * _WaveColor;
				

				return WaveColor;
			}

			ENDHLSL
		}

		
	}

	
}
