Shader "may/SSAO"
{
    Properties
    {
        _MainTex("Source Tex", 2D) = "white"{}
        
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        pass
        {
            Blend Off
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag 
            #include "UnityCG.cginc"
            sampler2D _MainTex;
            sampler2D _CameraDepthNormalsTexture;   //深度法线图
            
            float4x4 _Matrix_IP;    //逆矩阵
            float4x4 _Matrix_P;
            int _SampleCount;       //半球采样点数量
            float _SampleRadius;    //半球半径
            fixed4 _AOColor;        //ao的颜色，默认黑色

            struct a2v 
            {
                float4 vertex:POSITION;
                float2 uv:TEXCOORD;
            };
            struct v2f 
            {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD;
            };
            
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float RandomFloat(float2 uv)    //随机
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }
            float3 RandomFloat3(float2 uv)  //随机向量  单位随机向量 * [-1,1]
            {
                float3 ranVector;
                ranVector.x = RandomFloat(uv) * 2 - 1;
                ranVector.y = RandomFloat(uv*uv) * 2 - 1;
                ranVector.z = RandomFloat(uv*uv*uv) * 2 - 1;
                return normalize(ranVector);
            }

            fixed4 frag(v2f i):SV_TARGET
            {
                //重建世界坐标
                float depthTex =  DecodeFloatRG(tex2D(_CameraDepthNormalsTexture, i.uv).zw);
                float3 normalVS = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, i.uv));
                float4 posNDC = float4(i.uv.x * 2 -1, i.uv.y * 2 -1, depthTex * 2 - 1, 1);
                float4 posVS = mul(_Matrix_IP, posNDC);
                posVS = posVS / posVS.w;


                //在观察空间，定义一个切线空间
                float3 tangentVS = RandomFloat3(i.uv);
                float3 binormalVS = normalize(cross(tangentVS, normalVS));
                tangentVS = cross(normalVS, binormalVS);
                float3x3 ViewSpaceToTangentSpace = {tangentVS, binormalVS, normalVS};
                float3x3 TangentSpaceToViewSpace = transpose(ViewSpaceToTangentSpace);


                int count = 0;  // 没被遮挡采样点数
                for(int k = 0; k < _SampleCount; k++)
                {
                    float3 randomVector = RandomFloat3(i.uv * (k+1) );                              //偏移量，像素的切线空间 ,注意要保证每次循环产生的向量不同（所以乘k）
                    randomVector.z =abs( randomVector.z ) * 0.8 +0.2;                             //切线空间，偏移量，分量范围: [-1, 1], [-1, 1], [0, 1]
                    randomVector = mul(TangentSpaceToViewSpace, randomVector);
                    randomVector *= _SampleRadius;
                    
                    float4 SamplerPointPosVS = posVS + float4(randomVector, 0); //采样点，相机空间
                    float4 SamplerPointPosCS = mul(_Matrix_P, SamplerPointPosVS);
                    float4 SamplerPointPosNDC = SamplerPointPosCS / SamplerPointPosCS.w;
                    float2 SamplerPointUV = (SamplerPointPosNDC.xy + 1) / 2;

                    float Depth = DecodeFloatRG(tex2D(_CameraDepthNormalsTexture, SamplerPointUV).zw);
                    float4 ndc = float4( SamplerPointUV * 2 -1, Depth * 2 - 1,  1);
                    float4 vs = mul(_Matrix_IP, ndc);
                    vs /= vs.w;

                    if( (-vs.z) - (-SamplerPointPosVS.z) > 0 || (-SamplerPointPosVS.z) - (-vs.z) > _SampleRadius )        // 场景深度图的深度  大于  采样点深度（未被遮挡）   或    采样点深度 大于 场景深度 很多（被遮挡，但是是错开的物体）
                    {
                        count++;
                    }
                }

                //float4 rowTex = tex2D(_MainTex, i.uv);

                fixed ao= float(count)/_SampleCount;
                return lerp( _AOColor, fixed4(1, 1, 1, 1), ao);//          (1-ao)*_AOColor + ao * fixed4(1, 1, 1, 1);    ao做出的遮罩 * ao颜色 + 非ao区域 * 白色
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
