Shader "may/XRay Depth Test"
{
    Properties
    {
        _AmbientOcclusion("AO Map",     2D) = "white"{}
        _BaseColor ("Base Color",       2D) = "white" {}
        _ColorTint("Color Tint",        Color) = (1,1,1,1)
        _XRayColor("XRay Color",        Color) = (1,1,1,1)
        _SpecularPow("Specular Pow",    Range(1, 40)) = 8
    }
    SubShader
    {

        CGINCLUDE
        #include "UnityCG.cginc"
        #include "Lighting.cginc"
        #include "AutoLight.cginc"
        sampler2D _AmbientOcclusion;
        float4 _AmbientOcclusion_ST;
        sampler2D _BaseColor;
        float4 _BaseColor_ST;
        fixed4 _ColorTint;
        fixed4 _XRayColor;
        half _SpecularPow;
        struct a2v 
        {
            float4 vertex       :POSITION;
            fixed3 normalMS     :NORMAL;
            float2 uv           :TEXCOORD;
        };
        struct v2f 
        {
            float4 pos          :SV_POSITION;
            fixed3 posWS        :TEXCOORD;
            float4 uv           :TEXCOORD1;
            half3 normalWS      :TEXCOORD2;
            SHADOW_COORDS(3)
        };
        v2f vert(a2v v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.posWS = mul(unity_ObjectToWorld, v.vertex);
            o.uv.xy = TRANSFORM_TEX(v.uv, _AmbientOcclusion);
            o.uv.zw = TRANSFORM_TEX(v.uv, _BaseColor);
            o.normalWS = UnityObjectToWorldNormal(v.normalMS);
            TRANSFER_SHADOW(o)
            return o;
        }
        fixed4 fragRegularBase(v2f i):SV_TARGET0
        {
            fixed3 normalWS = normalize(i.normalWS);
            fixed3 viewDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
            fixed3 lightDirWS = normalize(UnityWorldSpaceLightDir(i.posWS));

            //ambient 
            fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.rgb * tex2D(_AmbientOcclusion, i.uv.xy);

            //diffuse 
            fixed3 albedo = _ColorTint * pow( tex2D(_BaseColor,i.uv.zw), 2.2);      // Gamma correct
            fixed Lambert = max(0, dot(lightDirWS, normalWS));
            fixed3 diffuseColor = albedo * _LightColor0.rgb * Lambert;

            //specular 
            fixed3 halfVector = normalize(viewDirWS + lightDirWS);
            fixed3 specularColor = _LightColor0 * pow( max(0, dot(halfVector, normalWS)), _SpecularPow );

            //shadow
            //fixed atten = SHADOW_ATTENUATION(i);
            UNITY_LIGHT_ATTENUATION(atten, i , i.posWS);

            fixed4 finalColor =  fixed4(ambientColor + (diffuseColor + specularColor) * atten, 1);
            return pow(finalColor, 0.45);     // convert to Gamma4
        }
        fixed4 fragRegularAdd(v2f i):SV_TARGET0
        {
            fixed3 normalWS = normalize(i.normalWS);
            fixed3 viewDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
            fixed3 lightDirWS = normalize(UnityWorldSpaceLightDir(i.posWS));

            //diffuse 
            fixed3 albedo = _ColorTint * pow( tex2D(_BaseColor,i.uv.zw), 2.2);      // Gamma correct
            fixed Lambert = max(0, dot(lightDirWS, normalWS));
            fixed3 diffuseColor = albedo * _LightColor0.rgb * Lambert;

            //specular 
            fixed3 halfVector = normalize(viewDirWS + lightDirWS);
            fixed3 specularColor = _LightColor0 * pow( max(0, dot(halfVector, normalWS)), _SpecularPow );

            //shadow
            UNITY_LIGHT_ATTENUATION(atten, i , i.posWS);

            fixed4 finalColor =  fixed4( (diffuseColor + specularColor) * atten, 1);
            return pow(finalColor, 0.45);     // convert to Gamma4
        }
        fixed4 fragXRay(v2f i):SV_TARGET0
        {
            fixed3 normalWS = normalize(i.normalWS);
            fixed3 viewDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
            fixed3 lightDirWS = normalize(UnityWorldSpaceLightDir(i.posWS));

            fixed fresnel = 1 - dot( viewDirWS , normalWS );

            fixed3 finalColor = _XRayColor.rgb * pow(fresnel, 1);
            return fixed4(finalColor ,1);
        }
        ENDCG

       
        Tags { "Queue" = "Geometry" "RenderType"="Opaque" }
        LOD 100
        
        pass 
        {
            Name "XRay" 
            Tags{"LightMode" = "ForwardBase"}
            ZTest Greater
            ZWrite Off


            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment fragXRay
            ENDCG
        }
        Pass
        {
            Name "RegularBase"
            Tags{"LightMode" = "ForwardBase"}
            ZTest LEqual 

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragRegularBase
            #pragma multi_compile_fwdbase
            ENDCG
        }
        Pass
        {
            Name "RegularAdd"
            Tags{"LightMode" = "ForwardAdd"}
            ZTest LEqual 
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragRegularAdd
            #pragma multi_compile_fwdadd
            ENDCG
        }
    }
    Fallback "Diffuse"
}
