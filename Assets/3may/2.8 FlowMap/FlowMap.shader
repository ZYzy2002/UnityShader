Shader "may/FlowMap"
{
    Properties
    {
        _ColorTint ("Color Tint",       Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)",       2D) = "white" {}

        _FlowMap("Flow Map",            2D) = "black"{}
        _FlowSpeed ("Flow Speed",       Range(0,10)) = 0.5
        _FlowStrength("Flow Strength",  Range(0.001, 10)) = 1

        [Toggle] _reverse_flow ("inverse flow dir ", Int) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        pass
        {
            Name "FlowMap"
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma vertex vert
            #pragma fragment frag 
            #pragma multi_compile_fwdbase
            #pragma shader_feature _REVERSE_FLOW_ON
            fixed4 _ColorTint;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _FlowMap;
            float4 _FlowMap_ST;
            half _FlowSpeed;
            half _FlowStrength;

            struct a2v 
            {
                float4 vertex:POSITION;
                float2 uv:TEXCOORD;
            };
            struct v2f 
            {
                float4 pos:SV_POSITION;
                float4 uv:TEXCOORD;
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _FlowMap);
                return o;
            }
            fixed4 frag(v2f i):SV_TARGET0
            {
                half2 uvoffset = tex2D(_FlowMap, i.uv.zw) *2 - half2(1, 1);
                #ifdef _REVERSE_FLOW_ON
                uvoffset*=-1;
                #endif
                uvoffset *= _FlowStrength;
                fixed function1 = frac(_Time.y * _FlowSpeed );                      //偏移程度1
                fixed function2 = frac(_Time.y * _FlowSpeed + 0.5);              //偏移程度2
                fixed3 texColor1 = tex2D(_MainTex, i.uv.xy + uvoffset * function1);    
                fixed3 texColor2 = tex2D(_MainTex, i.uv.xy + uvoffset * function2);
                fixed3 baseColorTex = lerp(texColor1, texColor2, abs(function1 - 0.5) * 2 );

                return fixed4( baseColorTex , 1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
