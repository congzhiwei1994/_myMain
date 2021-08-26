
Shader "Jefford/CatToonOcenWater"
{
    Properties
    {

        _ShallowColor(" 浅水颜色",Color) = (0,0,0,1)
        _DeepColor(" 深水颜色",Color) = (0,0,0,1)
        _FresnelColor(" 远处水面反射颜色",Color) = (1,1,1,1)
        _DepthRange(" 深度范围",Range(0,1)) = 1
        _FresnelRange(" 远处水面颜色的范围",float) = 1

        [Space(15)]
        [Header(SurFaceNormal)]
        _Tilling(" 法线缩放",float) = 1
        _SurFaceNormal("SurFaceNormal",2D) = "bump"{}
        _WaterSpeed(" 水流动的速度",Range(0,1)) = 1
        _WaterDix_X("水流X方向",Range(-1,1)) = 1
        _WaterDix_Z("水流Z方向",Range(-1,1)) = 1

        [Space(15)]
        [Header(Env)]
        [Toggle]_PlanarReflection("_PlanarReflection",int) = 0
        _PlanarReflectionIntensity("平面反射扭曲强度",Range(0,1)) = 1
        _EnvMap(" 环境球",Cube) = "white"{}
        _Smoothness("_Smoothness",Range(0,1)) = 1
        _EnvNoiseIntensity("环境球扭曲程度",Range(0,1)) = 1
        _FresnelIntensity("菲尼尔强度", Range(0,2)) = 1
        _FresnelPow("菲尼尔范围", Range(0,2)) = 1

        [Space(15)]
        [Header(UnderWater)]
        _UnderWaterDistort("折射扭曲强度",Range(0,1)) = 0.3

        [Space(15)]
        [Header(Caustic)]
        _CausticMap("_CausticMap",2D) = "white"{}
        _CausticTilling("_CausticTilling", float) = 1
        _CausticIntensity("焦散强度", Range(0,3)) = 1.5
        _CausticRange("焦散范围", Range(0,5)) = 1

        [Space(15)]
        [Header(Shore)]
        _ShoreColor("岸边泡沫的颜色",color) = (1,1,1,1)
        _ShoreRange("岸边泡沫的范围",Range(0, 1)) = 1
        _ShoreEdgeWidth("岸边宽度",Range(0,1)) = 1
        _ShoreEdgeIntensity("岸边泡沫强度",Range(0,1)) = 1

        [Space(15)]
        [Header(Foam)]
        _FoamColor("泡沫颜色",color) = (1,1,1,1)
        _FoamNoiseMap("泡沫噪波图",2D) = "white"{}
        _FoamNoiseTlling("泡沫噪波图缩放",Range(0,1)) = 1
        _FoamNoiseDissolve("泡沫溶解",Range(0,1)) = 1
        _FoamShape("泡沫的形状",Range(0,1)) = 0.5
        _FoamIntensity("泡沫的强度",Range(0,1)) = 1
        _FoamRange("泡沫的范围",Range(0,1)) = 1
        _FoamSpeed("泡沫的速度",Range(0,10)) = 1
        _FoamFrequency("泡沫的频率",Range(0,20)) = 1

        [Space(15)]
        [Header(Wave)]
        [Toggle] _Wave("是否启用动态波浪",float) = 1
        _WaveColor("WaveColor", Color) = (0,0,0,0)
        _WaveASpeedXYSteepnesswavelength("WaveA(SpeedXY, Steepness, wavelength)", Vector) = (1,1,2,50)
        _WaveB("WaveB", Vector) = (1,1,2,50)
        _WaveC("WaveC", Vector) = (1,1,2,50)

        

    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline"  "RenderType"="Water Transparent"  "Queue"="Transparent" }


        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForward" }
            
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma shader_feature _WAVE_ON
            #pragma shader_feature _PLANARREFLECTION_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"


            CBUFFER_START(UnityPerMaterial)

            half4 _ShallowColor;
            half4 _DeepColor;
            half _DepthRange;
            half _FresnelRange;
            half4 _FresnelColor;
            half _Smoothness;

            half _Tilling;
            half _WaterSpeed;
            half _WaterDix_X;
            half _WaterDix_Z;

            // Env
            half _EnvNoiseIntensity;
            half4 _EnvMap_HDR;
            half  _FresnelIntensity;
            half  _FresnelPow;

            //UnderWater
            half _UnderWaterDistort;

            // Caustics
            half _CausticTilling;
            half _CausticIntensity;
            half _CausticRange;

            // Shore
            half4 _ShoreColor;
            half _ShoreRange;
            half _ShoreEdgeWidth;
            half _ShoreEdgeIntensity;

            //Foam
            half4 _FoamColor;
            half _FoamRange;
            half _FoamSpeed;
            half _FoamFrequency;
            half _FoamIntensity;
            half _FoamNoiseTlling;
            half _FoamNoiseDissolve;
            half _FoamShape;

            //Wave
            half4 _WaveColor;
            half4 _WaveASpeedXYSteepnesswavelength;
            half4 _WaveB;
            half4 _WaveC;
            
            half _PlanarReflectionIntensity;
            CBUFFER_END

            
            TEXTURE2D (_SurFaceNormal);                                  SAMPLER(sampler_SurFaceNormal);
            TEXTURECUBE(_EnvMap);                                        SAMPLER(sampler_EnvMap);
            TEXTURE2D(_CausticMap);                                      SAMPLER(sampler_CausticMap);
            TEXTURE2D(_FoamNoiseMap);                                    SAMPLER(sampler_FoamNoiseMap);
            
            TEXTURE2D(_CameraDepthTexture);                              SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D(_CameraOpaqueTexture);                             SAMPLER(sampler_CameraOpaqueTexture);

            #if defined _PLANARREFLECTION_ON
                TEXTURE2D (_PlanarReflectionTexture);SAMPLER(sampler_PlanarReflectionTexture);
            #endif


            struct Attributes
            {
                float4 positionOS       : POSITION;
                float3 normalOS         : NORMAL;
                float4 tangentOS        : TANGENT;
                float2 uv               : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float2 uv                : TEXCOORD0;
                float3 positionWS       : TEXCOORD1;
                float3 viewDirWS            : TEXCOORD2;
                float3 normalWS                 : TEXCOORD3;  
                float3 tangentWS                : TEXCOORD4;    
                float3 bitangentWS              : TEXCOORD5;
                float3 positionVS               : TEXCOORD6;
                float fogCoord      : TEXCOORD7;
                

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

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.uv = v.uv;
                #if defined _WAVE_ON
                    float3 tangent = float3( 1,0,0 );
                    float3 binormal = float3( 0,0,1 );

                    float3 positionWS = mul(UNITY_MATRIX_M, float4(v.positionOS.xyz, 1)).xyz;
                    float3 gerstnerWave_A = GerstnerWave_A( positionWS , tangent , binormal , _WaveASpeedXYSteepnesswavelength );
                    float3 gerstnerWave_B = GerstnerWave_B( positionWS , tangent , binormal , _WaveB );
                    float3 gerstnerWave_C = GerstnerWave_C( positionWS , tangent , binormal , _WaveC );
                    positionWS = ( positionWS + gerstnerWave_A + gerstnerWave_B + gerstnerWave_C );
                    float3 positionOS = mul(UNITY_MATRIX_I_M, float4( positionWS,1)).xyz;
                #else
                    float3 positionOS = v.positionOS.xyz;
                #endif
                
                o.positionWS = mul(UNITY_MATRIX_M,float4(positionOS.xyz,1) );
                o.positionVS = mul(UNITY_MATRIX_V,float4(o.positionWS.xyz,1)).xyz;
                o.positionCS = mul(UNITY_MATRIX_VP,float4(o.positionWS.xyz,1));

                o.viewDirWS = _WorldSpaceCameraPos - o.positionWS; 
                
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
                o.tangentWS = SafeNormalize(mul((float3x3)UNITY_MATRIX_M, v.tangentOS.xyz));
                half sign = v.tangentOS.w * unity_WorldTransformParams.w;
                o.bitangentWS = cross(o.normalWS,o.tangentWS) * sign;
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float3 positionWS = i.positionWS;
                half2 worldUV = positionWS.xz;
                float3 V = SafeNormalize(i.viewDirWS);
                half NoV = saturate(dot(i.normalWS,V));
                half fresnel = 1 - NoV;

                
                float3 WaveColor = 0;
                {
                    #if defined _WAVE_ON
                        float3 tangent = float3( 1,0,0 );
                        float3 binormal = float3( 0,0,1 );
                        float3 gerstnerWave_A = GerstnerWave_A( positionWS ,tangent , binormal, _WaveASpeedXYSteepnesswavelength );
                        float3 gerstnerWave_B = GerstnerWave_B( positionWS , tangent ,binormal, _WaveB );
                        float3 gerstnerWave_C = GerstnerWave_C( positionWS , tangent , binormal, _WaveC );
                        float3 gerstnerWave = positionWS + gerstnerWave_A + gerstnerWave_B + gerstnerWave_C;
                        float clampResult = saturate(gerstnerWave - positionWS).y;
                        WaveColor = clampResult * _WaveColor; 
                    #endif
                }
                // 深度采样
                half2 screenUV = i.positionCS.xy / _ScreenParams.xy;
                half depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                half sceneDepth = LinearEyeDepth(depthMap, _ZBufferParams);
                // 深度差
                half viewDepth = sceneDepth - i.positionCS.w;
                

                // 通过深度差实现水的颜色
                half waterDepth = saturate(exp(-viewDepth / _DepthRange));
                half3 waterColor = lerp(_DeepColor, _ShallowColor, waterDepth);
                // 通过菲尼尔系数实现远处水面反射的颜色
                waterColor = lerp(waterColor, _FresnelColor, saturate( pow(fresnel,  _FresnelRange)));

                // 水的流动Noise
                half2 waterDir = half2(_WaterDix_X, _WaterDix_Z) * _WaterSpeed * _Time.y;
                half2 worldUV_A = positionWS.xz * _Tilling + waterDir;
                half4 normalMap_A = SAMPLE_TEXTURE2D(_SurFaceNormal, sampler_SurFaceNormal, worldUV_A);
                half3 normalTS_A = UnpackNormal(normalMap_A);
                half2 worldUV_B = positionWS.xz * _Tilling * 2 + waterDir * -0.5;
                half4 normalMap_B = SAMPLE_TEXTURE2D(_SurFaceNormal, sampler_SurFaceNormal, worldUV_B);
                half3 normalTS_B = UnpackNormal(normalMap_B);
                // 法线混合
                half3 normalTS = BlendNormal(normalTS_A, normalTS_B);
                half3x3 tbn = half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);
                half3 normalWS = NormalizeNormalPerPixel(mul(normalTS, tbn));
                

                // Env
                

                half3 normal_Env = lerp(half3(0,0,1), normalWS, _EnvNoiseIntensity * 0.1);
                float3 R = reflect(-V,normal_Env);
                half3 indirectSpecular = 0;
                {
                    half4 envMap = SAMPLE_TEXTURECUBE_LOD(_EnvMap, sampler_EnvMap, R, 0);
                    indirectSpecular = DecodeHDREnvironment(envMap, _EnvMap_HDR);
                    
                    // 使用unity自带的cubumap
                    half mip = PerceptualRoughnessToMipmapLevel(1 - _Smoothness);
                    half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, R, mip);
                    indirectSpecular = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
                    // half roughness2 = max(PerceptualRoughnessToRoughness(1 - _Smoothness), HALF_MIN_SQRT);
                    // float surfaceReduction = 1.0 / (roughness2 + 1.0);
                    // indirectSpecular = surfaceReduction * indirectSpecular * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);
                }

                #if defined _PLANARREFLECTION_ON
                    screenUV = lerp(screenUV, screenUV + normalTS.xyz, _PlanarReflectionIntensity * 0.1);
                    half4 planeReflectionMap = SAMPLE_TEXTURE2D(_PlanarReflectionTexture, sampler_PlanarReflectionTexture,screenUV);
                    indirectSpecular = planeReflectionMap.rgb;
                    // return planeReflectionMap;
                #endif
                
                indirectSpecular *= saturate(pow(fresnel,  _FresnelPow) *  _FresnelIntensity);
                

                // 折射扭曲强度
                half2 distor = _UnderWaterDistort * normalWS.xy * 0.01;
                half3 opaqueTex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV + distor);

                
                // 深度重建观察空间坐标，实现焦散
                float4 depthVS = 1;
                depthVS.xy = i.positionVS.xy * sceneDepth / -i.positionVS.z;
                depthVS.z = sceneDepth;
                float3 depthWS = mul(unity_CameraToWorld,depthVS).rgb;
                half causticMask = saturate(exp(-viewDepth / _CausticRange));
                
                half2 caustic_uv = depthWS.xz * _CausticTilling + depthWS.y * 0.2;
                half3 causticMap01 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, caustic_uv + waterDir);
                half3 causticMap02 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, -caustic_uv + waterDir);
                half3 causticMap = min(causticMap01, causticMap02) * _CausticIntensity * causticMask;
                half3 underWaterColor = causticMap + opaqueTex;

                // Shore : 岸边
                half shoreRange = saturate(exp(-viewDepth / _ShoreRange));
                half shoreWidth = smoothstep(_ShoreEdgeWidth, 1.1, shoreRange) * _ShoreEdgeIntensity;
                half3 shoreColor = _ShoreColor * opaqueTex;

                // Foam
                half foamRange = 1 - saturate(viewDepth / _FoamRange);
                half foamSpeed = -_FoamSpeed * _Time.y;
                // Sin波形
                half foamSin = saturate(sin(foamSpeed + foamRange * _FoamFrequency));
                half foamNoiseMap = SAMPLE_TEXTURE2D(_FoamNoiseMap, sampler_FoamNoiseMap, worldUV * _FoamNoiseTlling * 0.1).r;
                half foamNoise = foamSin - foamNoiseMap;
                
                foamNoise = foamNoise - _FoamNoiseDissolve + foamRange;
                foamNoise = step(foamRange/_FoamShape, foamNoise)  * foamRange;
                half3 foamColor = _FoamColor.rgb * foamNoise;
                
                waterColor = waterColor + indirectSpecular  + WaveColor.rgb;
                half3 color = lerp(waterColor, underWaterColor, waterDepth);
                color = lerp(color, shoreColor, shoreRange);
                color = lerp(color, color + foamColor, _FoamIntensity) + shoreWidth;
                color = saturate(color);
                color = MixFog(color, i.fogCoord);
                return half4(color,1);
            }
            ENDHLSL
        }
    }
}

