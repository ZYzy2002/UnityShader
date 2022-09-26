Shader "may/my Tess"
{
    Properties
    {
        _BaseColor ("Base Color",   2D) = "white" {}
        _Tessellation( "tesselation " , Range(1, 64)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain 
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Tessellation.cginc"   //包含一些曲面细分的函数

            sampler2D _BaseColor;
            float4 _BaseColor_ST;
            half _Tessellation;

            struct VSInput
            {
                float4 vertex:      POSITION;
                float3 normal:      NORMAL;
                float4 tangent:     TANGENT;
                float2 uv:          TEXCOORD;
            };
            struct HullInput// also VSOutput
            {
                float4 pos          :POSITION;
                float3 normalMS     :NORMAL;
                float4 tangentMS    :TANGENT;
                float2 uv           :TEXCOORD;
            };
            HullInput vert(VSInput v)
            {
                HullInput o;
                o.pos = v.vertex;
                o.normalMS = v.normal;
                o.tangentMS = v.tangent;
                o.uv = TRANSFORM_TEX(v.uv, _BaseColor);
                return o;
            }
            struct DomainInput
                {
                    float4 pos          :POSITION;
                    float3 normalMS     :NORMAL;
                    float4 tangentMS    :TANGENT;
                    float2 uv           :TEXCOORD;
                };
            //#ifdef UNITY_CAN_COMPILE_TESSELLATION       //检查平台是否支持曲面细分
                //Hull**********************
                [domain("tri")]                         //三角形            tri, quad, isoline
                [partitioning("fractional_odd")]        //切分方式          integer, fractional_even, fractional_odd, pow2.
                [outputtopology("triangle_cw")]         //三角形顺时针      point, line, triangle_cw, triangle_ccw
                [outputcontrolpoints(3)]                //三个控制点        
                [patchconstantfunc("ConstFunction")]    //计算常量数据的函数名
                
                DomainInput hull(InputPatch<HullInput,3> patch, uint pointId : SV_OutputControlPointID)
                {
                    DomainInput o;
                    o.pos = patch [pointId].pos;
                    o.normalMS = patch [pointId].normalMS;
                    o.tangentMS = patch [pointId].tangentMS;
                    o.uv = patch [pointId].uv;
                    return o;
                }
                //Const Function***************************
                struct ConstFuncType
                {
                    float edges[3] : SV_TessFactor;
                    float inside : SV_InsideTessFactor;
                };
                ConstFuncType ConstFunction(InputPatch<HullInput, 3> inputPatch)
                {
                    ConstFuncType o;
                    o.edges[0] = _Tessellation;
                    o.edges[1] = _Tessellation;
                    o.edges[2] = _Tessellation;
                    o.inside = _Tessellation;
                    return o;
                }

                //Domain *************************
                
                struct PSInput
                {
                    float4 pos          :SV_POSITION;
                    float3 normalMS     :NORMAL;
                    float4 tangentMS    :TANGENT;
                    float2 uv           :TEXCOORD;
                };
                [domain("tri")]
                PSInput domain(ConstFuncType i, float3 bary:SV_DOMAINLOCATION, OutputPatch<DomainInput,3> patch)
                {
                    PSInput o;
                    o.pos = patch[0].pos * bary.x + patch[1].pos * bary.y + patch[2].pos * bary.z;                          
                    o.tangentMS = patch[0].tangentMS * bary.x + patch[1].tangentMS * bary.y + patch[2].tangentMS * bary.z;
                    o.normalMS = patch[0].normalMS * bary.x + patch[1].normalMS * bary.y + patch[2].normalMS * bary.z;
                    o.uv = patch[0].uv * bary.x + patch[1].uv * bary.y + patch[2].uv * bary.z;

                    o.pos = UnityObjectToClipPos(o.pos);
                    return o;
                }
            //#endif
            fixed4 frag( PSInput i ):SV_TARGET
            {
                return fixed4(1, 1, 1, 1);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
