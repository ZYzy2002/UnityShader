Shader "zd/葡萄"
{
    Properties
    {
        _RampTex("Ramp Tex", 2D) = "white"{}
        _ColorTintMap("Color Tint", 2D) = "white"{}
        _SpecularPow("Specular Domain", range(0, 100)) = 20
        _FresnelPow("Fresnel Domain", range(0, 100)) = 20
        _FresnelColor("Frasnel Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        pass
        {
            Name "葡萄"
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM 
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma vertex vert 
            #pragma fragment frag 
            #pragma multi_compile_fwdbase
            sampler2D _RampTex;
            float4 _RampTex_ST;
            sampler2D _ColorTintMap;
            float4 _ColorTintMap_ST;
            float _SpecularPow;
            float _FresnelPow;
            fixed4 _FresnelColor;
            
	        struct a2v
	        {
		        float4 vertex:POSITION;
                fixed3 normal:NORMAL;
                float4 texcoord:TEXCOORD;
	        };
	        struct v2f 
	        {
		        float4 pos:SV_POSITION;
                float2 uv:TEXCOORD;
                float4 posWS:TEXCOORD1;
                SHADOW_COORDS(2)
                float3 normalWS:TEXCOORD3;
	        };
	        v2f vert(a2v v)
	        {
		        v2f o;
		        o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _ColorTintMap);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                TRANSFER_SHADOW(o)
                o.normalWS = UnityObjectToWorldNormal(v.normal);
		        return o;
	        }
	        fixed4 frag(v2f i):SV_TARGET0
	        {
                fixed3 LightDirWS = normalize(UnityWorldSpaceLightDir(i.posWS));
                fixed3 ViewDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
                fixed3 normalWS = normalize(i.normalWS); 
                fixed3 ColorTint = tex2D(_ColorTintMap, i.uv);
                
               
                half fresnel = pow(1 - dot(ViewDirWS, normalWS), _FresnelPow) * _FresnelColor;

                //
                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.xyz + fresnel.xxx;

                fixed halfLambert = dot(LightDirWS, normalWS) * 0.5 + 0.5;
                fixed3 diffuseColor = _LightColor0 * ColorTint * tex2D(_RampTex, fixed2(halfLambert, 0.5));

                half3 halfVector = normalize(LightDirWS + ViewDirWS);
                fixed3 specularColor = _LightColor0 * pow(saturate(dot(halfVector, normalWS)), _SpecularPow);

                UNITY_LIGHT_ATTENUATION(atten, i, i.posWS)
                //return fixed4(LightDirWS, 1);
		        return fixed4(ambientColor + (diffuseColor + specularColor) * atten , 1);
	        }
	        ENDCG
        }
    }
    FallBack "Diffuse"
}
