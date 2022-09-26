Shader "may/TESS"
{
    Properties
    {
        //细分数
        _TessellationUniform ("Tessellation Uniform", Range(1,64)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            
            //1.1定义Hull Shader 以及 Domain Shader
            #pragma hull hullProgram 
            #pragma domain ds
            
            #pragma vertex tessvert
            #pragma fragment frag
            #pragma target 5.0
            #include "UnityCG.cginc"
            
            //1.2曲面细分的头文件，其中包含很多有用的辅助函数
            #include "Tessellation.cginc"
            //2.1 定义输入到曲面细分着色器的结构体 及 输出到片元的结构体
            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct VertexOutput
            {
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            //2.2 应用在domain函数中，用来进行空间转换 
            VertexOutput vert (VertexInput v) 
            {
                VertexOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = v.normal;
                o.tangent = v.tangent;
                return o;
            }
            //3.1 TESS并不是所有平台都支持，定义一个宏来保证在不支持的硬件上面不会报错
            #ifdef UNITY_CAN_COMPILE_TESSELLATION
                //3.2 定义顶点着色器结构体
                struct TessVertex {
                    float4 vertex : INTERNALTESSPOS;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                    float2 uv : TEXCOORD0;
                };
                
                //3.3 定义path用于Hull Shader
                struct OutputPatchConstant { 
                    //Tessellation Factor和Inner Tessellation Factor来定义细分数量
                    //不同的图元结构体也会不同，此处3为三角形
                    float edge[3] : SV_TESSFACTOR;  
                    float inside : SV_INSIDETESSFACTOR;
                };
                //3.4 顶点着色器函数
                //此处没有进行空间转换，只是把信息传到曲面细分着色器中
                TessVertex tessvert (VertexInput v) { 
                    TessVertex o;
                    o.vertex = v.vertex;
                    o.normal = v.normal;
                    o.tangent = v.tangent;
                    o.uv = v.uv;
                    return o;
                }

                //4. 定义曲面细分的参数
                float _TessellationUniform;
                OutputPatchConstant hsconst (InputPatch<TessVertex,3> patch) {
                    //定义曲面细分的参数
                    OutputPatchConstant o;
                    o.edge[0] = _TessellationUniform;
                    o.edge[1] = _TessellationUniform;
                    o.edge[2] = _TessellationUniform;
                    o.inside = _TessellationUniform;
                    return o;
                }

                //5.1 定义hull shader函数
                [UNITY_domain("tri")]//确定图元，quad、triangle等
                [UNITY_partitioning("fractional_odd")]//edge的切分规则
                //输出三角形，按顺时针还是逆时针组装，影响最后显示，正面剔除或背面剔除
                [UNITY_outputtopology("triangle_cw")]
                //规定这一个patch的曲面细分的属性，一个patch有三个点，这三个点共用这个函数
                [UNITY_patchconstantfunc("hsconst")]
                //定义控制点，不同的图元数量不同，此处为三角形
                [UNITY_outputcontrolpoints(3)]
                
                //5.2 hull函数实现
                TessVertex hullProgram (InputPatch<TessVertex,3> patch,uint id : SV_OutputControlPointID) { 
                    return patch[id];
                }

                //6.1 定义Domian Shader函数
                [UNITY_domain("tri")]//同样需要定义图元
                //6.2  Domian实现 进行空间转换,将切线空间下的顶点转换至模型空间
                VertexOutput ds (OutputPatchConstant tessFactors, const OutputPatch<TessVertex,3> patch,float3 bary : SV_DOMAINLOCATION) //bary：重心空间下的顶点位置信息
                {
                    VertexInput v;
                    v.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
                    v.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
                    v.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
                    v.uv = patch[0].uv * bary.x + patch[1].uv * bary.y + patch[2].uv * bary.z;
                    VertexOutput o = vert(v);
                    return o;

                }
            #endif
            //最后片元着色输出
            fixed4 frag (VertexOutput i) : SV_Target
            {
                return float4(1.0,1.0,1.0,1.0);
            }
            ENDCG
        }
    }
}