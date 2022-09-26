Shader "zd/RampTeX¼ÙSSSÐ§¹û"
{
    Properties
    {
        _RampTex ("RampTex SSS", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed4 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv       :TEXCOORD0;
                float4 pos      : SV_POSITION;
                float4 posWS :TEXCOORD1;
                fixed3 normalWS :TEXCOORD2;
            };

            sampler2D _RampTex;
            float4 _RampTex_ST;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _RampTex);
                o.normalWS = UnityObjectToWorldNormal(v.normal);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float halfLambert = 0.5 * (dot(i.normalWS, WorldSpaceLightDir(i.posWS)) + 1);
                fixed4 col = tex2D(_RampTex, half2(halfLambert, 0.5));
                
                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
