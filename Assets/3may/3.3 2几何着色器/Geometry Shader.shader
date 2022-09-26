Shader "may/Geometry Shader"
{
    Properties
    {
        
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

            struct VSIn
            {
                float4 vertex:POSITION;
                fixed3 normal:NORMAL;
            };
            struct VSOut
            {
                float4 pos:POSITION;
            };

            struct GSOut
            {
                float4 pos:SV_POSITION;
            };

            VSOut vert(VSIn v)
            {
                VSOut o;
                o.pos = v.vertex;
                return o;
            }
            
            
            GSOut MakeGSOut(float4 pos)
            {
                GSOut o;
                o.pos = pos ;
                return o;
            }
            [maxvertexcount(6)]
            void geometry(
                triangle VSOut i[3] : SV_POSITION, 
                inout TriangleStream<GSOut> triStream
                )
            {
			    float4 pos = mul(unity_ObjectToWorld, i[0].pos);
                //float4 pos1 = mul(unity_ObjectToWorld, i[1].pos);
                //float4 pos2 = mul(unity_ObjectToWorld, i[2].pos);
				float4 pos1 = pos + float4(1, 0, 0, 0);
                float4 pos2 = pos + float4(0.5, 1, 0, 0);
                pos = UnityWorldToClipPos(pos);
                pos1 = UnityWorldToClipPos(pos1);
                pos2 = UnityWorldToClipPos(pos2);

                triStream.Append(MakeGSOut(pos ));
                triStream.Append(MakeGSOut(pos1));
                triStream.Append(MakeGSOut(pos2 ));
                /*triStream.Append(MakeGSOut(pos ));
                triStream.Append(MakeGSOut(pos1 ));
                triStream.Append(MakeGSOut(pos2 ));*/
			}

            fixed4 frag():SV_TARGET
            {
                return fixed4(1,1,1,1);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
