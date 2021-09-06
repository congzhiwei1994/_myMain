#ifndef JEFFORD_BASEPBR_INCLUDED
  #define JEFFORD_BASEPBR_INCLUDED


  float3 ACESFilm(float3 x)
  {
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x*(a*x + b))/(x*(c*x+d) + e));

  }

  
  half3 LightingPhysicallyBased1(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
  {
    half3 lightColor = light.color;
    half3 lightDirectionWS = light.direction;
    half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;

    half NdotL = saturate(dot(normalWS, lightDirectionWS)) * 0.8 + 0.2;
    half3 radiance = lightColor * (lightAttenuation * NdotL);

    half3 brdf = brdfData.diffuse;
    
    brdf += brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);

    return brdf * radiance;
  }
  

  half3 BasePBRIndirect(Light mainLight, half3 bakedGI, half3 normalWS, TextureData texData, BRDFData brdfData, VectorData vectorData)
  {
    half3 indirectDiffuse = bakedGI *  texData.occlusion * brdfData.diffuse;

    half3 reflectVector = reflect(-vectorData.viewDirWS, normalWS);
    half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, vectorData.viewDirWS)));

    half mip = PerceptualRoughnessToMipmapLevel(brdfData.perceptualRoughness);
    half4 cubeMap = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, reflectVector, mip);
    half3 ibl = DecodeHDREnvironment(cubeMap, unity_SpecCube0_HDR) *  texData.occlusion;

    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    half3 indirectSpecular = surfaceReduction * ibl * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);
    half3 indirect = indirectDiffuse + indirectSpecular;
    return indirect;
  }


  
#endif