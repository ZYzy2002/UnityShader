Shader "may/normal map"
{
    Properties
    {
        _BaseColor  ("����ɫRGB", 2D)   = "white"{}
        _normalMap  ("������ͼ", 2D)    = "bump" {}
        _AOmap      ("�������ڱ�", 2D)  = "white"{}
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType"="Opaque"  "IgnoreProjector" = "True" "DisableBatching" = "False" }
        LOD 100

        Pass
        {
            Name "Normal Map"
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            sampler2D _normalMap;
            float4 _normalMap_ST;
            sampler2D _BaseColor;
            float4 _BaseColor_ST;
            sampler2D _AOmap;
            float4 _AOmap_ST;

            struct a2v 
            {
                float4 vertex:POSITION;
                float4 uv:TEXCOORD;
                float3 normalMS:NORMAL;
                float4 tangentMS:TANGENT;
            };
            struct v2f 
            {
                float4 pos:SV_POSITION;
                float2 uvBC:TEXCOORD;
                float2 uvNor:TEXCOORD5;
                float2 uvAO:TEXCOORD6;
                fixed3 viewDirTS:TEXCOORD1;
                fixed3 lightDirTS:TEXCOORD2;
                LIGHTING_COORDS(3, 4)
                //SHADOW_COORDS(3)
                //float4 posWS:TEXCOORD6;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.uvBC = TRANSFORM_TEX(v.uv, _BaseColor);
                o.uvNor = TRANSFORM_TEX(v.uv, _normalMap);
                o.uvAO = TRANSFORM_TEX(v.uv, _AOmap);

                float3 viewDirMS = normalize(ObjSpaceViewDir(v.vertex));
                float3 lightDirMS = normalize(ObjSpaceLightDir(v.vertex));
                float3 BinormalMS = cross(v.normalMS, v.tangentMS.xyz) * v.tangentMS.w;
                float3x3 ModelToTangent  =
                {
                    v.tangentMS.xyz,
                    BinormalMS,
                    v.normalMS      
                };
                o.viewDirTS = normalize( mul(ModelToTangent, viewDirMS) );
                o.lightDirTS = normalize( mul(ModelToTangent, lightDirMS) );

                TRANSFER_VERTEX_TO_FRAGMENT(o)
                //TRANSFER_SHADOW(o)

                //o.posWS = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }
            fixed4 frag(v2f i):SV_TARGET0
            {
                fixed3 normalTex = UnpackNormal(tex2D(_normalMap, i.uvBC));
                fixed3 baseColorTex = tex2D(_BaseColor, i.uvNor);
                fixed3 AO = tex2D(_AOmap, i.uvAO);
                //ambient 
                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.xyz * AO;

                //diffuse
                fixed lambert = saturate(dot(normalTex, i.lightDirTS));
                fixed3 diffuseColor = _LightColor0 *baseColorTex * lambert;

                fixed atten = LIGHT_ATTENUATION(i);
                //UNITY_LIGHT_ATTENUATION(atten, i, i.posWS);
                return fixed4( ambientColor + diffuseColor * atten, 1);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
