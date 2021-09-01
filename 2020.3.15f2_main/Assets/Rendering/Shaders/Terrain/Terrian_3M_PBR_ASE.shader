// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Jefford/Terrian/3M PBR_ASE"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin][Toggle(_ISBLENDMAP_ON)] _IsBlendMap("IsBlendMap", Float) = 0
		_BlendContrast("BlendContrast", Range( 0 , 1)) = 0.1
		[Toggle(_ISAUTOSLOPE_ON)] _IsAutoSlope("IsAutoSlope", Float) = 0
		_SlopeRange("SlopeRange", Range( 1 , 10)) = 0
		_SlopeHeightContract("SlopeHeightContract", Range( 0 , 1)) = 1
		[NoScaleOffset]_BlendMap("BlendMap", 2D) = "white" {}
		[NoScaleOffset]_Layer1_BaseMap_Slope("Layer1_BaseMap_Slope", 2D) = "white" {}
		_Layer1_Tilling("Layer1_Tilling", Range( 1 , 5)) = 1
		[NoScaleOffset]_Layer1_HRA("Layer1_HRA", 2D) = "white" {}
		_Layer01_HeightContrast("Layer01_HeightContrast", Range( 0 , 1)) = 0
		_Layer1_Roughness("Layer1_Roughness", Float) = 1
		[NoScaleOffset]_Layer1_NormalMap("Layer1_NormalMap", 2D) = "bump" {}
		[NoScaleOffset]_Layer2_BaseMap("Layer2_BaseMap", 2D) = "white" {}
		_Layer2_Tilling("Layer2_Tilling", Range( 1 , 5)) = 1
		[NoScaleOffset]_Layer2_HRA("Layer2_HRA", 2D) = "white" {}
		_Layer02_HeightContrast("Layer02_HeightContrast", Range( 0 , 1)) = 0
		[NoScaleOffset]_Layer2_NormalMap("Layer2_NormalMap", 2D) = "bump" {}
		[NoScaleOffset]_Layer3_BaseMap("Layer3_BaseMap", 2D) = "white" {}
		_Layer3_Tilling("Layer3_Tilling", Range( 1 , 5)) = 1
		[NoScaleOffset]_Layer3_HRA("Layer3_HRA", 2D) = "white" {}
		_Layer03_HeightContrast("Layer03_HeightContrast", Range( 0 , 1)) = 0
		[ASEEnd][NoScaleOffset]_Layer3_NormalMap("Layer3_NormalMap", 2D) = "bump" {}

		//_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		//_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		//_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		//_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
		//_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		//_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		//_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5
		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		Cull Back
		AlphaToMask Off
		HLSLINCLUDE
		#pragma target 2.0

		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}
		
		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#define _RECEIVE_SHADOWS_OFF 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_FORWARD

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			
			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
			    #define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_FRAG_WORLD_NORMAL
			#pragma shader_feature_local _ISAUTOSLOPE_ON
			#pragma shader_feature_local _ISBLENDMAP_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 fogFactorAndVertexLight : TEXCOORD1;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD2;
				#endif
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD6;
				#endif
				float4 ase_texcoord7 : TEXCOORD7;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float _Layer1_Tilling;
			float _Layer01_HeightContrast;
			float _Layer2_Tilling;
			float _Layer02_HeightContrast;
			float _Layer3_Tilling;
			float _Layer03_HeightContrast;
			float _BlendContrast;
			float _SlopeHeightContract;
			float _SlopeRange;
			float _Layer1_Roughness;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			TEXTURE2D(_Layer1_BaseMap_Slope);
			SAMPLER(sampler_Layer1_BaseMap_Slope);
			TEXTURE2D(_Layer1_HRA);
			SAMPLER(sampler_Layer1_HRA);
			TEXTURE2D(_BlendMap);
			SAMPLER(sampler_BlendMap);
			TEXTURE2D(_Layer2_HRA);
			SAMPLER(sampler_Layer2_HRA);
			TEXTURE2D(_Layer3_HRA);
			SAMPLER(sampler_Layer3_HRA);
			TEXTURE2D(_Layer2_BaseMap);
			SAMPLER(sampler_Layer2_BaseMap);
			TEXTURE2D(_Layer3_BaseMap);
			SAMPLER(sampler_Layer3_BaseMap);
			TEXTURE2D(_Layer1_NormalMap);
			SAMPLER(sampler_Layer1_NormalMap);
			TEXTURE2D(_Layer2_NormalMap);
			SAMPLER(sampler_Layer2_NormalMap);
			TEXTURE2D(_Layer3_NormalMap);
			SAMPLER(sampler_Layer3_NormalMap);


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_texcoord7.xy = v.texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord7.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.ase_normal, v.ase_tangent );

				o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				OUTPUT_SH( normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz );

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.texcoord;
					o.lightmapUVOrVertexSH.xy = v.texcoord * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );
				#ifdef ASE_FOG
					half fogFactor = ComputeFogFactor( positionCS.z );
				#else
					half fogFactor = 0;
				#endif
				o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
				
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				
				o.clipPos = positionCS;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				o.screenPos = ComputeScreenPos(positionCS);
				#endif
				return o;
			}
			
			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.texcoord1 = v.texcoord1;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( IN.tSpace0.xyz );
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif
				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif
	
				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float2 texCoord44 = IN.ase_texcoord7.xy * float2( 1,1 ) + float2( 0,0 );
				float2 LayerUV46 = texCoord44;
				float2 temp_output_64_0 = ( LayerUV46 * _Layer1_Tilling );
				float4 Layer1_BaseMap76 = SAMPLE_TEXTURE2D( _Layer1_BaseMap_Slope, sampler_Layer1_BaseMap_Slope, temp_output_64_0 );
				float4 tex2DNode109 = SAMPLE_TEXTURE2D( _Layer1_HRA, sampler_Layer1_HRA, temp_output_64_0 );
				float temp_output_2_0_g5 = tex2DNode109.r;
				float lerpResult4_g5 = lerp( ( 0.0 - temp_output_2_0_g5 ) , ( temp_output_2_0_g5 + 1.0 ) , _Layer01_HeightContrast);
				float clampResult3_g5 = clamp( lerpResult4_g5 , 0.0 , 1.0 );
				float Layer1_Height127 = clampResult3_g5;
				float2 texCoord224 = IN.ase_texcoord7.xy * float2( 1,1 ) + float2( 0,0 );
				#ifdef _ISBLENDMAP_ON
				float4 staticSwitch239 = SAMPLE_TEXTURE2D( _BlendMap, sampler_BlendMap, texCoord224 );
				#else
				float4 staticSwitch239 = IN.ase_color;
				#endif
				float4 break203 = staticSwitch239;
				float R210 = break203.r;
				float M_R226 = ( Layer1_Height127 + R210 );
				float G211 = break203.g;
				float2 temp_output_52_0 = ( LayerUV46 * _Layer2_Tilling );
				float4 tex2DNode55 = SAMPLE_TEXTURE2D( _Layer2_HRA, sampler_Layer2_HRA, temp_output_52_0 );
				float temp_output_2_0_g6 = tex2DNode55.r;
				float lerpResult4_g6 = lerp( ( 0.0 - temp_output_2_0_g6 ) , ( temp_output_2_0_g6 + 1.0 ) , _Layer02_HeightContrast);
				float clampResult3_g6 = clamp( lerpResult4_g6 , 0.0 , 1.0 );
				float Layer2_Height58 = clampResult3_g6;
				float M_G227 = ( G211 + Layer2_Height58 );
				float B212 = break203.b;
				float2 temp_output_53_0 = ( LayerUV46 * _Layer3_Tilling );
				float4 tex2DNode56 = SAMPLE_TEXTURE2D( _Layer3_HRA, sampler_Layer3_HRA, temp_output_53_0 );
				float temp_output_2_0_g7 = tex2DNode56.r;
				float lerpResult4_g7 = lerp( ( 0.0 - temp_output_2_0_g7 ) , ( temp_output_2_0_g7 + 1.0 ) , _Layer03_HeightContrast);
				float clampResult3_g7 = clamp( lerpResult4_g7 , 0.0 , 1.0 );
				float Layer3_Height63 = clampResult3_g7;
				float M_B228 = ( B212 + Layer3_Height63 );
				float temp_output_28_0 = ( max( max( M_R226 , M_G227 ) , M_B228 ) - _BlendContrast );
				float temp_output_33_0 = max( ( M_R226 - temp_output_28_0 ) , 0.0 );
				float temp_output_35_0 = max( ( M_G227 - temp_output_28_0 ) , 0.0 );
				float temp_output_34_0 = max( ( M_B228 - temp_output_28_0 ) , 0.0 );
				float3 appendResult36 = (float3(temp_output_33_0 , temp_output_35_0 , temp_output_34_0));
				float3 BlendWeight37 = ( appendResult36 / ( temp_output_33_0 + temp_output_35_0 + temp_output_34_0 ) );
				float3 break176 = BlendWeight37;
				float4 Layer2_BaseMap74 = SAMPLE_TEXTURE2D( _Layer2_BaseMap, sampler_Layer2_BaseMap, temp_output_52_0 );
				float4 Layer3_BaseMap79 = SAMPLE_TEXTURE2D( _Layer3_BaseMap, sampler_Layer3_BaseMap, temp_output_53_0 );
				float4 temp_output_180_0 = ( ( Layer1_BaseMap76 * break176.x ) + ( break176.y * Layer2_BaseMap74 ) + ( break176.z * Layer3_BaseMap79 ) );
				float temp_output_9_0_g8 = _SlopeHeightContract;
				float3 break282 = BlendWeight37;
				float SlopeHeight283 = ( ( Layer1_Height127 * break282.x ) + ( break282.y * Layer2_Height58 ) + ( break282.z * Layer3_Height63 ) );
				float dotResult244 = dot( WorldNormal , float3(0,1,0) );
				float clampResult8_g8 = clamp( ( ( SlopeHeight283 - 1.0 ) + ( pow( saturate( ( 1.0 - dotResult244 ) ) , _SlopeRange ) * 2.0 ) ) , 0.0 , 1.0 );
				float lerpResult12_g8 = lerp( ( 0.0 - temp_output_9_0_g8 ) , ( temp_output_9_0_g8 + 1.0 ) , clampResult8_g8);
				float clampResult13_g8 = clamp( lerpResult12_g8 , 0.0 , 1.0 );
				float Slope251 = clampResult13_g8;
				float4 lerpResult254 = lerp( temp_output_180_0 , Layer1_BaseMap76 , Slope251);
				#ifdef _ISAUTOSLOPE_ON
				float4 staticSwitch258 = lerpResult254;
				#else
				float4 staticSwitch258 = temp_output_180_0;
				#endif
				float4 BaseColor149 = staticSwitch258;
				
				float3 Layer1_NormalMap108 = UnpackNormalScale( SAMPLE_TEXTURE2D( _Layer1_NormalMap, sampler_Layer1_NormalMap, temp_output_64_0 ), 1.0f );
				float3 break182 = BlendWeight37;
				float3 Layer2_NormalMap102 = UnpackNormalScale( SAMPLE_TEXTURE2D( _Layer2_NormalMap, sampler_Layer2_NormalMap, temp_output_52_0 ), 1.0f );
				float3 Layer3_NormalMap119 = UnpackNormalScale( SAMPLE_TEXTURE2D( _Layer3_NormalMap, sampler_Layer3_NormalMap, temp_output_53_0 ), 1.0f );
				float3 temp_output_196_0 = ( ( Layer1_NormalMap108 * break182.x ) + ( break182.y * Layer2_NormalMap102 ) + ( break182.z * Layer3_NormalMap119 ) );
				float3 lerpResult290 = lerp( temp_output_196_0 , Layer1_NormalMap108 , Slope251);
				#ifdef _ISAUTOSLOPE_ON
				float3 staticSwitch291 = lerpResult290;
				#else
				float3 staticSwitch291 = temp_output_196_0;
				#endif
				float3 NormalMap162 = staticSwitch291;
				
				float Layer1_Roughness111 = ( ( 1.0 - tex2DNode109.g ) * _Layer1_Roughness );
				
				float Layer1_AO132 = tex2DNode109.b;
				float3 break187 = BlendWeight37;
				float Layer2_AO101 = tex2DNode55.b;
				float Layer3_AO120 = tex2DNode56.b;
				float temp_output_198_0 = ( ( Layer1_AO132 * break187.x ) + ( break187.y * Layer2_AO101 ) + ( break187.z * Layer3_AO120 ) );
				float lerpResult297 = lerp( temp_output_198_0 , Layer1_AO132 , Slope251);
				#ifdef _ISAUTOSLOPE_ON
				float staticSwitch296 = lerpResult297;
				#else
				float staticSwitch296 = temp_output_198_0;
				#endif
				float AO157 = staticSwitch296;
				
				float3 Albedo = BaseColor149.rgb;
				float3 Normal = NormalMap162;
				float3 Emission = 0;
				float3 Specular = 0.5;
				float Metallic = 0.0;
				float Smoothness = Layer1_Roughness111;
				float Occlusion = AO157;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;
				inputData.shadowCoord = ShadowCoords;

				#ifdef _NORMALMAP
					#if _NORMAL_DROPOFF_TS
					inputData.normalWS = TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal ));
					#elif _NORMAL_DROPOFF_OS
					inputData.normalWS = TransformObjectToWorldNormal(Normal);
					#elif _NORMAL_DROPOFF_WS
					inputData.normalWS = Normal;
					#endif
					inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				#else
					inputData.normalWS = WorldNormal;
				#endif

				#ifdef ASE_FOG
					inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				#endif

				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS );
				#ifdef _ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif
				half4 color = UniversalFragmentPBR(
					inputData, 
					Albedo, 
					Metallic, 
					Specular, 
					Smoothness, 
					Occlusion, 
					Emission, 
					Alpha);

				#ifdef _TRANSMISSION_ASE
				{
					float shadow = _TransmissionShadow;

					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );
					half3 mainTransmission = max(0 , -dot(inputData.normalWS, mainLight.direction)) * mainAtten * Transmission;
					color.rgb += Albedo * mainTransmission;

					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );

							half3 transmission = max(0 , -dot(inputData.normalWS, light.direction)) * atten * Transmission;
							color.rgb += Albedo * transmission;
						}
					#endif
				}
				#endif

				#ifdef _TRANSLUCENCY_ASE
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );

					half3 mainLightDir = mainLight.direction + inputData.normalWS * normal;
					half mainVdotL = pow( saturate( dot( inputData.viewDirectionWS, -mainLightDir ) ), scattering );
					half3 mainTranslucency = mainAtten * ( mainVdotL * direct + inputData.bakedGI * ambient ) * Translucency;
					color.rgb += Albedo * mainTranslucency * strength;

					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );

							half3 lightDir = light.direction + inputData.normalWS * normal;
							half VdotL = pow( saturate( dot( inputData.viewDirectionWS, -lightDir ) ), scattering );
							half3 translucency = atten * ( VdotL * direct + inputData.bakedGI * ambient ) * Translucency;
							color.rgb += Albedo * translucency * strength;
						}
					#endif
				}
				#endif

				#ifdef _REFRACTION_ASE
					float4 projScreenPos = ScreenPos / ScreenPos.w;
					float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, WorldNormal ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
					projScreenPos.xy += refractionOffset.xy;
					float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos ) * RefractionColor;
					color.rgb = lerp( refraction, color.rgb, color.a );
					color.a = 1;
				#endif

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
					#else
						color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
					#endif
				#endif
				
				return color;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#define _RECEIVE_SHADOWS_OFF 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float _Layer1_Tilling;
			float _Layer01_HeightContrast;
			float _Layer2_Tilling;
			float _Layer02_HeightContrast;
			float _Layer3_Tilling;
			float _Layer03_HeightContrast;
			float _BlendContrast;
			float _SlopeHeightContract;
			float _SlopeRange;
			float _Layer1_Roughness;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Universal2D"
			Tags { "LightMode"="Universal2D" }

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#define _RECEIVE_SHADOWS_OFF 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 999999

			#pragma enable_d3d11_debug_symbols
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_2D

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			
			#define ASE_NEEDS_VERT_NORMAL
			#pragma shader_feature_local _ISAUTOSLOPE_ON
			#pragma shader_feature_local _ISBLENDMAP_ON


			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float _Layer1_Tilling;
			float _Layer01_HeightContrast;
			float _Layer2_Tilling;
			float _Layer02_HeightContrast;
			float _Layer3_Tilling;
			float _Layer03_HeightContrast;
			float _BlendContrast;
			float _SlopeHeightContract;
			float _SlopeRange;
			float _Layer1_Roughness;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			TEXTURE2D(_Layer1_BaseMap_Slope);
			SAMPLER(sampler_Layer1_BaseMap_Slope);
			TEXTURE2D(_Layer1_HRA);
			SAMPLER(sampler_Layer1_HRA);
			TEXTURE2D(_BlendMap);
			SAMPLER(sampler_BlendMap);
			TEXTURE2D(_Layer2_HRA);
			SAMPLER(sampler_Layer2_HRA);
			TEXTURE2D(_Layer3_HRA);
			SAMPLER(sampler_Layer3_HRA);
			TEXTURE2D(_Layer2_BaseMap);
			SAMPLER(sampler_Layer2_BaseMap);
			TEXTURE2D(_Layer3_BaseMap);
			SAMPLER(sampler_Layer3_BaseMap);


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord3.xyz = ase_worldNormal;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				o.ase_texcoord3.w = 0;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 texCoord44 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 LayerUV46 = texCoord44;
				float2 temp_output_64_0 = ( LayerUV46 * _Layer1_Tilling );
				float4 Layer1_BaseMap76 = SAMPLE_TEXTURE2D( _Layer1_BaseMap_Slope, sampler_Layer1_BaseMap_Slope, temp_output_64_0 );
				float4 tex2DNode109 = SAMPLE_TEXTURE2D( _Layer1_HRA, sampler_Layer1_HRA, temp_output_64_0 );
				float temp_output_2_0_g5 = tex2DNode109.r;
				float lerpResult4_g5 = lerp( ( 0.0 - temp_output_2_0_g5 ) , ( temp_output_2_0_g5 + 1.0 ) , _Layer01_HeightContrast);
				float clampResult3_g5 = clamp( lerpResult4_g5 , 0.0 , 1.0 );
				float Layer1_Height127 = clampResult3_g5;
				float2 texCoord224 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				#ifdef _ISBLENDMAP_ON
				float4 staticSwitch239 = SAMPLE_TEXTURE2D( _BlendMap, sampler_BlendMap, texCoord224 );
				#else
				float4 staticSwitch239 = IN.ase_color;
				#endif
				float4 break203 = staticSwitch239;
				float R210 = break203.r;
				float M_R226 = ( Layer1_Height127 + R210 );
				float G211 = break203.g;
				float2 temp_output_52_0 = ( LayerUV46 * _Layer2_Tilling );
				float4 tex2DNode55 = SAMPLE_TEXTURE2D( _Layer2_HRA, sampler_Layer2_HRA, temp_output_52_0 );
				float temp_output_2_0_g6 = tex2DNode55.r;
				float lerpResult4_g6 = lerp( ( 0.0 - temp_output_2_0_g6 ) , ( temp_output_2_0_g6 + 1.0 ) , _Layer02_HeightContrast);
				float clampResult3_g6 = clamp( lerpResult4_g6 , 0.0 , 1.0 );
				float Layer2_Height58 = clampResult3_g6;
				float M_G227 = ( G211 + Layer2_Height58 );
				float B212 = break203.b;
				float2 temp_output_53_0 = ( LayerUV46 * _Layer3_Tilling );
				float4 tex2DNode56 = SAMPLE_TEXTURE2D( _Layer3_HRA, sampler_Layer3_HRA, temp_output_53_0 );
				float temp_output_2_0_g7 = tex2DNode56.r;
				float lerpResult4_g7 = lerp( ( 0.0 - temp_output_2_0_g7 ) , ( temp_output_2_0_g7 + 1.0 ) , _Layer03_HeightContrast);
				float clampResult3_g7 = clamp( lerpResult4_g7 , 0.0 , 1.0 );
				float Layer3_Height63 = clampResult3_g7;
				float M_B228 = ( B212 + Layer3_Height63 );
				float temp_output_28_0 = ( max( max( M_R226 , M_G227 ) , M_B228 ) - _BlendContrast );
				float temp_output_33_0 = max( ( M_R226 - temp_output_28_0 ) , 0.0 );
				float temp_output_35_0 = max( ( M_G227 - temp_output_28_0 ) , 0.0 );
				float temp_output_34_0 = max( ( M_B228 - temp_output_28_0 ) , 0.0 );
				float3 appendResult36 = (float3(temp_output_33_0 , temp_output_35_0 , temp_output_34_0));
				float3 BlendWeight37 = ( appendResult36 / ( temp_output_33_0 + temp_output_35_0 + temp_output_34_0 ) );
				float3 break176 = BlendWeight37;
				float4 Layer2_BaseMap74 = SAMPLE_TEXTURE2D( _Layer2_BaseMap, sampler_Layer2_BaseMap, temp_output_52_0 );
				float4 Layer3_BaseMap79 = SAMPLE_TEXTURE2D( _Layer3_BaseMap, sampler_Layer3_BaseMap, temp_output_53_0 );
				float4 temp_output_180_0 = ( ( Layer1_BaseMap76 * break176.x ) + ( break176.y * Layer2_BaseMap74 ) + ( break176.z * Layer3_BaseMap79 ) );
				float temp_output_9_0_g8 = _SlopeHeightContract;
				float3 break282 = BlendWeight37;
				float SlopeHeight283 = ( ( Layer1_Height127 * break282.x ) + ( break282.y * Layer2_Height58 ) + ( break282.z * Layer3_Height63 ) );
				float3 ase_worldNormal = IN.ase_texcoord3.xyz;
				float dotResult244 = dot( ase_worldNormal , float3(0,1,0) );
				float clampResult8_g8 = clamp( ( ( SlopeHeight283 - 1.0 ) + ( pow( saturate( ( 1.0 - dotResult244 ) ) , _SlopeRange ) * 2.0 ) ) , 0.0 , 1.0 );
				float lerpResult12_g8 = lerp( ( 0.0 - temp_output_9_0_g8 ) , ( temp_output_9_0_g8 + 1.0 ) , clampResult8_g8);
				float clampResult13_g8 = clamp( lerpResult12_g8 , 0.0 , 1.0 );
				float Slope251 = clampResult13_g8;
				float4 lerpResult254 = lerp( temp_output_180_0 , Layer1_BaseMap76 , Slope251);
				#ifdef _ISAUTOSLOPE_ON
				float4 staticSwitch258 = lerpResult254;
				#else
				float4 staticSwitch258 = temp_output_180_0;
				#endif
				float4 BaseColor149 = staticSwitch258;
				
				
				float3 Albedo = BaseColor149.rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				half4 color = half4( Albedo, Alpha );

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				return color;
			}
			ENDHLSL
		}
		
	}
	/*ase_lod*/
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18500
-59;343;1920;554;4941.082;336.682;3.927996;True;False
Node;AmplifyShaderEditor.CommentaryNode;43;-2427.857,-2311.178;Inherit;False;542.3432;209;LayerUV;2;46;44;LayerUV;1,1,1,1;0;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;44;-2377.857,-2261.178;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;46;-2109.514,-2260.215;Inherit;False;LayerUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;216;-2777.554,-4057.096;Inherit;False;2369.551;1422.287;BlendWeight;41;228;231;230;31;227;229;226;24;211;210;212;203;223;224;207;37;38;39;36;34;35;33;30;32;28;29;25;209;208;215;206;214;204;205;213;232;233;234;235;238;239;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;54;-2974.737,-2054.544;Inherit;False;1687.632;827.8548;Layer1;16;132;127;122;113;111;109;108;94;91;76;66;64;60;59;217;218;Layer1;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;45;-2962.06,-1163.436;Inherit;False;1687.632;827.8548;Layer2;16;137;110;103;102;101;100;99;74;71;58;55;52;48;47;219;220;Layer2;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-2912.06,-955.7205;Inherit;False;Property;_Layer2_Tilling;Layer2_Tilling;15;0;Create;True;0;0;False;0;False;1;3.9;1;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;59;-2810.737,-1925.828;Inherit;False;46;LayerUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;224;-2749.109,-3834.135;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;49;-2933.526,-156.5072;Inherit;False;1687.632;827.8548;Layer3;16;131;123;121;120;119;116;105;79;75;63;56;53;51;50;222;221;Layer3;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;60;-2924.737,-1846.828;Inherit;False;Property;_Layer1_Tilling;Layer1_Tilling;9;0;Create;True;0;0;False;0;False;1;5;1;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;48;-2798.06,-1034.72;Inherit;False;46;LayerUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;223;-2529.109,-3831.135;Inherit;True;Property;_BlendMap;BlendMap;7;1;[NoScaleOffset];Create;True;0;0;False;0;False;-1;None;36e66baf007e57849845d2f97a7bca71;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;238;-2458.385,-4029.362;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-2609.737,-1882.828;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;51;-2853.526,88.20778;Inherit;False;Property;_Layer3_Tilling;Layer3_Tilling;21;0;Create;True;0;0;False;0;False;1;2.13;1;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;50;-2769.526,-27.79222;Inherit;False;46;LayerUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;52;-2597.06,-991.7205;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;55;-2253.177,-840.8807;Inherit;True;Property;_Layer2_HRA;Layer2_HRA;16;1;[NoScaleOffset];Create;True;0;0;False;0;False;-1;None;f2d6fec9d7ef0bb4794d9b8fa40f8e83;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;239;-2222.385,-3961.362;Inherit;False;Property;_IsBlendMap;IsBlendMap;0;0;Create;True;0;0;False;0;False;0;0;1;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;53;-2568.526,15.20778;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;109;-2292.853,-1688.988;Inherit;True;Property;_Layer1_HRA;Layer1_HRA;10;1;[NoScaleOffset];Create;True;0;0;False;0;False;-1;None;88fdd20478fb869468f60a3d2fcb19ea;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;219;-2247.573,-923.8746;Inherit;False;Property;_Layer02_HeightContrast;Layer02_HeightContrast;17;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;217;-2280.084,-1805.475;Inherit;False;Property;_Layer01_HeightContrast;Layer01_HeightContrast;11;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;56;-2224.642,166.0479;Inherit;True;Property;_Layer3_HRA;Layer3_HRA;22;1;[NoScaleOffset];Create;True;0;0;False;0;False;-1;None;3cb2fa9327229104b9395332cdf8b9bc;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;221;-2214.841,87.52405;Inherit;False;Property;_Layer03_HeightContrast;Layer03_HeightContrast;23;0;Create;True;0;0;False;0;False;0;0.37;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;218;-1960.084,-1790.475;Inherit;False;CheapContrast;-1;;5;87c1eaaf15470dc4396ef10c5eb870e0;0;2;6;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;220;-1927.573,-908.8746;Inherit;False;CheapContrast;-1;;6;87c1eaaf15470dc4396ef10c5eb870e0;0;2;6;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;203;-2028.188,-3961.577;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.FunctionNode;222;-1881.841,59.52405;Inherit;False;CheapContrast;-1;;7;87c1eaaf15470dc4396ef10c5eb870e0;0;2;6;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;210;-1627.997,-4017.604;Inherit;False;R;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;211;-1646.241,-3908.546;Inherit;False;G;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;127;-1698.454,-1757.989;Inherit;False;Layer1_Height;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;58;-1661.777,-908.882;Inherit;False;Layer2_Height;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;63;-1584.243,65.04689;Inherit;False;Layer3_Height;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;212;-1638.241,-3830.546;Inherit;False;B;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;204;-2568.498,-3567.048;Inherit;False;127;Layer1_Height;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;205;-1986.935,-3587.25;Inherit;False;58;Layer2_Height;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;213;-2538.455,-3485.57;Inherit;False;210;R;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;214;-1984.892,-3685.772;Inherit;False;211;G;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;206;-1286.67,-3640.646;Inherit;False;63;Layer3_Height;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;207;-2367.498,-3544.048;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;208;-1743.936,-3664.25;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;215;-1291.627,-3718.168;Inherit;False;212;B;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;227;-1588.971,-3656.689;Inherit;False;M_G;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;226;-2225.533,-3539.486;Inherit;False;M_R;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;209;-1074.67,-3688.646;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;228;-912.7045,-3683.085;Inherit;False;M_B;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;232;-2674.811,-3251.062;Inherit;False;226;M_R;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;233;-2682.811,-3167.062;Inherit;False;227;M_G;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;24;-2487.74,-3203.43;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;234;-2670.765,-3069.793;Inherit;False;228;M_B;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;25;-2360.74,-3118.43;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;29;-2445.741,-2969.43;Inherit;False;Property;_BlendContrast;BlendContrast;1;0;Create;True;0;0;False;0;False;0.1;0.161;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;28;-2171.989,-3088.989;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;237;-1882.994,-3051.884;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;230;-1803.18,-3125.493;Inherit;False;227;M_G;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;235;-1931.994,-3195.884;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;236;-1891.994,-2926.884;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;229;-1810.18,-3281.493;Inherit;False;226;M_R;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;231;-1792.18,-3008.493;Inherit;False;228;M_B;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;32;-1584.013,-2989.523;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;30;-1610.013,-3250.523;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;31;-1588.013,-3111.524;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;35;-1395.013,-3123.524;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;33;-1400.013,-3241.523;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;34;-1397.013,-2996.523;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;36;-1152.013,-3264.524;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;39;-1142.012,-3015.523;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;38;-994.0113,-3153.523;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;37;-823.9456,-3151.052;Inherit;False;BlendWeight;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;252;-240.3606,-4358.226;Inherit;False;1925.017;1104.248;Slope;21;251;259;260;250;287;247;283;246;285;248;279;286;281;284;244;282;277;278;240;280;242;Slope;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;280;-2.60564,-3862.672;Inherit;False;37;BlendWeight;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;277;214.6549,-3710.234;Inherit;False;58;Layer2_Height;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;242;-190.3604,-4127.224;Inherit;False;Constant;_Vector0;Vector 0;21;0;Create;True;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;284;233.5987,-3604.7;Inherit;False;63;Layer3_Height;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;240;-188.3604,-4308.225;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;278;245.8544,-3956.734;Inherit;False;127;Layer1_Height;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;282;210.2466,-3860.82;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DotProductOpNode;244;89.63954,-4194.224;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;286;593.7583,-3669.011;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;281;522.1232,-3910.612;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;279;527.7582,-3783.111;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;246;256.6385,-4199.224;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;285;780.6176,-3853.947;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;75;-2216.046,-106.5072;Inherit;True;Property;_Layer3_BaseMap;Layer3_BaseMap;20;1;[NoScaleOffset];Create;True;0;0;False;0;False;-1;None;e65adfa1700f1ae4b91bb0334228404a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;283;950.7364,-3860.126;Inherit;False;SlopeHeight;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;250;409.0119,-4267.999;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;248;245.9693,-4104.886;Inherit;False;Property;_SlopeRange;SlopeRange;5;0;Create;True;0;0;False;0;False;0;1;1;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;138;-980.4138,-1984.427;Inherit;False;1948.948;710.5123;BaseColor;14;175;177;174;176;144;179;178;180;149;145;254;256;257;258;BaseColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.SamplerNode;71;-2268.58,-1119.436;Inherit;True;Property;_Layer2_BaseMap;Layer2_BaseMap;14;1;[NoScaleOffset];Create;True;0;0;False;0;False;-1;None;7f505bb9f124d2e42b0d5f6d9bea736a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;66;-2257.257,-2004.544;Inherit;True;Property;_Layer1_BaseMap_Slope;Layer1_BaseMap_Slope;8;1;[NoScaleOffset];Create;True;0;0;False;0;False;-1;None;2ed9ef9a580690d40ae5fe9d82156af8;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;74;-1867.221,-1111.846;Inherit;False;Layer2_BaseMap;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;76;-1879.898,-2002.954;Inherit;False;Layer1_BaseMap;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;79;-1838.687,-104.9182;Inherit;False;Layer3_BaseMap;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;145;-956.6884,-1735.258;Inherit;False;37;BlendWeight;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PowerNode;247;545.6392,-4208.224;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;287;686.8639,-4110.583;Inherit;False;283;SlopeHeight;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;260;597.7108,-4013.727;Inherit;False;Property;_SlopeHeightContract;SlopeHeightContract;6;0;Create;True;0;0;False;0;False;1;0.1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;259;1015.069,-4204.876;Inherit;False;HeightLerp;-1;;8;a4412d0f44ca8f84a92e33ac370d2ba4;0;3;5;FLOAT;0;False;1;FLOAT;0;False;9;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;144;-837.0579,-1856.793;Inherit;False;76;Layer1_BaseMap;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;174;-737.6769,-1589.014;Inherit;False;74;Layer2_BaseMap;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;175;-705.6769,-1440.014;Inherit;False;79;Layer3_BaseMap;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.BreakToComponentsNode;176;-743.8362,-1733.406;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;178;-383.3594,-1665.898;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;179;-323.3594,-1489.898;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;177;-410.3594,-1764.898;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;251;1432.677,-4246.316;Inherit;False;Slope;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;256;-63.22528,-1426.635;Inherit;False;251;Slope;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;180;-109.3594,-1704.898;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;257;-77.3718,-1533;Inherit;False;76;Layer1_BaseMap;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;254;183.7747,-1582.635;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;258;381.5566,-1708.621;Inherit;False;Property;_IsAutoSlope;IsAutoSlope;2;0;Create;True;0;0;False;0;False;0;0;1;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;149;717.6568,-1722.121;Inherit;False;BaseColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;141;-966.9714,-394.7513;Inherit;False;1944.049;782.7815;Roughness;15;10;5;8;9;7;194;197;150;193;191;192;166;172;195;154;Roughness;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;140;-963.7437,-1181.799;Inherit;False;2088.434;651.4046;NormalMap;14;185;196;165;162;182;183;181;184;158;163;288;289;290;291;NormalMap;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;139;-970.3021,516.8085;Inherit;False;2264.227;733.7641;AO;14;190;187;167;151;188;157;186;189;198;170;296;297;298;299;AO;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;132;-1905.891,-1438.423;Inherit;False;Layer1_AO;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;94;-2308.135,-1419.489;Inherit;True;Property;_Layer1_NormalMap;Layer1_NormalMap;13;1;[NoScaleOffset];Create;True;0;0;False;0;False;-1;None;911cf8ac38a3d3847967cd54e3d78b2f;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;294;-91.76462,129.989;Inherit;False;137;Layer2_Roughness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;154;-709.2508,-212.9299;Inherit;False;111;Layer1_Roughness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;137;-1518.428,-765.0997;Inherit;False;Layer2_Roughness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;291;325.4008,-938.2064;Inherit;True;Property;_IsAutoSlope;IsAutoSlope;2;0;Create;True;0;0;False;0;False;0;0;1;True;;Toggle;2;Key0;Key1;Reference;258;True;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;192;-618.4232,-122.5483;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.GetLocalVarNode;151;-598.1678,617.6385;Inherit;False;132;Layer1_AO;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;116;-2215.325,459.5469;Inherit;True;Property;_Layer3_NormalMap;Layer3_NormalMap;25;1;[NoScaleOffset];Create;True;0;0;False;0;False;-1;None;c14f0d6deb03eee42a1dad5812df9cdd;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;296;393.9741,797.5371;Inherit;True;Property;_IsAutoSlope;IsAutoSlope;2;0;Create;True;0;0;False;0;False;0;0;1;True;;Toggle;2;Key0;Key1;Reference;258;True;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;293;177.3819,60.35382;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;292;352.1638,-57.63208;Inherit;True;Property;_IsAutoSlope;IsAutoSlope;4;0;Create;True;0;0;False;0;False;0;0;1;True;;Toggle;2;Key0;Key1;Reference;258;True;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;297;121.1923,982.523;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;194;-196.9118,-89.83833;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;191;-811.83,-124.4003;Inherit;False;37;BlendWeight;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;197;25.0564,-124.5322;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;299;-95.80771,1140.523;Inherit;False;251;Slope;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;290;150.6189,-820.2205;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;162;600.8747,-1009.947;Inherit;False;NormalMap;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;100;-1683.82,-774.6648;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;190;-407.2292,895.1181;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;123;-1489.894,182.8289;Inherit;False;Layer3_Roughness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;196;-103.9802,-1008.012;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;108;-1920.537,-1336.39;Inherit;False;Layer1_NormalMap;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;200;1219.991,-1791.612;Inherit;False;162;NormalMap;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;295;-39.61806,218.3538;Inherit;False;251;Slope;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;102;-1907.861,-549.2827;Inherit;False;Layer2_NormalMap;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;110;-2246.459,-547.3817;Inherit;True;Property;_Layer2_NormalMap;Layer2_NormalMap;19;1;[NoScaleOffset];Create;True;0;0;False;0;False;-1;None;f0ad82d505345b047a39a6e6a4d04367;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;167;-686.1679,957.6385;Inherit;False;101;Layer2_AO;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;172;621.9582,-159.9311;Inherit;False;Roughness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;121;-1864.067,269.9629;Inherit;False;Property;_Layer3_Roughness;Layer3_Roughness;24;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;188;-401.8642,733.5161;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;99;-1892.601,-736.9657;Inherit;False;Property;_Layer2_Roughness;Layer2_Roughness;18;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;170;-656.556,1079.974;Inherit;False;120;Layer3_AO;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;120;-1864.681,355.6138;Inherit;False;Layer3_AO;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;113;-1905.278,-1524.073;Inherit;False;Property;_Layer1_Roughness;Layer1_Roughness;12;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;195;-331.9119,6.261627;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;163;-638.7437,-1110.799;Inherit;False;108;Layer1_NormalMap;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;103;-1866.777,-805.8817;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;189;-272.2291,799.0181;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;181;-887.2036,-1016.737;Inherit;False;37;BlendWeight;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;198;47.43629,770.9468;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;111;-1531.105,-1611.207;Inherit;False;Layer1_Roughness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;288;-66.38105,-662.2205;Inherit;False;251;Slope;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;187;-693.7407,766.308;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;225;1455.307,-1740.443;Inherit;False;Constant;_Float0;Float 0;20;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;91;-1887.454,-1623.989;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;184;-276.8397,-947.176;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;157;804.732,719.2505;Inherit;False;AO;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;183;-382.4748,-1047.677;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;199;1458.991,-1924.612;Inherit;False;149;BaseColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;119;-1879.327,457.6458;Inherit;False;Layer3_NormalMap;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;101;-1893.215,-651.3147;Inherit;False;Layer2_AO;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;105;-1660.286,187.2639;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;131;-1846.243,170.0469;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;166;-713.8442,146.75;Inherit;False;123;Layer3_Roughness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;185;-290.8397,-823.0757;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;201;1189.471,-1693.563;Inherit;False;111;Layer1_Roughness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;202;1190.042,-1604.652;Inherit;False;157;AO;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;186;-906.5929,764.4561;Inherit;False;37;BlendWeight;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;165;-643.9993,-750.765;Inherit;False;119;Layer3_NormalMap;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;158;-669.9432,-864.2991;Inherit;False;102;Layer2_NormalMap;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;289;-118.5276,-750.5854;Inherit;False;108;Layer1_NormalMap;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;182;-674.3514,-1014.885;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;193;-326.5469,-155.3403;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;150;-732.2508,28.06992;Inherit;False;137;Layer2_Roughness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;122;-1701.497,-1606.772;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;298;-176.9543,965.1582;Inherit;False;132;Layer1_AO;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;6;1750.011,-1821.242;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;Jefford/Terrian/3M PBR_ASE;94348b07e5e8bab40bd6c8a1e3df54cd;True;Forward;0;1;Forward;17;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;0;Hidden/InternalErrorShader;0;0;Standard;36;Workflow;1;Surface;0;  Refraction Model;0;  Blend;0;Two Sided;1;Fragment Normal Space,InvertActionOnDeselection;0;Transmission;0;  Transmission Shadow;0.5,False,-1;Translucency;0;  Translucency Strength;1,False,-1;  Normal Distortion;0.5,False,-1;  Scattering;2,False,-1;  Direct;0.9,False,-1;  Ambient;0.1,False,-1;  Shadow;0.5,False,-1;Cast Shadows;0;  Use Shadow Threshold;0;Receive Shadows;0;GPU Instancing;0;LOD CrossFade;0;Built-in Fog;0;_FinalColorxAlpha;0;Meta Pass;0;Override Baked GI;0;Extra Pre Pass;0;DOTS Instancing;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;6;False;True;False;True;False;True;False;;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;10;139,12;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=Universal2D;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;9;139,12;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;8;139,12;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;False;False;False;False;0;False;-1;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;7;139,12;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;163.5966,194.3087;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;0;Hidden/InternalErrorShader;0;0;Standard;0;True;0
WireConnection;46;0;44;0
WireConnection;223;1;224;0
WireConnection;64;0;59;0
WireConnection;64;1;60;0
WireConnection;52;0;48;0
WireConnection;52;1;47;0
WireConnection;55;1;52;0
WireConnection;239;1;238;0
WireConnection;239;0;223;0
WireConnection;53;0;50;0
WireConnection;53;1;51;0
WireConnection;109;1;64;0
WireConnection;56;1;53;0
WireConnection;218;6;217;0
WireConnection;218;2;109;1
WireConnection;220;6;219;0
WireConnection;220;2;55;1
WireConnection;203;0;239;0
WireConnection;222;6;221;0
WireConnection;222;2;56;1
WireConnection;210;0;203;0
WireConnection;211;0;203;1
WireConnection;127;0;218;0
WireConnection;58;0;220;0
WireConnection;63;0;222;0
WireConnection;212;0;203;2
WireConnection;207;0;204;0
WireConnection;207;1;213;0
WireConnection;208;0;214;0
WireConnection;208;1;205;0
WireConnection;227;0;208;0
WireConnection;226;0;207;0
WireConnection;209;0;215;0
WireConnection;209;1;206;0
WireConnection;228;0;209;0
WireConnection;24;0;232;0
WireConnection;24;1;233;0
WireConnection;25;0;24;0
WireConnection;25;1;234;0
WireConnection;28;0;25;0
WireConnection;28;1;29;0
WireConnection;237;0;28;0
WireConnection;235;0;28;0
WireConnection;236;0;28;0
WireConnection;32;0;231;0
WireConnection;32;1;236;0
WireConnection;30;0;229;0
WireConnection;30;1;235;0
WireConnection;31;0;230;0
WireConnection;31;1;237;0
WireConnection;35;0;31;0
WireConnection;33;0;30;0
WireConnection;34;0;32;0
WireConnection;36;0;33;0
WireConnection;36;1;35;0
WireConnection;36;2;34;0
WireConnection;39;0;33;0
WireConnection;39;1;35;0
WireConnection;39;2;34;0
WireConnection;38;0;36;0
WireConnection;38;1;39;0
WireConnection;37;0;38;0
WireConnection;282;0;280;0
WireConnection;244;0;240;0
WireConnection;244;1;242;0
WireConnection;286;0;282;2
WireConnection;286;1;284;0
WireConnection;281;0;278;0
WireConnection;281;1;282;0
WireConnection;279;0;282;1
WireConnection;279;1;277;0
WireConnection;246;0;244;0
WireConnection;285;0;281;0
WireConnection;285;1;279;0
WireConnection;285;2;286;0
WireConnection;75;1;53;0
WireConnection;283;0;285;0
WireConnection;250;0;246;0
WireConnection;71;1;52;0
WireConnection;66;1;64;0
WireConnection;74;0;71;0
WireConnection;76;0;66;0
WireConnection;79;0;75;0
WireConnection;247;0;250;0
WireConnection;247;1;248;0
WireConnection;259;5;247;0
WireConnection;259;1;287;0
WireConnection;259;9;260;0
WireConnection;176;0;145;0
WireConnection;178;0;176;1
WireConnection;178;1;174;0
WireConnection;179;0;176;2
WireConnection;179;1;175;0
WireConnection;177;0;144;0
WireConnection;177;1;176;0
WireConnection;251;0;259;0
WireConnection;180;0;177;0
WireConnection;180;1;178;0
WireConnection;180;2;179;0
WireConnection;254;0;180;0
WireConnection;254;1;257;0
WireConnection;254;2;256;0
WireConnection;258;1;180;0
WireConnection;258;0;254;0
WireConnection;149;0;258;0
WireConnection;132;0;109;3
WireConnection;94;1;64;0
WireConnection;137;0;100;0
WireConnection;291;1;196;0
WireConnection;291;0;290;0
WireConnection;192;0;191;0
WireConnection;116;1;53;0
WireConnection;296;1;198;0
WireConnection;296;0;297;0
WireConnection;293;0;197;0
WireConnection;293;1;294;0
WireConnection;293;2;295;0
WireConnection;292;1;197;0
WireConnection;292;0;293;0
WireConnection;297;0;198;0
WireConnection;297;1;298;0
WireConnection;297;2;299;0
WireConnection;194;0;192;1
WireConnection;194;1;150;0
WireConnection;197;0;193;0
WireConnection;197;1;194;0
WireConnection;197;2;195;0
WireConnection;290;0;196;0
WireConnection;290;1;289;0
WireConnection;290;2;288;0
WireConnection;162;0;291;0
WireConnection;100;0;103;0
WireConnection;100;1;99;0
WireConnection;190;0;187;2
WireConnection;190;1;170;0
WireConnection;123;0;105;0
WireConnection;196;0;183;0
WireConnection;196;1;184;0
WireConnection;196;2;185;0
WireConnection;108;0;94;0
WireConnection;102;0;110;0
WireConnection;110;1;52;0
WireConnection;172;0;292;0
WireConnection;188;0;151;0
WireConnection;188;1;187;0
WireConnection;120;0;56;3
WireConnection;195;0;192;2
WireConnection;195;1;166;0
WireConnection;103;0;55;2
WireConnection;189;0;187;1
WireConnection;189;1;167;0
WireConnection;198;0;188;0
WireConnection;198;1;189;0
WireConnection;198;2;190;0
WireConnection;111;0;122;0
WireConnection;187;0;186;0
WireConnection;91;0;109;2
WireConnection;184;0;182;1
WireConnection;184;1;158;0
WireConnection;157;0;296;0
WireConnection;183;0;163;0
WireConnection;183;1;182;0
WireConnection;119;0;116;0
WireConnection;101;0;55;3
WireConnection;105;0;131;0
WireConnection;105;1;121;0
WireConnection;131;0;56;2
WireConnection;185;0;182;2
WireConnection;185;1;165;0
WireConnection;182;0;181;0
WireConnection;193;0;154;0
WireConnection;193;1;192;0
WireConnection;122;0;91;0
WireConnection;122;1;113;0
WireConnection;6;0;199;0
WireConnection;6;1;200;0
WireConnection;6;3;225;0
WireConnection;6;4;201;0
WireConnection;6;5;202;0
ASEEND*/
//CHKSM=6451242A7A695B91F628D36CD5CB91550269B0AC