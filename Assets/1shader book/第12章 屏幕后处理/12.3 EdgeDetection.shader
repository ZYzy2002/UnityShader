Shader "Chapter12/12.3 EdgeDetection"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _EdgeOnly("Edge Only", Float) = 1                           //为0时：边缘将叠加到原图上，  为1时： 直接覆盖掉原图(只有 边缘色 和 背景色)
        _EdgeColor("Edge Color", Color) = (0, 0, 0, 1)              //边缘颜色  黑色
        _BackgroundColor("BackgroundColor", Color) = (1,1,1,1)      //其他部分的颜色   白色
    }
    SubShader
    {
        pass
        {
            Tags{}
            ZTest Always 
            ZWrite Off 
            Blend Off 
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag 
            #include "UnityCG.cginc"
            sampler2D _MainTex;
            float4 _MainTex_TexelSize;  //不用使用 _MainTex_ST  因为屏幕处理不需要纹理缩放，   _Xxxxx_TexelSize  获取该纹理对应的纹素的大小，
            half _EdgeOnly;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;

            struct a2v
            {
                float4 vertex:POSITION;
                half2 texcoord:TEXCOORD;
            };
            struct v2f 
            {
                float4 pos:SV_POSITION;
                half2 uv[9]:TEXCOORD1;
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv[0] = v.texcoord + _MainTex_TexelSize.xy * half2(-1, -1);
				o.uv[1] = v.texcoord + _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = v.texcoord + _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = v.texcoord + _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = v.texcoord + _MainTex_TexelSize.xy;
				o.uv[5] = v.texcoord + _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = v.texcoord + _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = v.texcoord + _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = v.texcoord + _MainTex_TexelSize.xy * half2(1, 1);
                return o;
            }
            fixed luminance(fixed4 color) {
				return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
			}
			half Sobel(v2f i) {
				const half Gx[9] = {-1,  0,  1,
									-2,  0,  2,
									-1,  0,  1};
				const half Gy[9] = {-1, -2, -1,
									0,  0,  0,
									1,  2,  1};
				
				half texColor;
				half edgeX = 0;
				half edgeY = 0;
				for (int it = 0; it < 9; it++) {
					texColor = luminance(tex2D(_MainTex, i.uv[it]));
					edgeX += texColor * Gx[it];
					edgeY += texColor * Gy[it];
				}
				
				half edge = 1 - abs(edgeX) - abs(edgeY);
				
				return edge;
			}
            float4 frag(v2f i):SV_TARGET0
            {
                half edge = Sobel(i);

                fixed4 edgeColor_and_texcolor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), edge);   //将边缘色添加到 原图上 
                fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);                    //将边缘色添加到 背景色上
                return lerp(edgeColor_and_texcolor, onlyEdgeColor, _EdgeOnly);      //_EdgeOnly 从上述显示方案中选择一个
            }
            ENDCG
        }
    }
}
