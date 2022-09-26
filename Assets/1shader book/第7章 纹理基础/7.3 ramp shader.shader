// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chapter7/7.3 ramp shader"
{
    Properties
    {
        _Color ("Base Color", Color) = (1,1,1,1)
        _RampTex ("Ramp Tex", 2D) = "white"{}
        _Specular ("_Specular Color", Color) = (1,1,1,1)
        _Gloss ("_Gloss Domain", Range(8.0, 256.0)) = 20
    }
    SubShader
    {
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            fixed4 _Color;
            sampler2D _RampTex;
            float4 _RampTex_ST;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 objPos:POSITION;
                float3 objNormal:NORMAL;
                float4 coord:TEXCOORD;
            };
            struct v2f
            {
                float4 clipPos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float4 worldPos:TEXCOORD1;
                float2 uv:TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.objPos);
                o.worldPos = mul(unity_ObjectToWorld, v.objPos);
                o.worldNormal = normalize(mul(unity_WorldToObject, v.objNormal));
                o.uv = TRANSFORM_TEX(v.coord.xy, _RampTex);
                return o;
            }

            float4 frag(v2f f): SV_TARGET
            {
                float4 ambientColor = UNITY_LIGHTMODEL_AMBIENT;

                float halfLambert = 0.5 * dot(f.worldNormal, UnityWorldSpaceLightDir(f.worldPos)) + 0.5;
                float4 diffuseColor = _LightColor0 * _Color * tex2D(_RampTex,float2(halfLambert, halfLambert)) *saturate(dot(f.worldNormal, UnityWorldSpaceLightDir(f.worldPos)) + 0.2);

                float3 halfVector = normalize(normalize(UnityWorldSpaceViewDir(f.worldPos)) + normalize(UnityWorldSpaceLightDir(f.worldPos)));
                float4 specularColor = _Specular * pow(saturate(dot(halfVector, f.worldNormal)), _Gloss);

                return ambientColor + diffuseColor + specularColor;
            }
            
            ENDCG
        }
    }
    FallBack "Specular"
}
