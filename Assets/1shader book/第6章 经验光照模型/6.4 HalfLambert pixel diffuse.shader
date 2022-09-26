Shader "Chapter6/HalfLambert pixel diffuse"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1.0,1.0,1.0,1.0)
        _Proportion_of_a("a proportion", Range(0,1)) = 0.5
        _Proportion_of_b("b proportion", Range(0,1)) = 0.5
    }
        SubShader
    {
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include"lighting.cginc"
            fixed4 _Diffuse;
            fixed _Proportion_of_a;
            fixed _Proportion_of_b;

            struct a2f
            {
                float4 object_position:POSITION;
                fixed3 object_normal : NORMAL;
            };
            struct v2f
            {
                float4 clip_position:SV_POSITION;
                fixed3 world_normal : COLOR0;
            };

            v2f vert(a2f v_input)
            {
                v2f v_output;
                v_output.world_normal = normalize(mul((float3x3)unity_WorldToObject, v_input.object_normal));   
                v_output.clip_position = UnityObjectToClipPos(v_input.object_position);
                return v_output;
            }
            fixed4 frag(v2f f_input) :SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT;
                fixed3 light_direction = normalize(_WorldSpaceLightPos0);
                fixed3 diffuse = _Diffuse * _LightColor0 
                    * ( saturate(dot(light_direction,f_input.world_normal)) * _Proportion_of_b + _Proportion_of_b);
                return fixed4(diffuse + ambient, 1.0);
            }
            ENDCG
        }// end of first pass
    }
    FallBack "Diffuse"
}
