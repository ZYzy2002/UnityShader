Shader "zd/Matcap"
{
    Properties
    {
        _MatCap("MatCap Tex",   2D) = "white"{}
        _ColorTint("Color Tint", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags {"Queue" = "Geometry" "RenderType"="Opaque" }
        LOD 200
        pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag 
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            sampler2D _MatCap;
            fixed4 _ColorTint;

            struct v2f
            {
                float4 pos:SV_POSITION;
                float3 normalVS:TEXCOORD;
            };
            v2f vert(float4 vertex:POSITION, float3 normalMS:NORMAL)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(vertex);
                float3 normalWS = UnityObjectToWorldNormal(normalMS);
                o.normalVS = mul((float3x3)UNITY_MATRIX_V, normalWS);
                return o;
            }
            fixed4 frag(v2f i):SV_TARGET
            {
                fixed3 normalVS = normalize(i.normalVS);
                fixed2 uv = (normalVS.xy + 1) / 2.0;
                return tex2D(_MatCap, uv) * _ColorTint;
            }
            ENDCG
        }
        
    }
    FallBack "Diffuse"
}
