Shader "may/Steep Parallax"
{
    Properties
    {
        _BaseColor  ("BaseColor RGB",   2D) =   "white" {}
        _DepthMap   ("DepthMap 0-1",    2D) =   "white" {}
        _AOmap      ("AO",              2D) =   "white" {}
        _LayNum     ("LayNum",          Range(2,100)) = 5
        _BumpScale  ("BumpScale",       Range(0.0,0.1))  = 0.0001
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "steep"
            Tags {"LightMode" = "ForwardBase"}
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
                TRANSFER_VERTEX_TO_FRAGMENT(o)

                return o;
            }

            float2 POM(float2 texCoords,float3 viewDir)
            {    
                float numLayers = 100;
                float layerDepth = 1.0 / numLayers;
                float currentLayerDepth = 0.0;
                //偏移
                float2 P = viewDir.xy / viewDir.z * _BumpScale;
                //分层
                float2 deltaTexCoords = P / numLayers;
                float2 currentTexCoords = texCoords;
                float currentDepthMapValue = tex2D(_DepthMap, currentTexCoords).r;
                
                while(currentLayerDepth < currentDepthMapValue)
                {                   
                   currentTexCoords += deltaTexCoords;
                   //使用tex2D会因为迭代次数过多报错，因此使用tex2Dlod指定lod
                   currentDepthMapValue = tex2Dlod(_DepthMap, float4(currentTexCoords,0,0)).r;  
                   currentLayerDepth += layerDepth;  
                }
                //POM插值
                float2 prevTexCoords = currentTexCoords - deltaTexCoords;
                float afterDepth  = currentDepthMapValue - currentLayerDepth;
                float beforeDepth = tex2D(_DepthMap, prevTexCoords).r - currentLayerDepth + layerDepth;                  
                float weight = afterDepth / (afterDepth - beforeDepth);
                float2 finalTexCoords = prevTexCoords * weight + currentTexCoords * (1.0 - weight);

                return finalTexCoords;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                
                //diffuse
                fixed stepDepth = 1.0 / _LayNum;
                fixed LayDepth = 0;
                fixed2 deviatedUV = i.uv;
                fixed2 deltaUV = i.viewDirTS.xy / i.viewDirTS.z * _BumpScale;

                while( tex2Dlod(_DepthMap, float4(deviatedUV, 0, 0)).x > LayDepth)
                {
                    LayDepth += stepDepth;
                    deviatedUV += deltaUV;
                }


                fixed3 abedoTex = tex2D(_BaseColor, deviatedUV);
                
                //ambient
                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.xyz * tex2D(_AOmap, deviatedUV);

                fixed atten = LIGHT_ATTENUATION(i);
                return fixed4( ambientColor + abedoTex * atten, 1);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
