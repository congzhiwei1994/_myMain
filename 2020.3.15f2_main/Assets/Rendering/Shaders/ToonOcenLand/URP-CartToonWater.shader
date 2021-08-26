
Shader "Czw/URP/CartToonWater"
{
    Properties
    {
        [KeywordEnum(Foam,Noise,Caustic,Specular,Reflection,Depth,None)] _Debug("_Debug",int) = 0
        [Header(Water)]
        _WaterColor01("_WaterColor01",Color) = (1,1,1,1)
        _WaterColor02("_WaterColor02",Color) = (1,1,1,1)
        
        _Alpha("_Alpha",Range(0,1)) = 0.5
        _WaterVariable("Dir_X(X) Dir_Z(Y) Speed(Z) Depth(W)",vector) = (1,1,0.3,8)
        
        [Header(Foam)]
        _FoamColor("_FoamColor",Color) = (1,1,1,1)
        _FoamMap("_FoamMap", 2D) = "white" {}
        _FoamRange("_FoamRange",Range(0,20)) = 1
        _FoamPow("_FoamPow",float) = 1
        _FoamIntensity("_FoamIntensity",float) = 1

        [Header(Noise)]
        _NoiseIntensity("_NoiseIntensity", Range(0,1)) = 1.0
        _NoiseBumpMap("_NoiseBumpMap", 2D) = "bump" {}
        _NormalScale("_NormalScale",Range(0,3)) = 1

        [Header(Caustic)]
        _CausticMap("_CausticMap",2D) = "white"{}
        _CausticIntensity("_CausticIntensity",Range(0,1)) = 0.5

        [Header(Specular)]
        _Specular("Specular",Color) = (1,1,1,1)
        [PowerSlider(2)]_SpecularPow("_SpecularPow",Range(0,1)) = 1
        _SpecularIntensity("_SpecularIntensity",Range(0,2)) = 1

        [Header(Reflection)]
        _ReflectionMap("_ReflectionMap",Cube) = "white" {}
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            // Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #pragma shader_feature _DEBUG_NOISE _DEBUG_FOAM  _DEBUG_CAUSTIC _DEBUG_SPECULAR _DEBUG_REFLECTION _DEBUG_NONE _DEBUG_DEPTH
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _WaterVariable;
            half4 _WaterColor01;
            half4 _WaterColor02;

            half _NormalScale;
            half _Alpha;
            half _FoamRange;
            
            float4 _FoamMap_ST;
            half4 _FoamColor;
            half _FoamPow;
            half _FoamIntensity;
            half _NoiseIntensity;
            half4 _NoiseBumpMap_ST;

            half4 _Specular;
            half _SpecularIntensity;
            half _SpecularPow;

            half4 _ReflectionMap_HDR;
            half2 _CausticMap_ST;

            half _CausticIntensity;
            
            CBUFFER_END

            TEXTURE2D(_WaterRamp);          SAMPLER(sampler_WaterRamp);
            TEXTURE2D(_CausticMap);          SAMPLER(sampler_CausticMap);
            TEXTURE2D(_FoamMap);             SAMPLER(sampler_FoamMap);
            TEXTURE2D(_NoiseBumpMap);        SAMPLER(sampler_NoiseBumpMap);

            TEXTURE2D(_CameraDepthTexture);  SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D(_CameraOpaqueTexture); SAMPLER(sampler_CameraOpaqueTexture);
            TEXTURECUBE(_ReflectionMap);     SAMPLER(sampler_ReflectionMap);


            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float3 normalOS      : NORMAL;
                float4 tangentOS     : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS               : SV_POSITION;
                float fogCoord                  : TEXCOORD1;
                float3 positionVS               : TEXCOORD2;
                float3 positionWS               : TEXCOORD3;
                float4 positionWS_UV            : TEXCOORD4;    //.xy:foamMap uv

                float4 normal                   : TEXCOORD5;    // xyz: normal, w: viewDir.x
                float4 tangent                  : TEXCOORD6;    // xyz: tangent, w: viewDir.y
                float4 bitangent                : TEXCOORD7;    // xyz: bitangent, w: viewDir.z
                half4 normalUV                  : TEXCOORD8;  
                half2 waterSpeed                 : TEXCOORD9;  //水流速度
            };



            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);

                half waterSpeed = _WaterVariable.z;
                o.waterSpeed = _Time.y * waterSpeed * _WaterVariable.xy;
                o.positionWS_UV.xy = o.positionWS.xz * _FoamMap_ST.xy + o.waterSpeed;
                //交叉流动
                o.normalUV.xy = o.positionWS.xz * _NoiseBumpMap_ST.xy + o.waterSpeed;
                o.normalUV.zw = o.positionWS.xz * _NoiseBumpMap_ST.xy + o.waterSpeed * float2(-0.8,1.3);

                o.positionVS = TransformWorldToView(o.positionWS.xyz);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);

                half sign = v.tangentOS.w * GetOddNegativeScale();
                half3 normalWS = TransformObjectToWorldNormal(v.normalOS);
                half3 tangentWS= TransformObjectToWorldDir(v.tangentOS.xyz);
                half3 bitangentWS = cross(normalWS,tangentWS) * sign;
                half3 viewDirWS = GetCameraPositionWS() - o.positionWS;

                o.normal = half4(normalWS, viewDirWS.x);
                o.tangent = half4(tangentWS, viewDirWS.y);
                o.bitangent = half4(bitangentWS, viewDirWS.z); 

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                

                // 变量
                half waterDepth = _WaterVariable.w;


                // ----------------------------------------- 深度 -----------------------------------------
                //深度图生成的是屏幕空间下的图片，需要用到屏幕空间下的坐标
                //齐次裁剪空间下的坐标，顶点着色器 =>片段着色器，会变成具体得到像素 除以总像素，每个像素（0~1）的值
                float2 screenUV = i.positionCS.xy/_ScreenParams.xy;
                
                half depthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,screenUV).r;
                half depthScene = LinearEyeDepth(depthTex,_ZBufferParams); //转换到(0~1)

                half depth = depthScene + i.positionVS.z;
                depth = saturate(depth * waterDepth);
                
                return depth;

                // half4 underRamp = SAMPLE_TEXTURE2D(_WaterRamp,sampler_WaterRamp,float2(depth,1)); 
                // half4 surfaceRamp= SAMPLE_TEXTURE2D(_WaterRamp,sampler_WaterRamp,float2(depth,0)); 

                // ----------------------------------------- 扭曲 -----------------------------------------
                
                half4 noiseNormalMap01 = SAMPLE_TEXTURE2D(_NoiseBumpMap, sampler_NoiseBumpMap,i.normalUV.xy);
                half4 noiseNormalMap02 = SAMPLE_TEXTURE2D(_NoiseBumpMap, sampler_NoiseBumpMap,i.normalUV.zw);
                half4 noiseNormalMap = noiseNormalMap01 * noiseNormalMap02;

                // half2 noiseUV = lerp(screenUV,noiseNormalMap.xy,_NoiseIntensity);
                half2 noiseUV = screenUV + noiseNormalMap.xy * _NoiseIntensity;

                half noiseTex = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,noiseUV).r;
                half noiseDepthScene = LinearEyeDepth(noiseTex,_ZBufferParams); //转换到(0~1)
                half noiseDepth = noiseDepthScene + i.positionVS.z;
                
                half2 noiseMapUV = noiseUV;
                if (noiseDepth<0)
                {
                    noiseMapUV = screenUV;
                }

                half noiseWater = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture,noiseMapUV).r; //屏幕抓帧

                // ----------------------------------------- 焦散 -----------------------------------------
                float4 depthVS = 1;
                depthVS.xy = i.positionVS.xy * noiseDepthScene/-i.positionVS.z;
                depthVS.z = noiseDepthScene;

                float3 depthWS = mul(unity_CameraToWorld,depthVS).rgb;

                half2 causticMap_UV01 = depthWS.xz * _CausticMap_ST.xy + depthWS.y * 0.2+ i.waterSpeed;
                half causticMap01 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap,causticMap_UV01).r;

                half2 causticMap_UV02 = depthWS.xz * _CausticMap_ST.xy + depthWS.y * 0.2 +  i.waterSpeed * float2(-0.8,1.2);
                half causticMap02 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap,causticMap_UV02).r;

                half causticMap = max(causticMap01, causticMap02);
                half caustic = causticMap * (1-depth);
                caustic = lerp(0,caustic,_CausticIntensity);


                // ----------------------------------------- 高光 -----------------------------------------
                Light mainLight = GetMainLight();
                float3 lightDir = mainLight.direction;
                float3 lightColor = mainLight.color;
                float3 viewDir = SafeNormalize(half3(i.normal.w, i.tangent.w, i.bitangent.w));

                half3 normapTS= UnpackNormalScale(noiseNormalMap,_NormalScale);
                half3x3 tbn = half3x3(i.tangent.xyz, i.bitangent.xyz, i.normal.xyz);
                half3 normalWS = NormalizeNormalPerPixel(TransformTangentToWorld(normapTS,tbn));

                float3 halfVec = SafeNormalize(lightDir + viewDir);
                half NdotH = saturate(dot(normalWS, halfVec));
                half specularPow = exp2(_SpecularPow * 10);
                half3 specular = lightColor.rgb * _Specular.rgb * pow(NdotH, specularPow) * _SpecularIntensity;

                // ----------------------------------------- 反射 -----------------------------------------
                half3 reflectVector = reflect(-viewDir, normalWS);
                half mip = PerceptualRoughnessToMipmapLevel(1 - _SpecularPow);
                half4 reflectionMap = SAMPLE_TEXTURECUBE_LOD(_ReflectionMap, sampler_ReflectionMap, reflectVector, mip);
                half3 ibl = DecodeHDREnvironment(reflectionMap, _ReflectionMap_HDR);
                half fresnel = 1 - saturate(dot(i.normal.xyz,viewDir));
                fresnel = pow(fresnel,1.5);

                half3 specularReflact = (specular + ibl) * fresnel;

                // ----------------------------------------- 泡沫 -----------------------------------------
                half formRange = (depth * _FoamRange);
                half foamMap = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap, i.positionWS_UV.xy).r;
                foamMap = pow(abs(foamMap),_FoamPow);

                half foamMask = step(formRange,foamMap); //卡通水泡沫的实现方式
                half4 foamColor = foamMask * _FoamColor * _FoamIntensity;
                foamColor += noiseWater;

                // -------------------------------------------------------------------------
                half4 waterColor = lerp(_WaterColor01,_WaterColor02,depth);
                waterColor.rgb *= lightColor;

                half3 c = waterColor * foamColor;
                c += specularReflact; 
                c += caustic;

                half4 Color = half4(c,_Alpha);

                // ----------------------------------------- Debug -----------------------------------------
                #if _DEBUG_DEPTH
                    return depth;
                #endif

                #if _DEBUG_NOISE
                    return noiseWater;
                #endif

                #if _DEBUG_FOAM
                    return foamColor;
                #endif

                #if _DEBUG_REFLECTION
                    return half4(ibl,1);
                #endif

                #if _DEBUG_SPECULAR
                    return half4(specular,1);
                #endif

                #if _DEBUG_CAUSTIC
                    return caustic;
                #endif

                #if _DEBUG_NONE
                    return Color;
                #endif

            }
            ENDHLSL
        }
    }
}

