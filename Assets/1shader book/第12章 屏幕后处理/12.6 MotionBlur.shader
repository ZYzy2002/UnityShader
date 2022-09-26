Shader "Chapter12/12.6 MotionBlur"
{
    Properties
    {   
        _MainTex("main tex", 2D) = ""{}
        _BlurAmount("Blur Amount", Float) = 0.5
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        float _BlurAmount;
        struct v2f 
        {
            float4 pos:SV_POSITION;
            float2 uv:TEXCOORD;
        };
        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord.xy;
            return o;
        }
        float4 fragRGB(v2f i):SV_TARGET0
        {
            return float4(tex2D(_MainTex, i.uv).rgb, _BlurAmount);
        }
        float4 fragA():SV_TARGET0
        {
            return float4(0, 0, 0, 1);
        }
        ENDCG

        ZTest Always ZWrite Off Cull Off 

        pass
        {
            ColorMask RGB
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragRGB
            ENDCG
        }
        pass 
        {
            ColorMask A
            Blend Off
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment fragA
            ENDCG
        }
    }
    FallBack "Diffuse"
}
