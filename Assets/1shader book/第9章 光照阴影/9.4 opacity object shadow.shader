

Shader "Chapter9/9.4 opacity object shadow"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1,1,1,1)
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8, 256)) = 20
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase

            #pragma vertex vert 
            #pragma fragment frag 
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            
            struct a2v
            {
                float4 vertex:POSITION;
                float3 objNormal:NORMAL;
            };
            struct v2f
            {
                float4 pos:SV_POSITION;
                float4 worldPos:TEXCOORD0;
                float3 worldNormal:TEXCOORD1;
                SHADOW_COORDS(2)
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = normalize(mul(unity_WorldToObject,v.objNormal));
                TRANSFER_SHADOW(o);
                return o;
            }
            float4 frag(v2f i):SV_TARGET0
            {
                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuseColor = _LightColor0 * _Diffuse.rgb * saturate(dot( i.worldNormal, worldLightDir)); 

                fixed3 halfVector = normalize(worldLightDir + UnityWorldSpaceViewDir(i.worldPos));
                fixed3 specularColor = _LightColor0 * _Specular.rgb * pow(saturate(dot(halfVector, i.worldNormal)), _Gloss);

                fixed shadowTint = SHADOW_ATTENUATION(i);
                fixed atten = 1;
                return float4(ambientColor + (diffuseColor + specularColor) * shadowTint * atten , 1);
            }
            ENDCG
        }
        pass
        {
            Tags{"LightMode" = "ForwardAdd"}
            Blend One One
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdadd

            #pragma vertex vert 
            #pragma fragment frag 
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            
            struct a2v
            {
                float4 vertex:POSITION;
                float3 objNormal:NORMAL;
            };
            struct v2f
            {
                float4 pos:SV_POSITION;
                float4 worldPos:TEXCOORD0;
                float3 worldNormal:TEXCOORD1;
                SHADOW_COORDS(2)
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = normalize(mul(unity_WorldToObject,v.objNormal));
                TRANSFER_SHADOW(o);
                return o;
            }
            float4 frag(v2f i):SV_TARGET0
            {
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                    fixed atten = 1.0;
                #else 
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);

                    float3 lightCoord = mul(unity_WorldToLight, i.worldPos).xyz;
                    fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).xx  ) .UNITY_ATTEN_CHANNEL;
                #endif

                fixed3 diffuseColor = _LightColor0 * _Diffuse.rgb * saturate(dot( i.worldNormal, worldLightDir)); 

                fixed3 halfVector = normalize(worldLightDir + UnityWorldSpaceViewDir(i.worldPos));
                fixed3 specularColor = _LightColor0 * _Specular.rgb * pow(saturate(dot(halfVector, i.worldNormal)), _Gloss);

                fixed shadowTint = SHADOW_ATTENUATION(i);
                return float4( (diffuseColor + specularColor) * shadowTint * atten, 1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}

