#ifndef JEFFORD_CLOTH_INCLUDED
  #define JEFFORD_CLOTH_INCLUDED

  
  #include"InputData.hlsl"

  
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
  real V_Ashikhmin_Lux(real NdotL, real NdotV)
  {
    // Use soft visibility term introduce in: Crafting a Next-Gen Material Pipeline for The Order : 1886
    return 1.0 / (4.0 * (NdotL + NdotV - NdotL * NdotV));
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


  half3 DirectBDRF_LuxCloth(BRDFData brdfData, Light light, AdditionalData addData, half3 normalWS, half3 viewDirectionWS)
  {

    half3 lightDirectionWS = light.direction;
    half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;
    half3 lightColor = light.color;
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);


    float3 halfDir = SafeNormalize(lightDirectionWS + viewDirectionWS);

    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));
    half NdotV = saturate(dot(normalWS, viewDirectionWS ));

    #if defined(_COTTONWOOL_ON)

      //  NOTE: We use the noPI version here!!!!!!
      float D = D_CharlieNoPI_Lux(NoH, brdfData.roughness);
      //  Unity: V_Charlie is expensive, use approx with V_Ashikhmin instead
      //  Unity: float Vis = V_Charlie(NdotL, NdotV, bsdfData.roughness);
      float Vis = V_Ashikhmin_Lux(NdotL, NdotV);

      //  Unity: Fabrics are dieletric but we simulate forward scattering effect with colored specular (fuzz tint term)
      //  Unity: We don't use Fresnel term for CharlieD
      //  SheenColor seemed way too dark (compared to HDRP) – so i multiply it with PI which looked ok and somehow matched HDRP
      //  Therefore we use the noPI charlie version. As PI is a constant factor the artists can tweak the look by adjusting the sheen color.
      float3 F = addData.sheenColor; // * PI;
      half3 specularLighting = F * Vis * D;
      
      //  Unity: Note: diffuseLighting originally is multiply by color in PostEvaluateBSDF
      //  So we do it here :)
      //  Using saturate to get rid of artifacts around the borders.
      half3 specularTerm = saturate(specularLighting) + brdfData.diffuse * FabricLambert_Lux(brdfData.roughness);
      return specularTerm * radiance;
      
    #else
      float TdotH = dot(addData.tangentWS, halfDir);
      float TdotL = dot(addData.tangentWS, lightDirectionWS);
      float BdotH = dot(addData.bitangentWS, halfDir);
      float BdotL = dot(addData.bitangentWS, lightDirectionWS);

      float3 F = F_Schlick(brdfData.specular, LoH);
      //float TdotV = dot(addData.tangentWS, viewDirectionWS);
      //float BdotV = dot(addData.bitangentWS, viewDirectionWS);
      float DV = DV_SmithJointGGXAniso( TdotH, BdotH, NoH, NdotV, TdotL, BdotL, NdotL,addData.roughnessT, addData.roughnessB, addData.partLambdaV);
      // Check NdotL gets factores in outside as well.. correct?
      half3 specularLighting = F * DV;
      half3 specularTerm = specularLighting + brdfData.diffuse;
      return specularTerm * radiance;
    #endif

  }

  #if defined(_SCATTERING_ON)
    half3 TranslucencyColor(Light light, half thickness, half3 normalWS, half3 viewDirWS)
    {
      // 主灯阴影衰减
      half mainLightShadowAtten = lerp(1, light.shadowAttenuation, _ShadowStrength);
      half atten = light.distanceAttenuation * mainLightShadowAtten;
      half NoL = saturate(dot(normalWS, light.direction));
      // 进行法线方向扭曲
      half transLightDir = light.direction + normalWS * _Distortion;
      half LoV = saturate(dot(transLightDir, -viewDirWS));
      // 压暗暗部，逐渐缩小透射区域
      LoV = exp2(LoV * _TranslucencyPower - _TranslucencyPower);
      LoV = LoV * (1 - NoL);
      half3 translucencyColor = LoV * light.color * atten * thickness * 4 * _TranslucencyColor.rgb;
      return translucencyColor;
    }
  #endif


  void CustormBRDFData(out BRDFData brdfData,TextureData texData)
  {
    // BRDF反射率计算
    // BRDFData brdfData;
    ZERO_INITIALIZE(BRDFData, brdfData);
    half reflectivity = ReflectivitySpecular(texData.specular);
    half oneMinusReflectivity = 1.0 - reflectivity;
    half3 brdfDiffuse = texData.albedo * (half3(1.0h, 1.0h, 1.0h) - texData.specular);
    half3 brdfSpecular = texData.specular;

    InitializeBRDFDataDirect(brdfDiffuse, brdfSpecular, reflectivity, oneMinusReflectivity, texData.smoothness, texData.alpha, brdfData);
    // 不需要计算反射率
    brdfData.diffuse = texData.albedo;
    brdfData.specular = texData.specular;
  }
  

  void GGX_ClothData(inout AdditionalData addData, inout BRDFData brdfData, out half3 normalWS, VectorData vectorData,  TextureData texData)
  {
    #if defined(_COTTONWOOL_ON)
      normalWS = vectorData.tbn[2];
      half3 tangentWS = half3(0, 0, 0);
      half3 bitangentWS = half3(0, 0, 0);
      texData.smoothness = lerp(0.0h, 0.6h, texData.smoothness);
    #else
      half3 tangentWS = vectorData.tbn[0];
      half3 bitangentWS = vectorData.tbn[1];
      normalWS = vectorData.normalWS;
    #endif

    CustormBRDFData(brdfData, texData);

    ZERO_INITIALIZE(AdditionalData, addData);
    addData.bitangentWS = normalize(-cross(normalWS, tangentWS));
    addData.tangentWS = cross(normalWS, addData.bitangentWS);
    addData.roughnessT = brdfData.roughness * (1 + _GGXAnisotropy);
    addData.roughnessB = brdfData.roughness * (1 - _GGXAnisotropy);


    #if defined(_COTTONWOOL_ON)
      //  partLambdaV should be 0.0f in case of cotton wool
      addData.partLambdaV = 0.0h;
      addData.anisoReflectionNormal = normalWS;
      half NoV = dot(normalWS, vectorData.viewDirWS);
    #else
      half ToV = dot(tangentWS, vectorData.viewDirWS);
      half BoV = dot(bitangentWS, vectorData.viewDirWS);
      half NoV = dot(normalWS, vectorData.viewDirWS);
      addData.partLambdaV = GetSmithJointGGXAnisoPartLambdaV(ToV, BoV, NoV, addData.roughnessT, addData.roughnessB);
      //  Set reflection normal and roughness – derived from GetGGXAnisotropicModifiedNormalAndRoughness
      half3 grainDirWS = (_GGXAnisotropy >= 0.0) ? bitangentWS : tangentWS;
      half stretch = abs(_GGXAnisotropy) * saturate(1.5h * sqrt(brdfData.perceptualRoughness));
      addData.anisoReflectionNormal = GetAnisotropicModifiedNormal(grainDirWS, normalWS, vectorData.viewDirWS, stretch);
      half iblPerceptualRoughness = brdfData.perceptualRoughness * saturate(1.2 - abs(_GGXAnisotropy));
      //  Overwrite perceptual roughness for ambient specular reflections
      brdfData.perceptualRoughness = iblPerceptualRoughness;
    #endif
    addData.sheenColor = _SheenColor.rgb;
  }


  half3 ClothIndirect(Light mainLight,half3 sh, half3 normalWS, TextureData texData, BRDFData brdfData, AdditionalData addData, VectorData vectorData)
  {
    half NoL = max(0.001, dot(normalWS, mainLight.direction));
    half3 indirectDiffuse = sh * texData.occlusion * brdfData.diffuse;
    
    half3 indirectSpecular;
    {
      half3 reflectVector = reflect(-vectorData.viewDirWS, addData.anisoReflectionNormal);
      half NdotV = saturate(dot(addData.anisoReflectionNormal, vectorData.viewDirWS));
      half fresnelTerm = Pow4(1.0 - NdotV);
      
      half mip = PerceptualRoughnessToMipmapLevel(brdfData.perceptualRoughness);
      half4 envCubeMap = SAMPLE_TEXTURECUBE_LOD(_ClothCubeMap, sampler_ClothCubeMap, reflectVector, mip);
      
      half3 ibl = DecodeHDREnvironment(envCubeMap, _ClothCubeMap_HDR) * texData.occlusion * _ClothCubeIntensity;
      float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
      surfaceReduction = surfaceReduction * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);
      indirectSpecular = ibl * surfaceReduction;
    }

    half3 indirect = indirectDiffuse + indirectSpecular  * NoL;
    return indirect;
  }

#endif