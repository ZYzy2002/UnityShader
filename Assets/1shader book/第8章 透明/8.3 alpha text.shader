

Shader "Chapter8/8.3 Alpha Text"
{
    Properties
    {
        _Color("Color Tint", Color) = (1,1,1,1)
        _MainTex("Main Tex", 2D) = "White"{}
        _Cutoff("Alpha Cutoff", Range(-1, 1)) =0.5
    }
    SubShader
    {
        Tags{ "Queue" = "AlphaTest" "IgnoreProjector" = "True" "RanderType" = "TransparentCutout"}
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;

            struct a2f
            {
                float4 objectPosition:POSITION;
                float3 objectNormal:NORMAL;
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
                o.clipPos = UnityObjectToClipPos(v.objectPosition);
                o.worldPos = mul(unity_ObjectToWorld, v.objectPosition);
                o.worldNormal = normalize(mul( unity_WorldToObject, v.objectPosition));
                o.uv = TRANSFORM_TEX(v.texcoord.xy,_MainTex);
                return o;
            }

            float4 frag(v2f f):SV_TARGET0
            {
                fixed4 textureColor = tex2D(_MainTex, f.uv);
                
                clip(textureColor.w - _Cutoff);
                //if((textureColor.a - _Cutoff) > 0) discard;       //上式和下式选一

                fixed4 ambientColor = UNITY_LIGHTMODEL_AMBIENT;

                fixed4 diffuseColor = float4(textureColor.xyz, 1) * _LightColor0 * saturate( dot(f.worldNormal, normalize(UnityWorldSpaceLightDir(f.worldPos))));
                
                return ambientColor + diffuseColor;
            }

            ENDCG
        }
    }
    FallBack "Transparent/Cutout/VertexLit"
}
