Shader "May/Bloom"
{
    Properties
    {
        _MainTex ("Blit Func Source Tex",               2D) = "white" {}
        _LuminanceThreshold("Luminance Threshold",      float) = 0.8
        _BlurSize(" UV offset",                         float) = 1.0
        _Bloom("Pass4 Second SourceTex ",               2D) = "white"{}
    }
    SubShader
    {
        Tags{}
        
        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        float4 _MainTex_TexelSize;
        float _LuminanceThreshold;
        float _BlurSize;
        sampler2D _Bloom;

        //Pass 1
        struct v2f_ObtainBright
        {
            float4 pos:SV_POSITION;
            float2 uv:TEXCOORD;
        };
        v2f_ObtainBright vert_ObtainBrighterArea(float4 vertex:POSITION, float2 uv:TEXCOORD)
        {
            v2f_ObtainBright o;
            o.pos = UnityObjectToClipPos(vertex);
            o.uv = uv;
            return o;
        }
        fixed4 frag_ObtainBrighterArea(v2f_ObtainBright i):SV_TARGET
        {
            fixed4 sourceTexColor = tex2D(_MainTex, i.uv);
            fixed brightness = Luminance(sourceTexColor);
            return sourceTexColor * clamp(brightness - _LuminanceThreshold, 0.0, 1.0);
        }
        //Pass 1,2
        struct v2f_BlurUV
        {
            float4 pos:SV_POSITION;
            float2 uv[5]:TEXCOORD;
        };
        v2f_BlurUV vert_BlurHorizontal(float4 vertex:POSITION, float2 uv:TEXCOORD)
        {
            v2f_BlurUV o;
            o.pos = UnityObjectToClipPos(vertex);
            float2 uvOffset = float2(_MainTex_TexelSize.x, 0);
            o.uv[0] = uv - uvOffset * 2 * _BlurSize;
            o.uv[1] = uv - uvOffset;
            o.uv[2] = uv;
            o.uv[3] = uv + uvOffset;
            o.uv[4] = uv + uvOffset * 2 * _BlurSize;
            return o;
        }
        v2f_BlurUV vert_BlurVertical(float4 vertex:POSITION, float2 uv:TEXCOORD)
        {
            v2f_BlurUV o;
            o.pos = UnityObjectToClipPos(vertex);
            float2 uvOffset = float2(0, _MainTex_TexelSize.y);
            o.uv[0] = uv - uvOffset * 2 * _BlurSize;
            o.uv[1] = uv - uvOffset;
            o.uv[2] = uv;
            o.uv[3] = uv + uvOffset;
            o.uv[4] = uv + uvOffset * 2 * _BlurSize;
            return o;
        }
        fixed4 frag_Blur(v2f_BlurUV i):SV_TARGET
        {
            float weight[3] = {0.4026, 0.2442, 0.0545};
            fixed3 finalColor = tex2D(_MainTex, i.uv[2]).rgb * weight[0];
            finalColor += tex2D(_MainTex, i.uv[1]).rgb * weight[1];
            finalColor += tex2D(_MainTex, i.uv[3]).rgb * weight[1];
            finalColor += tex2D(_MainTex, i.uv[0]).rgb * weight[2];
            finalColor += tex2D(_MainTex, i.uv[4]).rgb * weight[2];
            return fixed4(finalColor, 1);
        }
        //Pass 3
        struct v2fBloom {
			float4 pos : SV_POSITION; 
			float4 uv : TEXCOORD0;
		};

		v2fBloom vert_Add(float4 vertex:POSITION, float2 uv:TEXCOORD) {
			v2fBloom o;
			o.pos = UnityObjectToClipPos(vertex);
            o.uv.xy = uv;
            o.uv.zw = uv;

            #if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y < 0.0) 
                o.uv.w = 1.0 - o.uv.w;
            #endif

            return o;
        }

		fixed4 frag_Add(v2fBloom i) : SV_Target {
			return  tex2D(_Bloom, i.uv.zw) + tex2D(_MainTex, i.uv.xy);
		} 
        ENDCG

        ZTest Always Cull Off ZWrite Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_ObtainBrighterArea
            #pragma fragment frag_ObtainBrighterArea
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_BlurHorizontal
            #pragma fragment frag_Blur
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_BlurVertical
            #pragma fragment frag_Blur
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_Add
            #pragma fragment frag_Add
            ENDCG
        }
    }
    Fallback "Diffuse"
}
