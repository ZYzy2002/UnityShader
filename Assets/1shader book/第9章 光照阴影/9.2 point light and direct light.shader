// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chapter9/9.2 point light and direct light"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1,1,1,1)
        _Specular("Specular", Color) =(1,1,1,1)
        _Gross("Gross", Range(8.0, 256.0)) = 20
    }
    SubShader
    {
        Tags{"Queue" = "Geometry" "IgnoreProjector" = "False" "RanderType" = "Geometry"}
        pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gross;

            struct a2f
            {
                float4 objPos:POSITION;
                float3 objNormal:NORMAL;
            };
            struct v2f
            {
                float4 clipPos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float4 worldPos:TEXCOORD1;
            };

            v2f vert(a2f v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.objPos);
                o.worldNormal = normalize(mul(unity_WorldToObject, v.objNormal));
                o.worldPos = mul(unity_ObjectToWorld, v.objPos);
                return o;
            }
            float4 frag(v2f f) :SV_TARGET0
            {
                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuseColor = _LightColor0 * _Diffuse * saturate(dot(f.worldNormal, UnityWorldSpaceLightDir(f.worldPos)));

                fixed3 halfVector = normalize(UnityWorldSpaceViewDir(f.worldPos) + UnityWorldSpaceLightDir(f.worldPos));
                fixed3 specularColor = _Specular * _LightColor0 * pow(saturate(dot(halfVector, f.worldNormal)), _Gross);

                fixed atten = 1.0;  //平行光没有衰减
                return float4(ambientColor + (diffuseColor + specularColor) * atten, 1);
            }
            ENDCG
        }// end of base pass

        pass
        {
            Tags{"LightMode" = "ForwardAdd"}
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd

            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gross;

            struct a2f
            {
                float4 objPos:POSITION;
                float3 objNormal:NORMAL;

            };
            struct v2f
            {
                float4 clipPos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float4 worldPos:TEXCOORD1;
                SHADOW_COORDS(2)
            };

            v2f vert(a2f v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.objPos);
                o.worldNormal = normalize(mul(unity_WorldToObject, v.objNormal));
                o.worldPos = mul(unity_ObjectToWorld, v.objPos);
                TRANSFER_SHADOW(o)
                return o;
            }
            float4 frag(v2f f) :SV_TARGET0
            {
               /* #ifdef USING_DIRECTIONAL_LIGHT
                    fixed3 worldLightDir = _WorldSpaceLightPos0.xyz;
                    fixed atten = 1.0;
                #else 
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - f.worldPos);

                    float3 lightCoord = mul(unity_WorldToLight, f.worldPos).xyz;
                    fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).xx  ) .UNITY_ATTEN_CHANNEL;
                #endif
                */

                fixed3 diffuseColor = _LightColor0 * _Diffuse * saturate(dot(f.worldNormal, UnityWorldSpaceLightDir(f.worldPos)));

                fixed3 halfVector = normalize(UnityWorldSpaceViewDir(f.worldPos) + UnityWorldSpaceLightDir(f.worldPos));
                fixed3 specularColor = _Specular * _LightColor0 *  pow(saturate(dot(halfVector, f.worldNormal)), _Gross);

                UNITY_LIGHT_ATTENUATION(a, f, f.worldPos.xyz)
                return float4((diffuseColor + specularColor) * a, 1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
