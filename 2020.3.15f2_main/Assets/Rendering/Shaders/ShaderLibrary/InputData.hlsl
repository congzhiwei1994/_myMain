#ifndef JEFFORD_INPUT_INCLUDED
  #define JEFFORD_INPUT_INCLUDED

  CBUFFER_START(UnityPerMaterial)




  half4 _BaseColor;
  float4 _BaseMap_ST;
  half _OcclusionStrength;
  half _Smoothness;
  half _Metallic;
  half _BumpScale;

  // 布料
  half4 _SheenColor;
  half _GGXAnisotropy;
  half4 _ClothSpecColor;

  // 透射
  #if defined(_SCATTERING_ON)
    half4 _TranslucencyColor;
    half _TranslucencyPower;
    half _ThicknessStrength;
    half _ShadowStrength;
    half _Distortion;
  #endif

  // 环境光
  half4 _ClothCubeMap_HDR;
  half _ClothCubeIntensity;
  CBUFFER_END

  TEXTURE2D (_MaskMap);           SAMPLER(sampler_MaskMap);
  TEXTURECUBE(_ClothCubeMap);       SAMPLER(sampler_ClothCubeMap);
  TEXTURECUBE(_CubeMap);            SAMPLER(sampler_CubeMap);

  TEXTURE2D(_MetallicMap);          SAMPLER(sampler_MetallicMap);
  TEXTURE2D(_RoughnessMap);         SAMPLER(sampler_RoughnessMap);
  TEXTURE2D(_AOMap);                SAMPLER(sampler_AOMap);
  TEXTURE2D(_NormalMap);            SAMPLER(sampler_NormalMap);
  TEXTURE2D(_ClothMaskMap);          SAMPLER(sampler_ClothMaskMap);
  


  struct AdditionalData 
  {
    half3   tangentWS;
    half3   bitangentWS;
    float   partLambdaV;
    half    roughnessT;
    half    roughnessB;
    half3   anisoReflectionNormal;
    half3   sheenColor;
  };

  struct TextureData
  {
    half3 albedo;
    half3 normal;
    half3 specular;
    half smoothness;
    half metallic;
    half occlusion;
    half alpha;
    half4 maskMap;
  };

  struct VectorData
  {
    float3x3 tbn;
    float3 normalWS;
    float3 viewDirWS;
  };


  
#endif