#ifndef CLOTH_SHEEN_LIGHTING_INCLUDED
    #define CLOTH_SHEEN_LIGHTING_INCLUDED


    struct DirectBDRFCloth
    {
        half3 tangentWS;
        half3 bitangentWS;
        half roughnessT;
        half roughnessB;
        half partLambdaV;
        half3 anisoReflectionNormal;
    };
    
    // Ref: https://knarkowicz.wordpress.com/2018/01/04/cloth-shading/
    real D_CharlieNoPI_Lux(real NdotH, real roughness)
    {
        float invR = rcp(roughness);
        float cos2h = NdotH * NdotH;
        float sin2h = 1.0 - cos2h;
        // Note: We have sin^2 so multiply by 0.5 to cancel it
        return (2.0 + invR) * PositivePow(sin2h, invR * 0.5) / 2.0;
    }

    real D_Charlie_Lux(real NdotH, real roughness)
    {
        return INV_PI * D_CharlieNoPI_Lux(NdotH, roughness);
    }

    // We use V_Ashikhmin instead of V_Charlie in practice for game due to the cost of V_Charlie
    real V_Ashikhmin_Lux(real NoL, real NdotV)
    {
        // Use soft visibility term introduce in: Crafting a Next-Gen Material Pipeline for The Order : 1886
        return 1.0 / (4.0 * (NoL + NdotV - NoL * NdotV));
    }

    // A diffuse term use with fabric done by tech artist - empirical
    real FabricLambertNoPI_Lux(real roughness)
    {
        return lerp(1.0, 0.5, roughness);
    }

    real FabricLambert_Lux(real roughness)
    {
        return INV_PI * FabricLambertNoPI_Lux(roughness);
    }


    inline void InitializeBRDFData_Sheen(half3 albedo, half metallic, half3 specular, half smoothness, out BRDFData outBRDFData)
    {
        half alpha = 1;
        half reflectivity = ReflectivitySpecular(specular);
        half oneMinusReflectivity = 1.0 - reflectivity;
        half3 brdfDiffuse = albedo;
        half3 brdfSpecular = specular;
        InitializeBRDFDataDirect(brdfDiffuse, brdfSpecular, reflectivity, oneMinusReflectivity, smoothness, alpha, outBRDFData);
    }

    half3 DirectBDRF_Cloth(BRDFData brdfData, DirectBDRFCloth directBdrfCloth,Light light,  half3 normalWS, half3 viewDir)
    {
        half3 direct_Cloth = 0;
        float3 lightDir = light.direction;
        half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;
        half3 lightColor = light.color;
        
        float3 halfDir = SafeNormalize(lightDir + viewDir);

        float NoL = saturate(dot(normalWS, lightDir));
        float NoH = saturate(dot(normalWS, halfDir));
        float LoH = saturate(dot(lightDir, halfDir));
        float NoV = saturate(dot(normalWS, viewDir));

        half3 radiance = lightColor * (lightAttenuation * NoL);
        
        #if  _COTTONWOOL_ON
            float D = D_CharlieNoPI_Lux(NoH, brdfData.roughness);
            float Vis = V_Ashikhmin_Lux(NoL, NoV);
            float3 F = _SheenColor*_SheenColorPower; // * PI;
            half3 specular_Cloth = saturate(F * Vis * D);
            half3 diffuse_Cloth = brdfData.diffuse * FabricLambert_Lux(brdfData.roughness);
            direct_Cloth = specular_Cloth + diffuse_Cloth;
            return direct_Cloth * radiance;
        #else
            
            half roughnessT = directBdrfCloth.roughnessT;
            half roughnessB = directBdrfCloth.roughnessB;
            half partLambdaV = directBdrfCloth.partLambdaV;
            float3 tangentWS = directBdrfCloth.tangentWS;
            float3 bitangentWS = directBdrfCloth.bitangentWS;

            float TdotH = dot( tangentWS, halfDir);
            float TdotL = dot( tangentWS, lightDir);
            float BdotH = dot( bitangentWS, halfDir);
            float BdotL = dot( bitangentWS, lightDir);

            float3 F = F_Schlick(brdfData.specular, LoH);
            float DV = DV_SmithJointGGXAniso(
            TdotH, BdotH, NoH, NoV, TdotL, BdotL, NoL,
            roughnessT,  roughnessB,  partLambdaV
            );
            // Check NoL gets factores in outside as well.. correct?
            half3 specular_Cloth = F * DV;
            direct_Cloth = specular_Cloth + brdfData.diffuse;
            return direct_Cloth * radiance;
        #endif 
        
    }



    half3 ClothSheenLighting( half3 albedo, half metallic, half3 specular, half smoothness, half3 viewDir,half3 normalWS,half3 tangentWS, Light light)
    {
        BRDFData brdfData;
        InitializeBRDFData_Sheen(albedo, metallic, specular, smoothness, brdfData);
        

        DirectBDRFCloth directBdrfCloth;
        ZERO_INITIALIZE(DirectBDRFCloth, directBdrfCloth);
        brdfData.diffuse = albedo;
        brdfData.specular = specular;
        directBdrfCloth.bitangentWS = normalize(-cross(normalWS,tangentWS.xyz)); 
        directBdrfCloth.tangentWS = normalize(cross(normalWS, directBdrfCloth.bitangentWS));
        directBdrfCloth.roughnessT = brdfData.roughness * (1 + _AnisDir_Colth );
        directBdrfCloth.roughnessB = brdfData.roughness * (1 - _AnisDir_Colth );

        directBdrfCloth.anisoReflectionNormal = 0;
        #if defined _COTTONWOOL_ON
            directBdrfCloth.partLambdaV = 0;
            directBdrfCloth.anisoReflectionNormal = normalWS;
        #else
            tangentWS = directBdrfCloth.tangentWS;
            float3 bitangentWS = directBdrfCloth.bitangentWS;
            half roughnessT = directBdrfCloth.roughnessT;
            half roughnessB = directBdrfCloth.roughnessB;
            
            float TdotV = dot(tangentWS, viewDir);
            float BdotV = dot(bitangentWS, viewDir);
            float NdotV = dot(normalWS, viewDir);
            directBdrfCloth.partLambdaV = GetSmithJointGGXAnisoPartLambdaV(TdotV, BdotV, NdotV, roughnessT, roughnessB);
            //  Set reflection normal and roughness – derived from GetGGXAnisotropicModifiedNormalAndRoughness
            half3 grainDirWS = (_AnisDir_Colth >= 0.0) ? bitangentWS : tangentWS;
            half stretch = abs(_AnisDir_Colth) * saturate(1.5h * sqrt(brdfData.perceptualRoughness));
            directBdrfCloth.anisoReflectionNormal = GetAnisotropicModifiedNormal(grainDirWS, normalWS, viewDir, stretch);
            half iblPerceptualRoughness = brdfData.perceptualRoughness * saturate(1.2 - abs(_AnisDir_Colth));
            brdfData.perceptualRoughness = iblPerceptualRoughness;
        #endif
        
        half3 directCloth = DirectBDRF_Cloth(brdfData, directBdrfCloth, light, normalWS, viewDir);

        half3 indirectSpecular;
        {
            normalWS = directBdrfCloth.anisoReflectionNormal;
            half3 R = reflect(-viewDir,normalWS);
            half mip = PerceptualRoughnessToMipmapLevel(brdfData.perceptualRoughness);
            half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDir)));
            float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
            
            half4 ibl = SAMPLE_TEXTURECUBE_LOD(_SPL, sampler_SPL, R, mip);
            ibl = Gamma22ToLinear(ibl) * _EnvColor;
            indirectSpecular = DecodeHDREnvironment(ibl,_SPL_HDR);
            indirectSpecular = surfaceReduction * indirectSpecular * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);
        }

        half3 c = directCloth + indirectSpecular;
        return c;
    }



#endif 