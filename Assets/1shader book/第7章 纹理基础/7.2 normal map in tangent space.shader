Shader "Chapter7/7.1 normal map in tangent space"
{
    Properties
    {
        _BaseColorOffset("Base Color Tint", Color) = (1,1,1,1)
        _BaseColorMap("Base Color Map", 2D) = "while"{}
        _NormalMap("Normal Map", 2D) = "bump"{}
        _NormalMapScale("Bump Scale", Float) = 1.0

        _Specular("Specular Color", Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256.0)) = 20.0
    }
    SubShader
    {
        pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            float4 _BaseColorOffset;
            sampler2D _BaseColorMap;
            float4 _BaseColorMap_ST;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            float _NormalMapScale;
            float4 _Specular;
            float _Gloss;

            struct a2f
            {
                float4 objectPos:POSITION;
                float3 objectNormal:NORMAL;
                float4 tangent:TANGENT;
                float2 texcoord:TEXCOORD0;
            };
            struct v2f
            {
                float4 clipPos:SV_POSITION;
                float4 uv:TEXCOORD0;            //uv.xy存储 BaseColor Map 的UV  uv.zw存储 NormalMap 的UV
                float3 tangentlightDir:TEXCOORD1;
                float3 tangentviewDir:TEXCOORD2;
            };


            v2f vert(a2f v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos( v.objectPos );
                o.uv.xy = TRANSFORM_TEX( v.texcoord.xy, _BaseColorMap );
                o.uv.zw = TRANSFORM_TEX( v.texcoord.xy, _NormalMap );

                float3x3 obj2tangent =                              //该矩阵是 切线空间 到 模型空间的转置
                {
                    v.tangent.xyz,                                  
                    normalize( cross( v.tangent, v.objectNormal) ),
                    v.objectNormal                                  
                };
                o.tangentlightDir = normalize(mul( obj2tangent, ObjSpaceLightDir(v.objectPos)));    //模型到切线空间
                o.tangentviewDir = normalize(mul( obj2tangent, ObjSpaceViewDir(v.objectPos)));
                
                return o;
            }

            float4 frag(v2f f):SV_TARGET0
            {
                //ambient 
                float4 ambientColor = UNITY_LIGHTMODEL_AMBIENT ;

                //diffuse
                float2 NormalMapSample = tex2D( _NormalMap, f.uv.zw);
                float3 tangentNormalVector ;
                tangentNormalVector.xy =  (tex2D( _NormalMap, f.uv.zw) * 2 -float2(1,1)) * _NormalMapScale;
                tangentNormalVector.z =  sqrt( 1 - dot( tangentNormalVector.xy, tangentNormalVector.xy));
                //tangentNormalVector= UnpackNormal(tex2D( _NormalMap, f.uv.zw));

                float4 diffuseColor = _BaseColorOffset * tex2D(_BaseColorMap, f.uv.xy) * _LightColor0 * saturate(dot( f.tangentlightDir, tangentNormalVector ));
                
                //specular
                float3 halfVector = normalize( f.tangentviewDir + f.tangentlightDir);
                float4 specularColor = _LightColor0 * _Specular * pow( saturate(dot( halfVector, tangentNormalVector )), _Gloss) ;

                return  ambientColor + diffuseColor + specularColor ;
            }

            ENDCG
        }
    }
    FallBack "Specular"
}
