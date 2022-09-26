// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chapter9/9.4 translusent object shadow"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1,1,1,1)
        _MainTex("BCMap and Alpha", 2D) = "white"{}
        _Cutoff("Cutoff", Range(-1, 1)) = 0
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss" ,Range(8.0, 256.0)) = 20
    }
    SubShader
    {
        Tags{"Queue" = "AlphaTest" "IgnoreProjector" = "True" "RanderTarget" = "AlpahTest"}
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            ZWrite On
            CGPROGRAM
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "autoLight.cginc"
            #pragma multi_compile_fwdbase
            #pragma vertex vert 
            #pragma fragment frag 
            fixed4 _Diffuse;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Cutoff;
            fixed4 _Specular;
            float _Gloss;

            struct a2f
            {
                float4 vertex:POSITION;
                fixed3 objNor:NORMAL;
                float4 texcoord:TEXCOORD;
            };
            struct v2f
            {
                float4 pos:SV_POSITION;
                float4 worldPos:TEXCOORD0;
                fixed3 worldNor:TEXCOORD1;
                float2 uv:TEXCOORD2;
                SHADOW_COORDS(3)
                
            };
            v2f vert(a2f v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNor = normalize(mul(unity_WorldToObject, v.objNor));
                TRANSFER_SHADOW(o);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }
            float4 frag(v2f i):SV_TARGET0
            {
                fixed4 sampleFromTex = tex2D(_MainTex, i.uv);
                clip(sampleFromTex.a - _Cutoff);

                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 diffuseColor = _LightColor0 * sampleFromTex.rgb * saturate(dot(i.worldNor, worldLightDir));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfVector = normalize(worldViewDir + worldViewDir);
                fixed3 specularColor = _LightColor0 * _Specular * pow(saturate(dot(i.worldNor, halfVector)), _Gloss);


                fixed shadow = SHADOW_ATTENUATION(i);
                fixed atten = 1.0;
                
                return float4(ambientColor + (diffuseColor + specularColor) * shadow * atten, 1);
            }
            ENDCG
        }
    }
    FallBack "VertexLit"
}
