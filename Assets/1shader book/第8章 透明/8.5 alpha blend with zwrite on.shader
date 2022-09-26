// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chapter8/8.5 alpha blend with zwrite on"
{
    Properties
    {
        _ColorTint("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _AlphaScale("Alpha Scale",Range(0,2)) =1
    }
    SubShader
    {
        Tags{"Queue" = "Transparent" "IgnorPorjector" = "True" "RenderType"="Transparent"}

        Pass
        {
            ZWrite On
            ColorMask 0
        }
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            fixed4 _ColorTint;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _AlphaScale;

            struct a2f
            {
                float3 objPos:POSITION;
                fixed3 objectNormal:NORMAL;
                float4 texcoord:TEXCOORD0;
            };
            struct v2f
            {
                float4 clipPos:SV_POSITION; 
                float3 worldNormal:TEXCOORD0;
                float4 worldPos:TEXCOORD1;
                float2 uv:TEXCOORD2;
            };

            v2f vert(a2f v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.objPos);
                o.worldNormal = normalize(mul(unity_WorldToObject, v.objectNormal));
                o.worldPos = mul(unity_ObjectToWorld, v.objPos);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            float4 frag(v2f f):SV_TARGET0
            {
                fixed4 sampleFromTex = tex2D(_MainTex, f.uv);
                fixed3 albedo = sampleFromTex.xyz * _ColorTint.xyz;

                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT;

                fixed3 diffuseColor = albedo * _LightColor0 * saturate(dot(f.worldNormal, UnityWorldSpaceLightDir(f.worldPos)));

                return float4(ambientColor + diffuseColor, sampleFromTex.a * _AlphaScale);
            }
            ENDCG
        }
    }
}
