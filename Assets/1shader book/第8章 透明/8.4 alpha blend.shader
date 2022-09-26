// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chapter8/8.4 alpha blend"
{
    Properties
    {
        _ColorTint("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex("Main Tex", 2D) = "White"{}
        _AlphaScale("Alpha Scale", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags{"Queue" = "Transparent" "IgnoreProjector" = "True" "RanderType" = "Transparent" }
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
                fixed3 objNormal:NORMAL;
                float4 uv:TEXCOORD0;
            };
            struct v2f
            {
                float4 clipPos:SV_POSITION;
                float4 worldPos:TEXCOORD0;
                fixed3 worldNormal:TEXCOORD1;
                float2 uv:TEXCOORD2;
            };

            v2f vert(a2f v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.objPos);
                o.worldPos = mul(unity_ObjectToWorld, v.objPos);
                o.worldNormal = normalize(mul(unity_WorldToObject, v.objNormal));
                o.uv = TRANSFORM_TEX(v.uv.xy, _MainTex);
                return o;
            }
            float4 frag(v2f f):SV_TARGET0
            {
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(f.worldPos));

                fixed4 mainTexSample = tex2D(_MainTex, f.uv);
                fixed3 albedo = mainTexSample * _ColorTint;
                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT * albedo;

                fixed3 diffuseColor = _LightColor0 * albedo * saturate( dot(worldLightDir, f.worldNormal));

                return float4(ambientColor + diffuseColor, mainTexSample.a * _AlphaScale);
            }
            
            ENDCG
        }
    }
}
