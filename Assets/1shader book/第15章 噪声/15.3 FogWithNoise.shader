Shader "Chapter15/15.3 FogWithNoise"
{
    Properties
    {
        _MainTex("_Main Tex", 2D) = "white"{}   //后处理的 屏幕原纹理
    }
    SubShader
    {
        pass
        {
            ZTest Always ZWrite Off Cull Off 
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert 
            #pragma fragment frag 
            float _FogDensity;
            fixed4 _FogColor;   
            float _FogStart;    //高度
            float _FogEnd;      //高度
            sampler2D _NoiseTex;//噪声
            float _FogXSpeed;   
            float _FogYSpeed;
            float _NoiseAmount; //雾的整体强度

            float4x4 _FrustumCornersRay;
            sampler2D _CameraDepthTexture;

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;

            struct a2v 
            {
                float4 vertex:POSITION;
                float2 texcoord:TEXCOORD;
            };
            struct v2f 
            {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0;
                float2 uv_depth:TEXCOORD2;
                float3 interpolatedRay:TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.uv_depth = v.texcoord;

                int index;
                if(v.texcoord.x <  0.5 && v.texcoord.y < 0.5)
                {
                    index = 0;  //左下
                }
                else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5)
                {
                    index = 1;  //右下
                }
                else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5)
                {
                    index = 2;  //右上
                }
                else 
                {
                    index = 3;  //左上
                }

                #if UNITY_UV_STARTS_AT_TOP 
                    if(_MainTex_TexelSize.y < 0)
                    {   index = 3 - index;  //上下翻转
                        o.uv_depth.y = 1 - o.uv_depth.y;
                    }
                #endif
                    o.interpolatedRay = _FrustumCornersRay[index];
                    
                return o;
            }
            fixed4 frag(v2f i):SV_TARGET0
            {
                float3 worldPos = _WorldSpaceCameraPos + i.interpolatedRay * LinearEyeDepth( SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));

                fixed noise = (    tex2D(_NoiseTex, i.uv + _Time.x * float2(_FogXSpeed, _FogYSpeed)    ).r )* _NoiseAmount * _FogColor;          // 雾效的选区  +0.1 避免纯黑
                noise = saturate(lerp(noise  , 0, (worldPos.y - _FogStart) / (_FogEnd - _FogStart)) * _FogDensity);                                            // 插值因子 w 

                return lerp(tex2D(_MainTex, i.uv), _FogColor, noise);






 /*               float2 speed = _Time.y * float2(_FogXSpeed, _FogYSpeed);
			float noise = (tex2D(_NoiseTex, i.uv + speed).r - 0.5) * _NoiseAmount;
					
			float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); 
			fogDensity = saturate(fogDensity * _FogDensity * (1 + noise));
			
			fixed4 finalColor = tex2D(_MainTex, i.uv);
			finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);
			
			return finalColor;
*/
               
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
