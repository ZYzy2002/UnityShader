Shader "may/stencil write"
{
    Properties
    {
        _StencilRefValue ("Stencil Ref Value", Int) = 1
    }
    SubShader
    {
        Tags { "Queue" = "Geometry+1" "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            ColorMask 0
            ZWrite Off
            stencil 
            {
                Ref [_StencilRefValue]
                Comp Always 
                Pass Replace 
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 vert (float4 vertex :POSITION):SV_POSITION
            {
                 return UnityObjectToClipPos(vertex);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(1, 1, 1, 1);
            }
            ENDCG
        }
    }
}
