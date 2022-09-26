// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chapter10/10.1 reflection"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _ReflectColor("Reflection Color", Color) = (1,1,1,1)        //反射颜色
        _ReflectAmount("Reflect Amount", Range(0, 1)) =1            //反射程度
        _CubeMap("Reflection Cubemap", Cube) = "_Skybox"{}
    }
    SubShader
    {
        Pass
        {   
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase
            #pragma vertex vert 
            #pragma fragment frag 
            fixed4 _Color;
            fixed4 _ReflectColor;
            fixed _ReflectAmount;
            samplerCUBE _CubeMap;

            struct a2f
            {
                float4 vertex:POSITION;
                fixed3 objNor:NORMAL;
            };
            struct v2f
            {
                float4 pos:SV_POSITION;
                float4 worldPos:TEXCOORD0;
                fixed3 worldNor:TEXCOORD1;
                fixed3 worldRefl:TEXCOORD2;
            };

            v2f vert(a2f v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNor = normalize(UnityObjectToWorldNormal(v.objNor));
                //o.worldNor = normalize(mul(unity_WorldToObject, v.objNor));

                fixed3 worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.worldRefl = reflect(-worldViewDir, o.worldNor);
                
                return o;
            }

            float4 frag(v2f i):SV_TARGET0
            {
                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.rgb;

                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0);
                fixed3 diffuseColor = _LightColor0 * _Color.xyz * saturate(dot(i.worldNor, worldLightDir));

                fixed3 reflectionColor = texCUBE(_CubeMap, i.worldRefl.xyz) *_ReflectColor.rgb;

                return float4(ambientColor + lerp(diffuseColor, reflectionColor , _ReflectAmount), 1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
