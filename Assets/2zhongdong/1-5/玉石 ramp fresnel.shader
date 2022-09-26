// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "zd/绿色玉石 ramp"
{
    Properties
    {
        
        _RampMap ("玉石渐变纹理", 2D) = "white" {}
        _SpecularPow("高光范围", Range(0.2,40)) = 16
        _fresnelPow("菲涅尔范围",Range(0.1,10)) = 4
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        pass
        {
            tags{"LightMode" = "ForwardBase"}
            NAME "绿色玉石"

            CGPROGRAM 
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag 
            sampler2D _RampMap;
            half4 _RampMap_ST;
            float _SpecularPow;
            float _fresnelPow;

            struct a2v 
            {
                float4 vertex:POSITION;
                fixed4 uv:TEXCOORD;
                fixed3 normal:NORMAL;
            };
            struct v2f 
            {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD;
                float3 normalWS:TEXCOORD1;
                float3 posWS:TEXCOORD2;
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWS =mul(unity_ObjectToWorld, v.vertex);
                o.normalWS = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _RampMap);
                return o;
            }
            float4 frag(v2f i):SV_TARGET0
            {
                float3 normalWS = normalize(i.normalWS);
                fixed3 LightDirWS = normalize(UnityWorldSpaceLightDir(i.posWS));
                fixed3 ViewDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));

                fixed fresnel = pow(1-dot(normalWS,ViewDirWS), _fresnelPow);
                fixed lambert = saturate(dot(normalWS, LightDirWS));
                fixed3 reflectDir = normalize(reflect(-LightDirWS,i.normalWS));

                // 漫反射 渐变贴图 
                fixed3 rampMapColor = tex2D(_RampMap,lambert.xx);
                
                // 高光 Phong + 偏移 Phong
                fixed3 specularColor =  pow( dot(reflectDir, ViewDirWS), _SpecularPow) ;
                specularColor = _LightColor0 * smoothstep(0.7,0.9,specularColor);

                return fixed4(rampMapColor + fresnel.xxx + specularColor ,1);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
