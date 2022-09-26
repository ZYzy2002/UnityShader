// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chapter6/per pixel diffuse"//环境光，逐像素漫反射
{
    Properties
    {
        _Diffuse("Diffuse",Color)=(1,1,1,1)
    }


    SubShader
    {
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include"Lighting.cginc"
            fixed4 _Diffuse;

            struct a2f {
                float4 object_position:POSITION;
                fixed3 object_normal:NORMAL;
            };
            struct v2f {
                float4 clip_position:SV_POSITION;
                fixed3 world_normal: COLOR;
            };

            v2f vert(a2f v_input)
            {
                v2f v_output;
                v_output.clip_position = UnityObjectToClipPos(v_input.object_position);

                v_output.world_normal /*here is model normal*/ = normalize(mul((float3x3)unity_WorldToObject , v_input.object_normal));/*here: www.zhihu.com/question/400660113*/
                return v_output;
            }

            fixed4 frag(v2f f_input) :SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT;
                fixed3 light_direction = normalize(_WorldSpaceLightPos0);

                fixed3 diffuse= _LightColor0 * _Diffuse * saturate(dot(light_direction, f_input.world_normal));

                return fixed4(ambient + diffuse,1.f);
            }

            ENDCG
        }//end of the firsh pass

    }
    FallBack "VertexLit"
}
