Shader "Chapter13/13.4 EdgeWithDepthNormal"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _EdgeOnly("Edge Only", Float) = 1.0
        _EdgeColor("Edge Color", Color) = (0, 0, 0, 1)
        _BackgroundColor("BackgroundColor", Color) = (1, 1, 1, 1)
        _SampleDistance("Sample Distance", Float) = 1.0
        _Sensitivity("normal and depth sensitivity", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        float4 _MainTex_TexelSize;
        float _EdgeOnly;
        fixed4 _EdgeColor;
        fixed4 _BackgroundColor;
        float _SampleDistance;
        fixed4 _Sensitivity;

        sampler2D _CameraDepthNormalsTexture;

        struct v2f
        {
            float4 pos:SV_POSITION;
            half2 uv:TEXCOORD0;
            half2 uv_depth_normal:TEXCOORD1;
        };
        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord.xy;
            o.uv_depth_normal = v.texcoord.xy;

            #if UNITY_UV_STARTS_AT_TOP
                if(_MainTex_TexelSize.y < 0)
                o.uv_depth_normal.y = 1 - o.uv_depth_normal.y;
            #endif
            return o;
        }
        fixed4 frag(v2f i):SV_TARGET0
        {
            fixed2 uv[4] = 
            {
                i.uv_depth_normal + _SampleDistance * _MainTex_TexelSize.xy * fixed2(1, 1),
                i.uv_depth_normal + _SampleDistance * _MainTex_TexelSize.xy * fixed2(-1, 1),
                i.uv_depth_normal + _SampleDistance * _MainTex_TexelSize.xy * fixed2(1, -1),
                i.uv_depth_normal + _SampleDistance * _MainTex_TexelSize.xy * fixed2(-1, -1)
            };
            fixed4 sampleDepthTexture[4] =
            {
                tex2D(_CameraDepthNormalsTexture, uv[0]),
                tex2D(_CameraDepthNormalsTexture, uv[1]),
                tex2D(_CameraDepthNormalsTexture, uv[2]),
                tex2D(_CameraDepthNormalsTexture, uv[3])
            };
            fixed2 normal[4] = 
            {
                sampleDepthTexture[0].xy,
                sampleDepthTexture[1].xy,
                sampleDepthTexture[2].xy,
                sampleDepthTexture[3].xy
            };
            half depth[4] = 
            {
                DecodeFloatRG(sampleDepthTexture[0].zw),
                DecodeFloatRG(sampleDepthTexture[1].zw),
                DecodeFloatRG(sampleDepthTexture[2].zw),
                DecodeFloatRG(sampleDepthTexture[3].zw)
            };

            // judge if the normal is similar
            half different1 = abs(normal[0] - normal[3]) * _Sensitivity.x;
            half different2 = abs(normal[1] - normal[2]) * _Sensitivity.x;
            half normalEdge = (different1 < 0.1 ? 0 : 1) ||(different2 < 0.1 ? 0 : 1);

            // judge if the depth is similar
            half different3 = (abs(depth[0] - depth[3]) + abs(depth[1] - depth[2])) * _Sensitivity.y;
            half depthEdge = different3 < 0.1 ? 0 : 1;

            fixed4 edgeColorAndOriginalColor = lerp(tex2D(_MainTex, i.uv), _EdgeColor, normalEdge||depthEdge);
            fixed4 edgeColorAndBackgroundColor = lerp(_BackgroundColor, _EdgeColor, normalEdge||depthEdge);

            return lerp(edgeColorAndOriginalColor, edgeColorAndBackgroundColor, _EdgeOnly);
        }
        ENDCG

        pass
        {
            ZTest Always ZWrite Off Cull Off 
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag 
            ENDCG
        }
    }
    FallBack "Diffuse"
}
