Shader "Chapter11/11.2 sequence anim"
{
    Properties
    {
        _Color("Color Tint", Color) = (1,1,1,1)
        _MainTex("Image Sequence", 2D) = "white"{}
        _HorizontalAmount("Horizontal Amount", Float) = 8       //行数
        _VerticalAmount("Vertical Amount", Float) = 8           //列数
        _Speed("Speed", Range(1, 100)) = 30
    }
    SubShader
    {
        Tags{"Queue" = "Transparent"}
        pass
        {
            Tags{"LightMode" = "ForwardBase"}
            Zwrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase
            #pragma vertex vert 
            #pragma fragment frag 
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HorizontalAmount;
            float _VerticalAmount;
            float _Speed;

            struct a2v
            {
                float4 vertex:POSITION;
                float4 texcoord:TEXCOORD;
            };
            struct v2f
            {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0;
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }
            float4 frag(v2f i):SV_TARGET0
            {
                float time = floor(_Time.y * _Speed);           //向下取整，  单位  1/30s
                float row = floor(time / _HorizontalAmount);    //除以8  该纹理平铺模式必须是 重复
                float column = time - row * _HorizontalAmount;

                float2 uv = i.uv + float2(column, -row);
                uv.x /= _HorizontalAmount;
                uv.y /= _VerticalAmount;

                fixed4 frame = tex2D(_MainTex, uv);
                return frame * _Color;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
