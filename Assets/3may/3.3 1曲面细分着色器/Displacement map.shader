Shader "may/Displacement map"
{
    Properties
    {
        _BaseColor ("Base Color Map",           2D) = "white" {}
        _DisplacementMap("Displacement Map",    2D) = "black"{}
        _Hight("Hight",                         Range(0,0.01)) = 0.01
        _Tessellation("Tessellation",           Range(1, 100)) = 10
        _NormalMap("Normal Map",                2D) = "bump"{}

        [Toggle]_use_tess("use Tess", Int) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _USE_TESS_ON
   
            #pragma hull hull 
            #pragma domain domain 

            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Tessellation.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            

            sampler2D _BaseColor;
            float4 _BaseColor_ST;
            sampler2D _DisplacementMap;
            float4 _DisplacementMap_ST;
            float _Hight;
            float _Tessellation;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;

            struct toPS
            {
                float4 vertex       :POSITION;
                float4 tangentMS    :TANGENT;
                float3 normalMS     :NORMAL;
                float2 uv           :TEXCOORD;
            };
            struct VStoHS
            {
                float4 pos              :POSITION;
                float3 lightDirTS       :TEXCOORD;
                float3 viewDirTS        :TEXCOORD1;
                float2 uv_BaseColorMap  :TEXCOORD2;
                float2 uv_DisplaceMap   :TEXCOORD3;
                float2 uv_NormalMap     :TEXCOORD4;
                float3 normalMS         :TEXCOORD5;
                //LIGHTING_COORDS(6,7)
            };
            struct HStoDS
            {
                float4 pos              :POSITION;
                float3 lightDirTS       :TEXCOORD;
                float3 viewDirTS        :TEXCOORD1;
                float2 uv_BaseColorMap  :TEXCOORD2;
                float2 uv_DisplaceMap   :TEXCOORD3;
                float2 uv_NormalMap     :TEXCOORD4;
                float3 normalMS         :TEXCOORD5;
                //SHADOW_COORDS(5)
            };
            
            struct DStoPS
            {
                float4 pos              :POSITION;
                float3 lightDirTS       :TEXCOORD;
                float3 viewDirTS        :TEXCOORD1;
                float2 uv_BaseColorMap  :TEXCOORD2;
                float2 uv_DisplaceMap   :TEXCOORD3;
                float2 uv_NormalMap     :TEXCOORD4;
                float3 normalMS         :TEXCOORD5;
                //LIGHTING_COORDS(5,6)
            };
            
            VStoHS vert(toPS v)
            {
                VStoHS o;
                o.uv_BaseColorMap = TRANSFORM_TEX(v.uv, _BaseColor);
                o.uv_DisplaceMap = TRANSFORM_TEX(v.uv, _DisplacementMap);
                o.uv_NormalMap = TRANSFORM_TEX(v.uv, _NormalMap);

                //v.vertex.xyz += v.normalMS * tex2Dlod(_DisplacementMap, float4(o.uv_DisplaceMap, 0, 1)).xyz * _Hight;
                o.pos = /*UnityObjectToClipPos(*/v.vertex;
                o.normalMS = v.normalMS;
                float3 binormal = cross(v.tangentMS.xyz, v.normalMS) * v.tangentMS.w;
                float3x3 MStoTS = {
                    v.tangentMS.xyz,
                    binormal,
                    v.normalMS
                };
                float3 lightDirMS = ObjSpaceLightDir(v.vertex);
                float3 viewDirMS = ObjSpaceViewDir(v.vertex);
                o.lightDirTS = mul(MStoTS, lightDirMS);
                o.viewDirTS = mul(MStoTS, viewDirMS);

                //TRANSFER_VERTEX_TO_FRAGMENT(o)

                return o;
            }

                [domain("tri")]                         //三角形
                [partitioning("fractional_odd")]        //切分方式
                [outputtopology("triangle_cw")]         //三角形顺时针
                [outputcontrolpoints(3)]                //三个控制点
                [patchconstantfunc("ConstFunction")]    //计算常量数据的函数名
                
                HStoDS hull(InputPatch<VStoHS,3> patch, uint pointId : SV_OutputControlPointID)
                {
                    HStoDS o;
                    o.pos = patch [pointId].pos;
                    o.lightDirTS = patch [pointId].lightDirTS;
                    o.viewDirTS = patch [pointId].viewDirTS;
                    o.uv_BaseColorMap = patch [pointId].uv_BaseColorMap;
                    o.uv_DisplaceMap = patch [pointId].uv_DisplaceMap;
                    o.uv_NormalMap = patch [pointId].uv_NormalMap;
                    o.normalMS      = patch [pointId].normalMS;
                    
                    return o;
                }
                //Const Function***************************
                struct ConstFuncType
                {
                    float edges[3] : SV_TessFactor;
                    float inside : SV_InsideTessFactor;
                };
                ConstFuncType ConstFunction(InputPatch<VStoHS, 3> inputPatch)
                {
                    ConstFuncType o;
                    o.edges[0] = _Tessellation;
                    o.edges[1] = _Tessellation;
                    o.edges[2] = _Tessellation;
                    o.inside = _Tessellation;
                    return o;
                }

                [domain("tri")]
                DStoPS domain(ConstFuncType i, float3 bary:SV_DOMAINLOCATION, OutputPatch<HStoDS,3> patch)
                {
                    DStoPS o;                         
                    o.lightDirTS = patch[0].lightDirTS * bary.x + patch[1].lightDirTS * bary.y + patch[2].lightDirTS * bary.z;
                    o.viewDirTS = patch[0].viewDirTS * bary.x + patch[1].viewDirTS * bary.y + patch[2].viewDirTS * bary.z;
                    o.uv_BaseColorMap = patch[0].uv_BaseColorMap * bary.x + patch[1].uv_BaseColorMap * bary.y + patch[2].uv_BaseColorMap * bary.z;
                    o.uv_DisplaceMap = patch[0].uv_DisplaceMap * bary.x + patch[1].uv_DisplaceMap * bary.y + patch[2].uv_DisplaceMap * bary.z;
                    o.uv_NormalMap = patch[0].uv_NormalMap * bary.x + patch[1].uv_NormalMap * bary.y + patch[2].uv_NormalMap * bary.z;
                    o.normalMS = patch[0].normalMS * bary.x + patch[1].normalMS * bary.y + patch[2].normalMS * bary.z;
                    o.pos = patch[0].pos * bary.x + patch[1].pos * bary.y + patch[2].pos * bary.z;
                    o.pos += tex2Dlod(_DisplacementMap, float4(o.uv_DisplaceMap, 0, 1)) * _Hight * float4(o.normalMS, 1);
                    o.pos = UnityObjectToClipPos(o.pos);
                    return o;
                }

            fixed4 frag(DStoPS i):SV_TARGET
            {
                fixed3 lightDirTS = normalize(i.lightDirTS);
                fixed3 viewDirTS = normalize(i.viewDirTS);
                fixed3 normalTS = UnpackNormal(tex2D(_NormalMap,i.uv_NormalMap));

                //diffuse 
                fixed3 albedo = tex2D(_BaseColor, i.uv_BaseColorMap);
                fixed3 diffuseColor = albedo * _LightColor0 * max(0, dot(lightDirTS, normalTS));

                return fixed4(diffuseColor,1);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
