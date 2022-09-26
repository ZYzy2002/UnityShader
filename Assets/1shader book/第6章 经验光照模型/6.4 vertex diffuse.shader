// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chapter6/per vertex diffuse"//环境光，顶点漫反射,高罗德着色，
{
    Properties
    {
        _Diffuse("Diffuse",Color)=(1,1,1,1)
    }




//   SubShader
//   {
//        Pass
//        {
//        Tags{"LightMode"="ForwardBase"}//To make CPU prepare data "_LightColor0"
//        CGPROGRAM
//
//        
//#pragma vertex vert
//#pragma fragment frag
//#include"Lighting.cginc"
//        fixed4 _Diffuse;
//
//        struct a2f {
//            float4 position:POSITION;
//            float3 normal:NORMAL;
//        };
//        struct v2f {
//            float4 pos:SV_POSITION;
//            fixed3 color : COLOR;
//        };
//
//        v2f vert(a2f v)
//        {
//            v2f result;
//            result.pos = UnityObjectToClipPos(v.position);
//
//            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//
//            fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
//            fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
//
//            fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));
//            result.color = ambient + diffuse;
//
//            return result;
//        }
//
//        fixed4 frag(v2f i) :SV_Target{
//            return fixed4(i.color,1.0);
//        }
//
//        ENDCG
//        }
    SubShader
    {
        pass 
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include"Lighting.cginc"
            fixed4 _Diffuse;
            struct a2v
            {
                float4 position:POSITION;
                fixed3 normal : NORMAL;
            };
            struct v2f
            {
                float4 position:SV_POSITION;
                fixed3 color:COLOR;
            };

            //********************
            v2f vert(a2v v_input)
            {
                v2f v_output;
                v_output.position = UnityObjectToClipPos(v_input.position);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT;

                fixed3 vertex_worldnormal = normalize(mul( (float3x3)unity_WorldToObject, v_input.normal));
                fixed3 light_normal = normalize(_WorldSpaceLightPos0);
                fixed3 diffuse_result = _Diffuse * _LightColor0 * saturate( dot(vertex_worldnormal, light_normal));//"saturate" has one parameter， it use to clamp "0~1"

                v_output.color = ambient + diffuse_result;
                return v_output;
            }
            fixed4 frag(v2f f_input) :SV_Target
            {
                return fixed4(f_input.color,1.0);
            }
            //********************

            ENDCG

        }//end of a pass
    }




    FallBack "VertexLit"
}


