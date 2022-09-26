// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Chapter10/10.1 Fresnel"
{
    Properties
    {
        _ColorTint("Color Tint", Color) = (1, 1, 1, 1)
        _FresnelScale("Fresnel Scale", Range(0, 1)) = 0.5
        _Cubemap("Reflection Cube map", Cube) = "_Skybox"{}
    }
    SubShader
    {
        Tags{"Queue" = "Geometry"}
        pass
        {
            Tags{"LightMode" = "ForwardBase"}
            ZWrite On
            
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma vertex vert 
            #pragma fragment frag 
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            fixed4 _ColorTint;
            float _FresnelScale;
            samplerCUBE _Cubemap;

            struct a2v
            {
                float4 vertex:POSITION;
                fixed3 objNormal:NORMAL;
            };
            struct v2f
            {
                float4 pos:SV_POSITION;
                float4 worldPos:TEXCOORD0;
                fixed3 worldNormal:TEXCOORD1;
                SHADOW_COORDS(2)
                float3 negtive_worldViewDir:TEXCOORD3;
                float3 reflectionDir:TEXCOORD4;
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.objNormal));
                
                TRANSFER_SHADOW(o);

                o.negtive_worldViewDir = - normalize(UnityWorldSpaceViewDir(o.worldPos));
                o.reflectionDir = reflect(o.negtive_worldViewDir, o.worldNormal);
                return o;
            }
            float4 frag(v2f i):SV_TARGET0
            {
                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.rgb;

                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 diffuseColor = _LightColor0 .rgb * _ColorTint * saturate(dot(worldLightDir, i.worldNormal)); 

                fixed3 reflectColor = texCUBE(_Cubemap, i.reflectionDir);
                float fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(i.worldNormal, -i.negtive_worldViewDir), 5);

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                return float4(ambientColor + lerp(diffuseColor, reflectColor, saturate(fresnel)) * atten, 1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
