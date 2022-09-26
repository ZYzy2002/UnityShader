Shader "Chapter14/14.2 Hatching"
{
    Properties
    {
        _Color("Color Tint", Color) = (1,1,1,1)
        _TileFactor("Tile Factor", Float) = 8           //六张纹理的 xy scale平铺 都使用这个缩放值，便于控制，此处不再使用_Tex_ST或 TRANSFORM_TEX
        _Outline("Outline Width", Range(0, 1)) = 0.1    //描边宽度
        _Hatch0("Hatch0", 2D) = "white"{}
        _Hatch1("Hatch1", 2D) = "white"{}
        _Hatch2("Hatch2", 2D) = "white"{}
        _Hatch3("Hatch3", 2D) = "white"{}
        _Hatch4("Hatch4", 2D) = "white"{}
        _Hatch5("Hatch5", 2D) = "white"{}
    }
    SubShader
    {   
        Tags{"Queue" = "Geometry" "IgnoreProjector" = "False" "RanderType" = "Opaque" "DisableBatching" = "False"}
        pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma vertex vert 
            #pragma fragment frag 
            #pragma multi_compile_fwdbase
            fixed4 _Color;
            float _TileFactor;
            fixed _Outline;
            sampler2D _Hatch0;
            sampler2D _Hatch1;
            sampler2D _Hatch2;
            sampler2D _Hatch3;
            sampler2D _Hatch4;
            sampler2D _Hatch5;

            struct a2v 
            {
                float4 vertex:POSITION;
                float2 texcoord:TEXCOORD;
                float3 normal:NORMAL;
            };
            struct v2f 
            {
                float4 pos:SV_POSITION;
                float4 worldPos:TEXCOORD1;
                fixed3 worldNor:TEXCOORD2;
                float2 uv:TEXCOORD0;
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNor = UnityObjectToWorldNormal(v.normal);
                o.uv = v.texcoord * _TileFactor;
                return o;
            }
            fixed4 frag(v2f i):SV_TARGET0
            {
                i.worldNor = normalize(i.worldNor);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 diffuseColor = _LightColor0.rgb * _Color.rgb * saturate(dot(i.worldNor, worldLightDir));
                half diffuseBrightness = diffuseColor.r * 0.299 + diffuseColor.g * 0.587 + diffuseColor.b *0.114;
                diffuseBrightness *= 7;

                if(diffuseBrightness >= 6)
                {
                    return lerp(tex2D(_Hatch0, i.uv), fixed4(1, 1, 1, 1), diffuseBrightness - 6.0);
                }
                else if(diffuseBrightness >= 5)
                {
                    return lerp(tex2D(_Hatch1, i.uv), tex2D(_Hatch0, i.uv) , diffuseBrightness - 5.0);
                }
                else if(diffuseBrightness >= 4)
                {
                    return lerp(tex2D(_Hatch2, i.uv), tex2D(_Hatch1, i.uv) , diffuseBrightness - 4.0);
                }
                else if(diffuseBrightness >= 3)
                {
                    return lerp(tex2D(_Hatch3, i.uv), tex2D(_Hatch2, i.uv) , diffuseBrightness - 3.0);
                }
                else if(diffuseBrightness >= 2)
                {
                    return lerp(tex2D(_Hatch4, i.uv), tex2D(_Hatch3, i.uv) , diffuseBrightness - 2.0);
                }
                else if(diffuseBrightness >= 1)
                {
                    return lerp(tex2D(_Hatch5, i.uv), tex2D(_Hatch4, i.uv) , diffuseBrightness - 1.0);
                }
                else
                {
                    return tex2D(_Hatch5, i.uv);
                }
                return fixed4(1, 1, 1, 1);
            }
            ENDCG
        }
    }
}
