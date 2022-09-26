// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "may/Gamma"
{
    Properties
    {
        _Gamma("Gamma" , Range(0.01,10)) = 2.2
    }
    SubShader
    {
        
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase
            float _Gamma;

            struct a2v
            {
                float4 objectPos:POSITION;
                float4 normal:NORMAL;
                float2 uv:TEXCOORD;
            };

            struct v2f
            {
                float4 clipPos:SV_POSITION;
                float2 uv:TEXCOORD1;
            };
            
            v2f vert (a2v v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos( v.objectPos );
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target0    
            {
                float a = pow(i.uv.x, _Gamma);
                return fixed4(a.xxx, 1);
            }
            ENDCG
        }             
    }
}
