Shader "Chapter12/12.5 Bloom"
{
    Properties
    {
        _MainTex("Screen", 2D) = ""{}                           //屏幕
        _Bloom ("Bloom (RGB)", 2D) = "black" {}                 //仅在最后的pass中使用， 输入 pass2 模糊后的 高亮部分
        _LuminanceThreshold("亮度阈值", Range(0, 1)) = 0.8 
        _BlurSize("BlurSize", Float) = 1
    }
    SubShader
    {
        //
        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        float4 _MainTex_TexelSize;
        sampler2D _Bloom;
        float _LuminanceThreshold;
        float _BlurSize;
        struct a2v 
        {
            float4 vertex:POSITION;
            float4 texcoord:TEXCOORD;
        };
        struct v2f 
        {
            float4 pos:SV_POSITION;
            float4 uv:TEXCOORD;     //pass0 use  xy ; pass3  use  xy zw
        };

        //提取高亮
        v2f ExtractBrightnessVert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.texcoord.xy;
            o.uv.zw = float2(0, 0);
            return o;
        }
        float computeBrightness(fixed3 color)
        {
            return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
        }
        float4 ExtractBrightnessFrag(v2f i):SV_TARGET0
        {
            fixed4 screenColor = tex2D(_MainTex, i.uv);
            fixed a = clamp(computeBrightness(screenColor.xyz) - _LuminanceThreshold, 0, 1);
            return screenColor * a;
        }
        //合并
        v2f AddVert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.texcoord.xy;           //Maintex
            o.uv.zw = v.texcoord.xy;           //Blured tex  需要考虑平台
            #if UNITY_UV_STARTS_AT_TOP			
			if (_MainTex_TexelSize.y < 0.0)
				o.uv.w = 1.0 - o.uv.w;
			#endif
            return o;
        }
        float4 AddFrag(v2f i):SV_TARGET0
        {
            return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
        }

        ENDCG
        //

        ZTest Always ZWrite Off Cull Off
        pass        //选出亮部 到 buffer0
        {
            CGPROGRAM
            #pragma vertex ExtractBrightnessVert
            #pragma fragment ExtractBrightnessFrag
            ENDCG
        }
        UsePass "Chapter12/12.4 GaussionBlur/GAUSSIAN_BLUR_VERTICAL"
        UsePass "Chapter12/12.4 GaussionBlur/GAUSSIAN_BLUR_HORIZONTAL"
        pass        //合并  模糊图和原图
        {
            CGPROGRAM
            #pragma vertex AddVert
            #pragma fragment AddFrag
            ENDCG
        }
    }
    FallBack "Diffuse"
}
