Shader "may/Steep Normal"
{
    Properties
    {
        _BaseColor  ("BaseColor RGB",   2D) =   "white" {}
        _DepthMap   ("DepthMap 0-1",    2D) =   "white" {}
        _AOmap      ("AO",              2D) =   "white" {}
        _LayNum     ("LayNum",          Range(2,500)) = 100
        _BumpScale  ("BumpScale",       Range(0.0,0.1))  = 0.0001
        _NormalMap  ("Normal Map",      2D) = "bump"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "steep"
            Tags {"LightMode" = "ForwardBase" "RenderType" = "Opaque"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _BaseColor;
            float4 _BaseColor_ST;
            sampler2D _DepthMap;
            float4 _DepthMap_ST;
            sampler2D _AOmap;
            float4 _AOmap_ST;
            float _LayNum;
            fixed _BumpScale;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;

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
                float2 uv:TEXCOORD;
                fixed3 viewDirTS:TEXCOORD3;
                LIGHTING_COORDS(4,5)
                float4 posWS:TEXCOORD6;
                fixed3 lightDirTS:TEXCOORD7;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;

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

                return o;
            }

            
            fixed4 frag (v2f i) : SV_Target
            {   
                
                //uv  deviate
                fixed stepDepth = 1.0 / _LayNum;
                fixed LayDepth = 0;
                fixed2 deviatedUV = i.uv;
                fixed2 deltaUV = i.viewDirTS.xy / i.viewDirTS.z * _BumpScale;

                while( tex2Dlod(_DepthMap, float4(deviatedUV, 0, 0)).x > LayDepth)
                {
                    LayDepth += stepDepth;
                    deviatedUV += deltaUV;
                }
                // parameter
                fixed3 normalTS = UnpackNormal(tex2D(_NormalMap, deviatedUV));
                fixed3 lightDirTS = normalize(i.lightDirTS);
                fixed3 viewDirTS = normalize(i.viewDirTS);


                //ambient
                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.xyz * tex2D(_AOmap, deviatedUV);

                //diffuse
                fixed3 abedoTex = tex2D(_BaseColor, deviatedUV);
                fixed3 diffuseColor = abedoTex * _LightColor0 * max(0, dot(lightDirTS, normalTS));
                
                
                fixed atten = LIGHT_ATTENUATION(i);
                return fixed4( ambientColor + diffuseColor * atten, 1);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
