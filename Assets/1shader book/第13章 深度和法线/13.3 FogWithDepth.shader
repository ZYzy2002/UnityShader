Shader "Chapter13/13.3 FogWithDepth"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white"{}
        _FogDensity("Fog Density", Float) = 1.0
        _FogColor("Fog Color", Color) = (1, 1, 1, 1)
        _FogStart("Fog Start", Float) = 0.0
        _FogEnd("Fog End", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        float4 _MainTex_TexelSize;
        float _FogDensity;
        fixed4 _FogColor;
        float _FogStart;
        float _FogEnd;
        
        float4x4 _FrustumCornersRay;       //储存 BL  BR  TR  TL 向量
        sampler2D _CameraDepthTexture;

        struct v2f 
        {
            float4 pos:SV_POSITION;
            float2 uv:TEXCOORD0;
            float2 uv_depth:TEXCOORD1;
            float4 interpolatedRay:TEXCOORD2;
        };
        v2f vert(appdata_img v)
        {
            v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;
			
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif
			
			int index = 0;
			if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
				index = 0;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
				index = 1;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
				index = 2;
			} else {
				index = 3;
			}

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				index = 3 - index;
			#endif
			
			o.interpolatedRay = _FrustumCornersRay[index];                  //由于后处理只有两个三角形，  共4个不同位置的点，  判断点的UV坐标  区分四个点，  返回四个向量，   插值后 得到 指向 对应像素的scale
				 	 
			return o;
        }
        fixed4 frag(v2f i):SV_TARGET0
        {
            float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
            float3 worldPos = _WorldSpaceCameraPos + i.interpolatedRay.xyz * linearDepth;

            float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);
            fogDensity = saturate(fogDensity * _FogDensity);

            //return fixed4(worldPos, 1);
            return lerp(tex2D(_MainTex, i.uv), _FogColor, fogDensity);
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
    FallBack Off
}

