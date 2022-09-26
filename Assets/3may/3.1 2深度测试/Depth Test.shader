Shader "may/Depth test"
{
    Properties
    {
        [Header(Depth)]
        [Enum( Off,0,On,1)]_ZWriteMode("Z Write Mode", Float ) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestMode("Z Test Mode", Float) = 4

        [Header(Diffuse)]
        _BaseColor ("Base Color", 2D) = "white" {}
        _ColorTint ("Color Tint", Color) = (1, 1, 1, 1)

    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "Z Test"
            Tags {"LightMode" = "ForwardBase"}
            ZWrite [_ZWriteMode]
            ZTest [_ZTestMode]
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"


            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _BaseColor;
            float4 _BaseColor_ST;
            fixed4 _ColorTint;

            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _BaseColor);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // diffuse
                fixed4 diffuseColor = tex2D(_BaseColor, i.uv) * _ColorTint;
                
                return diffuseColor;
            }
            ENDCG
        }
    }
}
