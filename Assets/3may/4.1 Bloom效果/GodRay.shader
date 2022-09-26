Shader "may/GodRay"
{
    Properties
    {
        _MainTex ("原图像/提取后的遮罩/原图像",  2D) = "white" {}

        [Header(Pass0 Extract)]
        _LuminanceThreshold("亮度提取 阈值",    Range(0,1)) = 0.9 
        _LightPosInScreenUV("光源位置 xy",      Color) = (0.5,0.5,0,0)
        _LightRadius("光源半径",                Range(0,1)) = 0.2
        _MaskPow("亮部遮罩 改变亮度的pow" ,      Range(0,40)) = 1

        [Header(Pass1 Radial Blur)]
        _SamplerPointCount("径向采样点个数",    Range(1,20)) = 14
        _SamplerOffset("径向uv采样偏移程度",    Range(0,0.05)) = 0.02
        _LightColor("光颜色  给遮罩偏色" ,       Color) = (1,0,0,1)

        [Header(Pass2 Add)]
        _BlurTex("径向模糊后的图像",            2D) = "white"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        
        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        float4 _MainTex_TexelSize;
        float _LuminanceThreshold;
        fixed2 _LightPosInScreenUV;
        half _LightRadius;
        half _MaskPow;
        half _SamplerPointCount;
        half _SamplerOffset;
        fixed4 _LightColor;

        sampler2D _BlurTex;

        struct v2f_Extract
        {
            float4 pos:SV_POSITION;
            float2 uv:TEXCOORD;
        };
        v2f_Extract vert_Exrtract(float4 vertex:POSITION, float2 uv:TEXCOORD)
        {
            v2f_Extract o;
            o.pos = UnityObjectToClipPos(vertex);
            o.uv = uv;
            return o;
        }
        fixed4 frag_Extract(v2f_Extract i):SV_TARGET
        {
            fixed4 sourceColor = tex2D(_MainTex, i.uv);
            fixed mask = saturate(Luminance(sourceColor) - _LuminanceThreshold);    //根据亮度制作的遮罩
            mask = mask * saturate(1 - length(i.uv - _LightPosInScreenUV) / _LightRadius);  //根据半径制作的遮罩
            
            return pow(fixed4(mask, mask, mask, 1), _MaskPow);
        }

        struct v2f_RadialBlur
        {
            float4 pos:SV_POSITION;
            float2 uv:TEXCOORD;
            float2 blurOffset:TEXCOORD1;
        };
        v2f_RadialBlur vert_RadialBlur(float4 vertex:POSITION, float2 uv:TEXCOORD)
        {
            v2f_RadialBlur o;
            o.pos = UnityObjectToClipPos(vertex);
            o.uv = uv;
            o.blurOffset = _SamplerOffset * (_LightPosInScreenUV - o.uv);
            return o;
        }
        fixed4 frag_RadialBlur(v2f_RadialBlur i):SV_TARGET
        {
            half mask = 0;
            for(int j = 0; j < _SamplerPointCount; j++)
            {
                mask += tex2D(_MainTex, i.uv).x;
                i.uv += i.blurOffset;
            }
            return mask / _SamplerPointCount * _LightColor;
        }

        struct v2f_Add
        {
            float4 pos:SV_POSITION;
            float2 uv:TEXCOORD;
        };
        v2f_Add vert_Add(float4 vertex:POSITION, float2 uv:TEXCOORD)
        {
            v2f_Add o;
            o.pos = UnityObjectToClipPos(vertex);
            o.uv = uv;
            #if UNITY_UV_STARTS_AT_TOP
                if (_MainTex_TexelSize.y < 0)
                o.uv.y = 1 - o.uv.y;
            #endif  
            return o;
        }
        fixed4 frag_Add(v2f_Add i):SV_TARGET
        {
            return tex2D(_MainTex, i.uv) + tex2D(_BlurTex,i.uv);
        }
        ENDCG

        ZWrite Off ZTest Always Cull Off
        pass
        {
            CGPROGRAM
            #pragma vertex vert_Exrtract
            #pragma fragment frag_Extract
            ENDCG
        }
        pass
        {
            CGPROGRAM
            #pragma vertex vert_RadialBlur
            #pragma fragment frag_RadialBlur
            ENDCG
        }
        pass
        {
            CGPROGRAM
            #pragma vertex vert_Add
            #pragma fragment frag_Add
            ENDCG
        }
    }
    FallBack "Diffuse"
}
