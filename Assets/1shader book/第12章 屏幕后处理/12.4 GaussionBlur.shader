Shader "Chapter12/12.4 GaussionBlur"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BlurSize("Blur Size", Float) = 1 
    }
    SubShader
    {
        //CGINCLUDE用于组织代码
        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        float4 _MainTex_TexelSize;
        float _BlurSize;
        struct a2v 
        {
            float4 vertex:POSITION;
            float2 texcoord:TEXCOORD;
        };
        struct v2f 
        {
            float4 pos:SV_POSITION;
            half2 uv[5]:TEXCOORD0;
        };
        v2f vertVertical(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            
            o.uv[2] = v.texcoord;
            o.uv[0] = v.texcoord - float2(0, _MainTex_TexelSize.y) * 2 * _BlurSize;
            o.uv[1] = v.texcoord - float2(0, _MainTex_TexelSize.y) * 1 * _BlurSize;
            o.uv[3] = v.texcoord + float2(0, _MainTex_TexelSize.y) * 1 * _BlurSize;
            o.uv[4] = v.texcoord + float2(0, _MainTex_TexelSize.y) * 2 * _BlurSize;
            return o;
        }
        v2f vertHorizontal(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            
            o.uv[2] = v.texcoord;
            o.uv[0] = v.texcoord - float2(_MainTex_TexelSize.x, 0) * 2 * _BlurSize;
            o.uv[1] = v.texcoord - float2(_MainTex_TexelSize.x, 0) * 1 * _BlurSize;
            o.uv[3] = v.texcoord + float2(_MainTex_TexelSize.x, 0) * 1 * _BlurSize;
            o.uv[4] = v.texcoord + float2(_MainTex_TexelSize.x, 0) * 2 * _BlurSize;
            return o;
        }
        float4 frag(v2f i):SV_TARGET0
        {
            float weight[3] = {0.4026, 0.2442, 0.0545};
            fixed3 nearColor[5];
            nearColor[0] = tex2D(_MainTex, i.uv[0]);
            nearColor[1] = tex2D(_MainTex, i.uv[1]);
            nearColor[2] = tex2D(_MainTex, i.uv[2]);
            nearColor[3] = tex2D(_MainTex, i.uv[3]);
            nearColor[4] = tex2D(_MainTex, i.uv[4]);
            return float4(nearColor[0] * weight[2] 
                + nearColor[1] * weight[1] 
                + nearColor[2] * weight[0] 
                + nearColor[3] * weight[1] 
                + nearColor[4] * weight[2], 1);
        }
        ENDCG
        //----------

        ZTest Always Cull Off ZWrite Off
        pass
        {
            Name "GAUSSIAN_BLUR_VERTICAL"
            //ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vertVertical
            #pragma fragment frag
            ENDCG
        }
        pass
        {   
            Name "GAUSSIAN_BLUR_HORIZONTAL"
            //ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vertHorizontal 
            #pragma fragment frag 
            ENDCG
        }
    }
    FallBack "Diffuse"
}
