// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Chapter10/10.1 refraction"
{
    Properties
    {
       _ColorTint("Color Tint", Color) = (1,1,1,1)
       _RefractionColorTint("Refraction Color Tint", Color) = (1,1,1,1)
       _RefractionAmount("Refraction Amount", Range(0,1)) = 1
       _RefractionRate("Refraction Rate", Range(0.01, 1)) = 0.5   //’€…‰¬ 
       _Cubemap("Cubemap refraction", Cube) = "_Skybox"{}
    }
    SubShader
    {
        Tags{"Queue" = "Geometry"}
        pass
        {
            Tags{"LightMode" = "ForwardBase"}
            ZWrite On

            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma vertex vert
            #pragma fragment frag 
            #pragma multi_compile_fwdbase
            fixed4 _ColorTint;
            fixed4 _RefractionColorTint;
            float _RefractionAmount;
            fixed _RefractionRate;
            samplerCUBE _Cubemap;

            struct a2f
            {
                float4 vertex:POSITION;
                fixed3 objNormal:NORMAL;
            };
            struct v2f 
            {
                float4 pos:SV_POSITION;
                float4 worldPos:TEXCOORD0;
                fixed3 worldNormal:TEXCOORD1;
                fixed3 refractDir:TEXCOORD2;
                SHADOW_COORDS(3)
            };
            v2f vert(a2f v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.objNormal));
                o.refractDir = refract(-UnityWorldSpaceViewDir(o.worldPos), o.worldNormal, _RefractionRate);
                TRANSFER_SHADOW(o);
                return o;
            }
            float4 frag(v2f i):SV_TARGET0
            {
                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.rgb;

                fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPos);
                fixed3 diffuseColor = _LightColor0.rgb * _ColorTint.rgb * saturate(dot(i.worldNormal, worldLightDir));

                fixed3 sampleDir = i.refractDir;
                fixed3 refractionColor = texCUBE(_Cubemap, sampleDir) * _RefractionColorTint.rgb;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                //fixed atten = SHADOW_ATTENUATION(i);
                return float4(ambientColor + lerp(diffuseColor,refractionColor,_RefractionAmount) * (atten * 0.5 + 0.5), 1);
            }
            ENDCG
        }
        
    }
    FallBack "Diffuse"
}
