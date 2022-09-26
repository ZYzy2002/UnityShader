Shader "may/Geometry Grasses"
{
    Properties
    {
        [Header(Grass Color)]
        _GrassBottomColor("Grass Bottom Color",     Color) = (1, 1, 1, 1)
        _GrassTopColor("Grass Top Color",           Color) = (1, 1, 1, 1)
        [Header(Grass Shape)]
        _GrassHight("Grass Hight",                  Range(0.00001, 0.05)) = 0.001
        _GrassWidth("Grass Width",                  Range(0.0005, 0.005)) = 0.005
        _GrassBend("Grass Bend",                    Range(0.0,0.01)) = 0.01
        [Header(Wind)]
        _WindFlowMap("Wind FlowMap",                2D) = "black"{}
        _WindStrength("wind Strength",              2D) = "white"{}
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType"="Opaque" }
        LOD 100
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            Cull  Off 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag 
            #pragma geometry geometry
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _GrassBottomColor;
            fixed4 _GrassTopColor;
            half _GrassHight;
            half _GrassWidth;
            half _GrassBend;
            //extern half PI = 3.1415927;
            sampler2D _WindFlowMap;
            float4 _WindFlowMap_ST;
            sampler2D _WindStrength;

            struct VSIn
            {
                float4 vertex:POSITION;
                fixed3 normalMS:NORMAL;
                fixed4 tangentMS:TANGENT;
                float2 uv:TEXCOORD;
            };
            struct VSOut
            {
                float4 pos:SV_POSITION;
                fixed3 normalMS:TEXCOORD;
                fixed4 tangentMS:TEXCOORD1;
                float2 uv:TEXCOORD2;
            };

            struct GSOut
            {
                float4 pos:SV_POSITION;
                float4 posWS:TEXCOORD;
                float hight :TEXCOORD1;
                float2 uv:TEXCOORD2;
            };



            //vertex shader
            VSOut vert(VSIn v)
            {
                VSOut o;
                o.pos = v.vertex;
                o.normalMS = v.normalMS;
                o.tangentMS = v.tangentMS;
                o.uv = v.uv;
                return o;
            }
            
            //geometry shader
            float rand_1_05(in float2 uv)       // 产生随机数 0 - 1
            {
                float2 noise = frac(sin(dot(uv ,float2(12.9898,78.233)*2.0)) * 43758.5453);
                return abs(noise.x + noise.y) * 0.5;
            }
            [maxvertexcount(7)]
            void geometry(triangle VSOut i[3] : SV_POSITION, inout TriangleStream<GSOut> triStream)
            {
                fixed3 Binormal0 = cross(i[0].normalMS , i[0].tangentMS.xyz ) * i[0].tangentMS.w;
                float3x3 MStoTS = {
                    i[0].tangentMS.xyz, 
                    Binormal0, 
                    i[0].normalMS
                };
                float3x3 TStoMS = transpose(MStoTS);    
                
                //规定草的形状 和 TS 下的位置偏移
                float randomGrassBend  =_GrassBend * (rand_1_05(i[0].uv) * 0.7 + 0.3);
                float randomGrassWidth = _GrassWidth * (rand_1_05(i[0].uv) * 0.4 + 0.6);
                float randomGrassHight = _GrassHight * (rand_1_05(i[0].uv) * 0.8 + 0.2);
                float angle = rand_1_05(i[0].uv) * 2 * 3.14;                                //无法使用 全局变量 PI
                float4x4 ramdomTransform =          //绕草的顶点法线 旋转
                {
                    cos(angle), -sin(angle),0,          0/* rand_1_05(i[1].uv)-0.5*/,
                    sin(angle), cos(angle), 0,          0/* rand_1_05(i[2].uv)-0.5*/,
                    0,          0,          1,          0,
                    0,          0,          0,          1
                };
                float2 windDirWS= tex2Dlod(_WindFlowMap, float4(i[0].uv, 0, 0)).xy * 2.0 -float2(1,1)  ;
                float3 windDirTS = mul(MStoTS , mul(unity_WorldToObject, (float3(windDirWS, 0))) );       //将世界风向 转到 模型 再转到 切线空间 便于草的旋转
                float3 windSpaceXAxis = normalize(float3(windDirTS.xy, 0));         //去掉 风对地吹的分量
                float3 windSpaceZAxis = float3(0, 0, 1), windSpaceYAxis = cross(windSpaceXAxis, windSpaceZAxis);
                float3x3 TangentToWindSpace = { windSpaceXAxis, windSpaceYAxis, windSpaceZAxis};
                float3x3 WindSpaceToTangent = transpose(TangentToWindSpace);

                float3 newPoint[7] = {  //tangent space
                    float3(-randomGrassWidth/2.0 ,   0,              0),
                    float3(randomGrassWidth/2.0,     0,              0),
                    float3(-randomGrassWidth/3.0,    randomGrassBend/6,      _GrassHight/3),
                    float3(randomGrassWidth/3.0,     randomGrassBend/6,      _GrassHight/3),
                    float3(-randomGrassWidth / 6,    randomGrassBend/2,      _GrassHight * 2 / 3),
                    float3(randomGrassWidth / 6,     randomGrassBend/2,      _GrassHight * 2 / 3),
                    float3(0,                   randomGrassBend,         _GrassHight)
                };
                
                
                for(int k = 0;k < 7;k++)
                {
                    GSOut o;
                    o.hight = newPoint[k].y/_GrassHight;    // grass Hight Percentage
                    o.uv = i[0].uv;

                    float3 randomGrassPosTS = mul(ramdomTransform, float4(newPoint[k],1)).xyz;   //切线空间下随机旋转朝向

                    float angle = 3.14 / 6.0 *  tex2Dlod(_WindStrength, float4(o.uv,0,1)).x *(sin(_Time.y)/2+0.5) * o.hight; //最大偏转30度，越矮的地方旋转角度小
                    float3x3 windRotateY =  //wind space 下绕Y轴旋转
                    {
                        cos(angle),     0,      sin(angle),
                        0,              1,      0,
                        -sin(angle),    0,      cos(angle)
                    };
                    randomGrassPosTS = mul(WindSpaceToTangent, mul(windRotateY, mul(TangentToWindSpace, randomGrassPosTS)));
                    
                    float3 posMS = mul(TStoMS, randomGrassPosTS) + i[0].pos;                     //切线转模型空间
                    o.posWS= mul(unity_ObjectToWorld, float4(posMS, 1));   //转到世界空间
                    o.pos = UnityWorldToClipPos(o.posWS);

                    triStream.Append(o);
                }
			}

            fixed4 frag(GSOut i):SV_TARGET
            {
                //diffuse
                fixed3 diffuseColor = lerp(_GrassBottomColor,_GrassTopColor, i.hight);
                return fixed4(diffuseColor,1);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
