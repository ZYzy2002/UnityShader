Shader "zd/Smooth Plastic"
{
    Properties
    {
        _AmbientColor( "Ambient Color", Color) = (0.2,0.2,0,1)
        _PlasticColor ("Plastic Color", Color) = (1,1,1,1)
        _SpecularColorTint("Specular Color Tint", Color) = (1,1,1,1)
        _SpecularPow("Specular Pow", Range(1, 30)) = 8
    }
    SubShader
    {
        Tags { "Queue" = "Geometry"  "RenderType"="Opaque" }
        LOD 200

        pass
        {
            Name "Smooth Plastic"
            Tags {"LightMode" = "ForwardBase"} 
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma vertex vert 
            #pragma fragment frag 
            #pragma multi_compile_fwdbase 

            fixed4 _PlasticColor;
            fixed4 _SpecularColorTint;
            half _SpecularPow;
            fixed4 _AmbientColor;

            struct a2v 
            {
                float4 vertex:POSITION;
                fixed3 normalMS:NORMAL;
            };
            struct v2f 
            {
                float4 pos:SV_POSITION;
                float4 posWS:TEXCOORD;
                float3 normalWS:TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.normalWS = UnityObjectToWorldNormal(v.normalMS);
                return o;
            }
            fixed4 frag(v2f i):SV_TARGET0
            {
                fixed3 normalWS = normalize(i.normalWS);
                fixed3 viewDirWS = UnityWorldSpaceViewDir(i.posWS);
                fixed3 lightDirWS = UnityWorldSpaceLightDir(i.posWS);
                fixed frensel = 1 - dot(normalWS, viewDirWS);

                //ambient 
                fixed3 ambientColor = _AmbientColor.rgb;

                //diffuse 
                fixed3 diffuseColor = _LightColor0 * _PlasticColor * max(0 , dot(normalWS, lightDirWS));

                //specular 
                fixed3 halfVector = normalize(viewDirWS + lightDirWS);
                fixed3 specularColor = _SpecularColorTint * _LightColor0 * pow( max(0, dot(halfVector, normalWS)), _SpecularPow);

                fixed3 finalColor = ambientColor + diffuseColor + specularColor ;
                return fixed4(finalColor,1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}

