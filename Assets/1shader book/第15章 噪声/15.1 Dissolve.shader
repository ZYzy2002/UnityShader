Shader "Chapter15/15.1 Dissolve"
{
    Properties
    {
        _BurnAmount("Burn Amount", Range(0, 1)) = 0.2 
        _BurnLineWidth("Burn Line Width", Range(0, 0.2)) = 0.2
        _MainTex("BaseColor", 2D) = "white"{}
        _Bump("Normal Map", 2D) = "bump"{}
        _BurnFirstColor("Burn First Color", Color) = (1, 0, 0, 1)       //轻度烧灼 黄色
        _BurnSecondColor("Burn Second Color", Color) = (1, 0, 0, 1)     //深度烧灼 褐色
        _NoiseMap("Burn Map", 2D) = "white"{}
    }
    SubShader
    {
        Tags{"Queue" = "AlphaTest" "IgnorePorjector" = "False" "RanderType" = "Opaque" "DisableBatching" = "False"}
        pass 
        {
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma vertex vert 
            #pragma fragment frag 
            #pragma multi_compile_fwdbase
            fixed _BurnAmount;
            fixed _BurnLineWidth;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Bump;
            float4 _Bump_ST;
            fixed4 _BurnFirstColor;
            fixed4 _BurnSecondColor;
            sampler2D _NoiseMap;
            float4 _NoiseMap_ST;

            struct a2v 
            {
                float4 vertex:POSITION;
                fixed3 normal:NORMAL;
                float2 texcoord:TEXCOORD;
                fixed4 tangent:TANGENT;
            };
            struct v2f 
            {
                float4 pos:SV_POSITION;
                float4 worldPos:TEXCOORD0;
                float3 tangentLigthDir:TEXCOORD1;

                float2 uv_MainTex:TEXCOORD2;
                float2 uv_Bump:TEXCOORD3;
                float2 uv_Noise:TEXCOORD4;

                SHADOW_COORDS(5)
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                fixed3 objectBinormal = normalize(cross(v.normal, v.tangent)) * v.tangent.w;
                float3 objectLightDir = ObjSpaceLightDir(v.vertex);
                o.tangentLigthDir = float3(dot(v.tangent, objectLightDir), dot(objectBinormal, objectLightDir), dot(v.normal, objectLightDir));

                o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv_Bump = TRANSFORM_TEX(v.texcoord, _Bump);
                o.uv_Noise = TRANSFORM_TEX(v.texcoord, _NoiseMap);

                TRANSFER_SHADOW(o);
                return o;
            }
            fixed4 frag(v2f i):SV_TARGET0
            {
                fixed4 noiseColor = tex2D(_NoiseMap, i.uv_Noise);
                clip(noiseColor.r - _BurnAmount);
                float3 tangentLightDir = normalize(i.tangentLigthDir);
                float3 tangentNormal;
                tangentNormal.xy = tex2D(_Bump, i.uv_Bump) * 2 - float2(1, 1);
                tangentNormal.z = sqrt(1 - dot(tangentNormal.xy, tangentNormal.xy));

                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.rgb;

                fixed3 adobe = tex2D(_MainTex, i.uv_MainTex) * _LightColor0.rgb;
                fixed3 diffuseColor = adobe * saturate(dot(tangentNormal, tangentLightDir) * 0.5 + 0.5);

                fixed3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, saturate((noiseColor.r - _BurnAmount) / _BurnLineWidth));        //从 烧穿 到 没烧到 是 0 到 1  没烧的地方是 1 
                fixed3 finalColor = lerp(burnColor, diffuseColor, saturate((noiseColor.r - _BurnAmount) / (_BurnLineWidth)));

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                return fixed4( ambientColor + finalColor * atten ,1);
            }
            ENDCG
        }
        pass
        {
            Tags{"LightMode" = "ShadowCaster"}
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert 
            #pragma fragment frag 
            #pragma multi_compile_shadowcaster
            sampler2D _NoiseMap;
            float4 _NoiseMap_ST;
            fixed _BurnAmount;

            struct a2v 
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float2 texcoord:TEXCOORD;
            };
            struct v2f 
            {
                //float4 pos:SV_POSITION;
                float2 uv_Noise:TEXCOORD;

                V2F_SHADOW_CASTER;
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv_Noise = TRANSFORM_TEX(v.texcoord, _NoiseMap);

                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
                return o;
            }
            fixed4 frag(v2f i):SV_TARGET0
            {
                clip(tex2D(_NoiseMap, i.uv_Noise).r - _BurnAmount);
                SHADOW_CASTER_FRAGMENT(i)
            }            
            ENDCG
        }
    }
    FallBack "Diffuse"
}
