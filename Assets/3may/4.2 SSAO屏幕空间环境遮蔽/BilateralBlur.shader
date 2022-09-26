Shader "may/BilateralBlur"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        CGINCLUDE
            #include "UnityCG.cginc"
            sampler2D _MainTex;
            sampler2D _AoTex;
            sampler2D _CameraDepthNormalsTexture;   //深度法线 
            float4 _AoTex_TexelSize;

            float _UVOffset;              //uv偏移量， 0 不偏移， 1 偏移量为窗口的宽/高       5x5采样   
            float _BilaterFilterFactor;

            struct a2v
            {
                float4 vertex:POSITION;
                float2 uv:TEXCOORD;
            };
            struct v2f_blur
            {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD;
                half2 uvOffset:TEXCOORD1;
            };
            struct v2f_Add
            {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD;
            };
            v2f_blur vert_Horizontal(a2v v)
            {
                v2f_blur o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uvOffset = half2(_UVOffset, 0);
                return o;
            }
            v2f_blur vert_Vertical(a2v v)
            {
                v2f_blur o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uvOffset = half2(0, _UVOffset);
                return o;
            }

            float CompareNormal(float3 normal0, float3 normal1)
            {
                return smoothstep(_BilaterFilterFactor, 1.0, dot(normal0, normal1));
            }
            fixed4 frag_blur( v2f_blur i):SV_TARGET
            {
                half2 UVOffset = i.uvOffset;
                half2 uv0 = i.uv - 3 * UVOffset;
                half2 uv1 = i.uv - 2 * UVOffset;
                half2 uv2 = i.uv - 1 * UVOffset;
                half2 uv3 = i.uv;
                half2 uv4 = i.uv + 1 * UVOffset;
                half2 uv5 = i.uv + 2 * UVOffset;
                half2 uv6 = i.uv + 3 * UVOffset;
                
	            fixed4 color0 = tex2D(_MainTex, uv0);
	            fixed4 color1 = tex2D(_MainTex, uv1);
	            fixed4 color2 = tex2D(_MainTex, uv2);
	            fixed4 color3 = tex2D(_MainTex, uv3);
	            fixed4 color4 = tex2D(_MainTex, uv4);
	            fixed4 color5 = tex2D(_MainTex, uv5);
                fixed4 color6 = tex2D(_MainTex, uv6);

                float3 normal0 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, uv0));
                float3 normal1 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, uv1));
                float3 normal2 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, uv2));
                float3 normal3 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, uv3));
                float3 normal4 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, uv4));
                float3 normal5 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, uv5));
                float3 normal6 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, uv6));
                
                fixed weight0 = CompareNormal(normal3, normal0) * 0.11453744493;
                fixed weight1 = CompareNormal(normal3, normal1) * 0.19823788546;
                fixed weight2 = CompareNormal(normal3, normal2) * 0.31718061674;
                fixed weight3 = 0.37004405286;
                fixed weight4 = CompareNormal(normal3, normal4) * 0.31718061674;
                fixed weight5 = CompareNormal(normal3, normal5) * 0.19823788546;
                fixed weight6 = CompareNormal(normal3, normal6) * 0.11453744493;
                fixed weight = weight0 + weight1 + weight2 + weight3 + weight4 + weight5 + weight6;

                fixed4 blurColor = fixed4(0,0,0,0);
                blurColor += color0 * weight0;
                blurColor += color1 * weight1;
                blurColor += color2 * weight2;
                blurColor += color3 * weight3;
                blurColor += color4 * weight4;
                blurColor += color5 * weight5;
                blurColor += color6 * weight6;

               
                
                //return color5;
                return blurColor /weight;
            }

            v2f_Add vert_Add(a2v v)
            {
                v2f_Add o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            fixed4 frag_Add( v2f_Add i):SV_TARGET
            {
                fixed4 src = tex2D(_MainTex, i.uv);         //原图
                fixed4 bluredAO = tex2D(_AoTex, i.uv);      //模糊后的AO；
                return src * bluredAO;
            }
        ENDCG


        ZWrite Off ZTest Always Cull Off 
        pass 
        {
           CGPROGRAM
           #pragma vertex vert_Horizontal
           #pragma fragment frag_blur
           ENDCG
        }
        pass 
        {
           CGPROGRAM
           #pragma vertex vert_Vertical
           #pragma fragment frag_blur
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
