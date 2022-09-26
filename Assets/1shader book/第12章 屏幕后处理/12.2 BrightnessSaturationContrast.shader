Shader "Chapter12/12.2 BrightnessSaturationContrast"
{
    Properties
    {
        _MainTex ("MainTex", Color) = (1,1,1,1)
        _Brightness ("Brightness", Float) = 1
        _Saturation ("Saturation", Float) = 1
        _Contrast ("Constrast", Float) = 1
    }
    SubShader
    {
        Tags{}
        pass
        {
            Tags{}
            ZWrite Off 
            ZTest Always
            Cull Off 

            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert 
            #pragma fragment frag
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Brightness;
            float _Saturation;
            float _Contrast;

            struct a2v 
            {
                float4 vertex:POSITION;
                float4 texcoord:TEXCOORD;
            };
            struct v2f
            {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD;
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
                fixed4 renderTex = tex2D(_MainTex, i.uv);

                //brightness 
                fixed3 finalColor = renderTex.rgb * _Brightness;
                
                //saturateion
                fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;   
                fixed3 luminanceColor = luminance.xxx;       
                finalColor = lerp(luminanceColor, finalColor, _Saturation);

                //contrast
                fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
                finalColor = lerp(avgColor, finalColor, _Contrast);

                return fixed4(finalColor, renderTex.w);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
