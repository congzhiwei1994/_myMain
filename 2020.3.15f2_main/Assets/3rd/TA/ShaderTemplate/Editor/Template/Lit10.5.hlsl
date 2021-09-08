#ifndef CUSTORM_LIT_INCLUDED
    #define CUSTORM_LIT_INCLUDED

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

    // -------------------------------------------------------------------------------------------------------
    //                                               Lightmap相关
    // -------------------------------------------------------------------------------------------------------

    // 
    void SampleDirectionalLightmap1(TEXTURE2D_LIGHTMAP_PARAM(lightmapTex, lightmapSampler), TEXTURE2D_LIGHTMAP_PARAM(lightmapDirTex, lightmapDirSampler), LIGHTMAP_EXTRA_ARGS, float4 transform,
    float3 normalWS, float3 backNormalWS, bool encodedLightmap, real4 decodeInstructions, inout real3 bakeDiffuseLighting, inout real3 backBakeDiffuseLighting)
    {
        // In directional mode Enlighten bakes dominant light direction
        // in a way, that using it for half Lambert and then dividing by a "rebalancing coefficient"
        // gives a result close to plain diffuse response lightmaps, but normalmapped.

        // Note that dir is not unit length on purpose. Its length is "directionality", like
        // for the directional specular lightmaps.

        // transform is scale and bias
        uv = uv * transform.xy + transform.zw;

        real4 direction = SAMPLE_TEXTURE2D_LIGHTMAP(lightmapDirTex, lightmapDirSampler, LIGHTMAP_EXTRA_ARGS_USE);
        // Remark: baked lightmap is RGBM for now, dynamic lightmap is RGB9E5
        real3 illuminance = real3(0.0, 0.0, 0.0);
        if (encodedLightmap)
        {
            real4 encodedIlluminance = SAMPLE_TEXTURE2D_LIGHTMAP(lightmapTex, lightmapSampler, LIGHTMAP_EXTRA_ARGS_USE).rgba;
            illuminance = DecodeLightmap(encodedIlluminance, decodeInstructions);
        }
        else
        {
            illuminance = SAMPLE_TEXTURE2D_LIGHTMAP(lightmapTex, lightmapSampler, LIGHTMAP_EXTRA_ARGS_USE).rgb;
        }
        

        real halfLambert = dot(normalWS, direction.xyz - 0.5) + 0.5;
        bakeDiffuseLighting += illuminance * halfLambert / max(1e-4, direction.w);
        // bakeDiffuseLighting = illuminance;

        real backHalfLambert = dot(backNormalWS, direction.xyz - 0.5) + 0.5;
        backBakeDiffuseLighting += illuminance * backHalfLambert / max(1e-4, direction.w);
    }

    // Just a shortcut that call function above
    real3 SampleDirectionalLightmap1(TEXTURE2D_LIGHTMAP_PARAM(lightmapTex, lightmapSampler), TEXTURE2D_LIGHTMAP_PARAM(lightmapDirTex, lightmapDirSampler), LIGHTMAP_EXTRA_ARGS, float4 transform,
    float3 normalWS, bool encodedLightmap, real4 decodeInstructions)
    {
        float3 backNormalWSUnused = 0.0;
        real3 bakeDiffuseLighting = 0.0;
        real3 backBakeDiffuseLightingUnused = 0.0;
        SampleDirectionalLightmap1(TEXTURE2D_LIGHTMAP_ARGS(lightmapTex, lightmapSampler), TEXTURE2D_LIGHTMAP_ARGS(lightmapDirTex, lightmapDirSampler), LIGHTMAP_EXTRA_ARGS_USE, transform,
        normalWS, backNormalWSUnused, encodedLightmap, decodeInstructions, bakeDiffuseLighting, backBakeDiffuseLightingUnused);

        return bakeDiffuseLighting;
    }
    


    // Sample baked lightmap. Non-Direction and Directional if available.
    // Realtime GI is not supported.
    half3 SampleLightmap1(float2 lightmapUV, half3 normalWS)
    {
        #ifdef UNITY_LIGHTMAP_FULL_HDR
            bool encodedLightmap = false;
        #else
            bool encodedLightmap = true;
        #endif

        half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);

        // The shader library sample lightmap functions transform the lightmap uv coords to apply bias and scale.
        // However, universal pipeline already transformed those coords in vertex. We pass half4(1, 1, 0, 0) and
        // the compiler will optimize the transform away.
        half4 transformCoords = half4(1, 1, 0, 0);

        // 采样LightMap，必须是定向光模式
        #if defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_COMBINED)
            return SampleDirectionalLightmap1(TEXTURE2D_LIGHTMAP_ARGS(LIGHTMAP_NAME, LIGHTMAP_SAMPLER_NAME),
            TEXTURE2D_LIGHTMAP_ARGS(LIGHTMAP_INDIRECTION_NAME, LIGHTMAP_SAMPLER_NAME),
            LIGHTMAP_SAMPLE_EXTRA_ARGS, transformCoords, normalWS, encodedLightmap, decodeInstructions);

        #elif defined(LIGHTMAP_ON)
            return SampleSingleLightmap(TEXTURE2D_LIGHTMAP_ARGS(LIGHTMAP_NAME, LIGHTMAP_SAMPLER_NAME), LIGHTMAP_SAMPLE_EXTRA_ARGS, transformCoords, encodedLightmap, decodeInstructions);
        #else
            return half3(0.0, 0.0, 0.0);
        #endif
    }

    
    half3 SubtractDirectMainLightFromLightmap1(Light mainLight, half3 normalWS, half3 bakedGI)
    {
        // Let's try to make realtime shadows work on a surface, which already contains
        // baked lighting and shadowing from the main sun light.
        // Summary:
        // 1) Calculate possible value in the shadow by subtracting estimated light contribution from the places occluded by realtime shadow:
        //      a) preserves other baked lights and light bounces
        //      b) eliminates shadows on the geometry facing away from the light
        // 2) Clamp against user defined ShadowColor.
        // 3) Pick original lightmap value, if it is the darkest one.


        // 1) Gives good estimate of illumination as if light would've been shadowed during the bake.
        // We only subtract the main direction light. This is accounted in the contribution term below.
        half shadowStrength = GetMainLightShadowStrength();
        half contributionTerm = saturate(dot(mainLight.direction, normalWS));
        half3 lambert = mainLight.color * contributionTerm;
        half3 estimatedLightContributionMaskedByInverseOfShadow = lambert * (1.0 - mainLight.shadowAttenuation);
        half3 subtractedLightmap = bakedGI - estimatedLightContributionMaskedByInverseOfShadow;

        // 2) Allows user to define overall ambient of the scene and control situation when realtime shadow becomes too dark.
        half3 realtimeShadow = max(subtractedLightmap, _SubtractiveShadowColor.xyz);
        realtimeShadow = lerp(bakedGI, realtimeShadow, shadowStrength);

        // 3) Pick darkest color
        return min(bakedGI, realtimeShadow);
    }



    // We either sample GI from baked lightmap or from probes.
    // If lightmap: sampleData.xy = lightmapUV
    // If probe: sampleData.xyz = L2 SH terms
    #if defined(LIGHTMAP_ON)
        #define SAMPLE_GI1(lmName, shName, normalWSName) SampleLightmap1(lmName, normalWSName)
    #else
        #define SAMPLE_GI1(lmName, shName, normalWSName) SampleSHPixel(shName, normalWSName)
    #endif


    // -------------------------------------------------------------------------------------------------------

    // -------------------------------------------------------------------------------------------------------

    // Computes the scalar specular term for Minimalist CookTorrance BRDF
    // NOTE: needs to be multiplied with reflectance f0, i.e. specular color to complete
    half DirectBRDFSpecular1(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
    {
        float3 halfDir = SafeNormalize(float3(lightDirectionWS) + float3(viewDirectionWS));

        float NoH = saturate(dot(normalWS, halfDir));
        half LoH = saturate(dot(lightDirectionWS, halfDir));

        // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
        // BRDFspec = (D * V * F) / 4.0
        // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
        // V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
        // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
        // https://community.arm.com/events/1155

        // Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
        // We further optimize a few light invariant terms
        // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
        float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;

        half LoH2 = LoH * LoH;
        half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);

        // On platforms where half actually means something, the denominator has a risk of overflow
        // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
        // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
        #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
            specularTerm = specularTerm - HALF_MIN;
            specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
        #endif

        return specularTerm;
    }

    
    
    half3 LightingPhysicallyBased1(BRDFData brdfData, BRDFData brdfDataClearCoat,half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS,half clearCoatMask, bool specularHighlightsOff)
    {
        half NdotL = saturate(dot(normalWS, lightDirectionWS));
        half3 radiance = lightColor * (lightAttenuation * NdotL);
        // return NdotL;

        half3 brdf = brdfData.diffuse;
        #ifndef _SPECULARHIGHLIGHTS_OFF
            [branch] if (!specularHighlightsOff)
            {
                brdf += brdfData.specular * DirectBRDFSpecular1(brdfData, normalWS, lightDirectionWS, viewDirectionWS);

                #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
                    // Clear coat evaluates the specular a second timw and has some common terms with the base specular.
                    // We rely on the compiler to merge these and compute them only once.
                    half brdfCoat = kDielectricSpec.r * DirectBRDFSpecular1(brdfDataClearCoat, normalWS, lightDirectionWS, viewDirectionWS);

                    // Mix clear coat and base layer using khronos glTF recommended formula
                    // https://github.com/KhronosGroup/glTF/blob/master/extensions/2.0/Khronos/KHR_materials_clearcoat/README.md
                    // Use NoV for direct too instead of LoH as an optimization (NoV is light invariant).
                    half NoV = saturate(dot(normalWS, viewDirectionWS));
                    // Use slightly simpler fresnelTerm (Pow4 vs Pow5) as a small optimization.
                    // It is matching fresnel used in the GI/Env, so should produce a consistent clear coat blend (env vs. direct)
                    half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);

                    brdf = brdf * (1.0 - clearCoatMask * coatFresnel) + brdfCoat * clearCoatMask;
                #endif // _CLEARCOAT
            }
        #endif // _SPECULARHIGHLIGHTS_OFF

        return brdf * radiance;
    }

    half3 LightingPhysicallyBased1(BRDFData brdfData, BRDFData brdfDataClearCoat, Light light, half3 normalWS, half3 viewDirectionWS, half clearCoatMask, bool specularHighlightsOff)
    {
        return LightingPhysicallyBased1(brdfData, brdfDataClearCoat, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, clearCoatMask, specularHighlightsOff);
    }


    half3 EnvironmentBRDF1(BRDFData brdfData, half3 indirectDiffuse, half3 indirectSpecular, half fresnelTerm)
    {
        half3 c = indirectDiffuse * brdfData.diffuse;
        c += indirectSpecular * EnvironmentBRDFSpecular(brdfData, fresnelTerm);
        return c;
    }


    half3 GlobalIllumination1(BRDFData brdfData, BRDFData brdfDataClearCoat, float clearCoatMask,half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS)
    {
        half3 reflectVector = reflect(-viewDirectionWS, normalWS);
        half NoV = saturate(dot(normalWS, viewDirectionWS));
        half fresnelTerm = Pow4(1.0 - NoV);

        half3 indirectDiffuse = bakedGI * occlusion;
        half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion);

        half3 color = EnvironmentBRDF1(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);

        #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
            half3 coatIndirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfDataClearCoat.perceptualRoughness, occlusion);
            // TODO: "grazing term" causes problems on full roughness
            half3 coatColor = EnvironmentBRDFClearCoat(brdfDataClearCoat, clearCoatMask, coatIndirectSpecular, fresnelTerm);

            // Blend with base layer using khronos glTF recommended way using NoV
            // Smooth surface & "ambiguous" lighting
            // NOTE: fresnelTerm (above) is pow4 instead of pow5, but should be ok as blend weight.
            half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * fresnelTerm;
            return color * (1.0 - coatFresnel * clearCoatMask) + coatColor;
        #else
            return color;
        #endif
    }

    // Backwards compatiblity
    half3 GlobalIllumination1(BRDFData brdfData, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS)
    {
        const BRDFData noClearCoat = (BRDFData)0;
        return GlobalIllumination1(brdfData, noClearCoat, 0.0, bakedGI, occlusion, normalWS, viewDirectionWS);
    }


    void MixRealtimeAndBakedGI1(inout Light light, half3 normalWS, inout half3 bakedGI)
    {
        #if defined(LIGHTMAP_ON) && defined(_MIXED_LIGHTING_SUBTRACTIVE)
            bakedGI = SubtractDirectMainLightFromLightmap1(light, normalWS, bakedGI);
        #endif
    }

    // Backwards compatiblity
    void MixRealtimeAndBakedGI1(inout Light light, half3 normalWS, inout half3 bakedGI, half4 shadowMask)
    {
        MixRealtimeAndBakedGI1(light, normalWS, bakedGI);
    }


    half4 UniversalFragmentPBR1(InputData inputData, SurfaceData surfaceData)
    {
        #ifdef _SPECULARHIGHLIGHTS_OFF
            bool specularHighlightsOff = true;
        #else
            bool specularHighlightsOff = false;
        #endif

        BRDFData brdfData;

        // NOTE: can modify alpha
        InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

        BRDFData brdfDataClearCoat = (BRDFData)0;
        #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
            // base brdfData is modified here, rely on the compiler to eliminate dead computation by InitializeBRDFData()
            InitializeBRDFDataClearCoat(surfaceData.clearCoatMask, surfaceData.clearCoatSmoothness, brdfData, brdfDataClearCoat);
        #endif

        // To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
        #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
            half4 shadowMask = inputData.shadowMask;
        #elif !defined (LIGHTMAP_ON)
            half4 shadowMask = unity_ProbesOcclusion;
        #else
            half4 shadowMask = half4(1, 1, 1, 1);
        #endif

        Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);

        #if defined(_SCREEN_SPACE_OCCLUSION)
            AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
            mainLight.color *= aoFactor.directAmbientOcclusion;
            surfaceData.occlusion = min(surfaceData.occlusion, aoFactor.indirectAmbientOcclusion);
        #endif

        MixRealtimeAndBakedGI1(mainLight, inputData.normalWS, inputData.bakedGI);
        // return half4( inputData.bakedGI,1);

        half3 color = GlobalIllumination1(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask, inputData.bakedGI, surfaceData.occlusion, inputData.normalWS, inputData.viewDirectionWS);

        half3 directColor = LightingPhysicallyBased1(brdfData, brdfDataClearCoat, mainLight, inputData.normalWS, inputData.viewDirectionWS, surfaceData.clearCoatMask, specularHighlightsOff);

        // return half4(directColor,1);

        color += directColor;

        #ifdef _ADDITIONAL_LIGHTS
            uint pixelLightCount = GetAdditionalLightsCount();
            for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
            {
                Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
                #if defined(_SCREEN_SPACE_OCCLUSION)
                    light.color *= aoFactor.directAmbientOcclusion;
                #endif
                color += LightingPhysicallyBased1(brdfData, brdfDataClearCoat,
                light,
                inputData.normalWS, inputData.viewDirectionWS,
                surfaceData.clearCoatMask, specularHighlightsOff);
            }
        #endif

        #ifdef _ADDITIONAL_LIGHTS_VERTEX
            color += inputData.vertexLighting * brdfData.diffuse;
        #endif

        color += surfaceData.emission;

        return half4(color, surfaceData.alpha);
    }

    half4 UniversalFragmentPBR1(InputData inputData, half3 albedo, half metallic, half3 specular,
    half smoothness, half occlusion, half3 emission, half alpha)
    {
        SurfaceData s;
        s.albedo              = albedo;
        s.metallic            = metallic;
        s.specular            = specular;
        s.smoothness          = smoothness;
        s.occlusion           = occlusion;
        s.emission            = emission;
        s.alpha               = alpha;
        s.clearCoatMask       = 0.0;
        s.clearCoatSmoothness = 1.0;
        return UniversalFragmentPBR1(inputData, s);
    }
#endif