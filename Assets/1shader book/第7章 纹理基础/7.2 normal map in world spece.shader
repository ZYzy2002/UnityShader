// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chapter7/7.2 normal map in world spece"
{
    Properties
    {
        _BaseColorTint("Color Tint", Color) = (1,1,1,1)
        _BaseColorMap("Base Color Map", 2D) = "white"{}

        _NormalMap("Normal Map", 2D) = "white"{}
        _NormalMapBumpScale("NormalMap Scale", Float) = 1.0

        _Specular("Specular Color", Color) = (1,1,1,1)
        _Gloss("Specular Gloss",Range(8.0,256.0)) = 20.0
    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            float4 _BaseColorTint;
            sampler2D _BaseColorMap;
            float4 _BaseColorMap_ST;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            float _NormalMapBumpScale;
            float4 _Specular;
            float _Gloss;

            struct a2f
            {
                float4 objVertexPos:POSITION;
                float4 vertexUV:TEXCOORD;                 //only use the xy for vertex uv;
                float3 objectNormal:NORMAL;
                float4 objectTangent:TANGENT;
            };
            struct v2f
            {
                float4 clipVertexPos:SV_POSITION;
                float4 uv:TEXCOORD0;                //xy for bc Map  zw for Normal Map
                float4 WorldVertexPos:TEXCOORD4;
                
                float4 tangentToWorld_Row1:TEXCOORD1;
                float4 tangentToWorld_Row2:TEXCOORD2;
                float4 tangentToWorld_Row3:TEXCOORD3;
            };

            v2f vert(a2f v)
            {
                v2f o;
                o.clipVertexPos = UnityObjectToClipPos( v.objVertexPos);
                o.WorldVertexPos = mul( unity_ObjectToWorld, v.objVertexPos);
                o.uv.xy = TRANSFORM_TEX(v.vertexUV, _BaseColorMap);
                o.uv.zw = TRANSFORM_TEX(v.vertexUV, _NormalMap);
                
                //calculate the matrix tangent To World
                float3 normalInWorld = normalize(mul(unity_WorldToObject, v.objectNormal));
                float3 tangentInWorld = normalize(mul(unity_ObjectToWorld, v.objectTangent));
                float3 binormalInWorld = normalize(cross( normalInWorld, tangentInWorld ) * v.objectTangent.w);     //objectTangent.w  保持坐标系手性正确，是1或-1 与平台有关，
                o.tangentToWorld_Row1 = float4(tangentInWorld.x, binormalInWorld.x, normalInWorld.x, 0);
                o.tangentToWorld_Row2 = float4(tangentInWorld.y, binormalInWorld.y, normalInWorld.y, 0);
                o.tangentToWorld_Row3 = float4(tangentInWorld.z, binormalInWorld.z, normalInWorld.z, 0);
                
                return o;
            }
            
            float4 frag(v2f f):SV_TARGET0
            {
                //ambient
                float4 ambientColor = UNITY_LIGHTMODEL_AMBIENT;

                //diffuse
                float4 albedo = tex2D(_BaseColorMap,f.uv.xy) * _BaseColorTint;
                float3 tangentNormalFromTex;
                tangentNormalFromTex.xy = (tex2D(_NormalMap, f.uv.zw) * 2 -float2(1, 1)) * _NormalMapBumpScale;
                tangentNormalFromTex.z = sqrt(1 - saturate(dot(tangentNormalFromTex.xy, tangentNormalFromTex.xy)));
                float4x4 tangentToWorld = 
                {
                    f.tangentToWorld_Row1, f.tangentToWorld_Row2, f.tangentToWorld_Row3, float4(0,0,0,1)
                };
                float3 worldNormal = normalize(mul((float3x3)tangentToWorld, tangentNormalFromTex));

                float4 diffuseColor = albedo * _LightColor0 * saturate( dot(worldNormal, UnityWorldSpaceLightDir(f.WorldVertexPos)) );

                //specular
                float3 viewDir = normalize(UnityWorldSpaceViewDir(f.WorldVertexPos));
                float3 halfVector = normalize(viewDir + UnityWorldSpaceLightDir(f.WorldVertexPos));
                float4 specularColor = _Specular * _LightColor0 * pow(saturate(dot(halfVector,worldNormal)),_Gloss);


                return ambientColor + diffuseColor + specularColor;
            }

            ENDCG
        }
    }
    FallBack "Specular"
}
