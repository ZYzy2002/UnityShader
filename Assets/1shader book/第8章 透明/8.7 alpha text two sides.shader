// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chapter8/8.7 alpha text two sides"
{
    Properties
    {
        _ColorTint("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Main texture", 2D) = "white" {}
        _AlphaOffset("Alpha Offset", Range(0,2)) = 1
    }
    SubShader
    {
        Tags{"Queue" = "AlphaTest" "IgnorProjector" = "True" "RanderType" = "TransparentCutout"}
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            fixed4 _ColorTint;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _AlphaOffset;

            struct a2f
            {
                float3 objPos:POSITION;
                fixed3 objNormal:NORMAL;
                float4 texcoord:TEXCOORD0;
            };
            struct v2f
            {
                float4 clipPos:SV_POSITION;
                float4 worldPos:TEXCOORD0;
                float3 worldNormal:TEXCOORD1;
                float2 uv:TEXCOORD2;
            };

            v2f vert(a2f v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.objPos);
                o.worldPos = mul(unity_ObjectToWorld, v.objPos);
                o.worldNormal =normalize( mul(unity_WorldToObject, v.objNormal));
                o.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
                return o;
            }
            float4 frag(v2f f):SV_TARGET0
            {
                fixed4 texColor = tex2D(_MainTex, f.uv);
                clip(texColor.a - _AlphaOffset);

                fixed4 ambientColor = UNITY_LIGHTMODEL_AMBIENT;
                fixed4 diffuseColor = texColor * _ColorTint * _LightColor0 * saturate(dot(f.worldNormal, UnityWorldSpaceLightDir(f.worldPos)));
                return ambientColor + diffuseColor;
            }

            ENDCG
        }
    }
}
