Shader "Chapter14/14.1 ToonShading"
{
    Properties
    {
        _Color("ColorTint", Color) = (1,1,1,1)
        _MainTex("Main Tex", 2D) = "white"{}
        _Ramp("Ramp Tex", 2D) = "white"{}       //渐变纹理

        _Outline("Outline", Range(0, 1)) = 0.05  //描边宽度
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)

        _Specular("Specular", Color) = (1, 1, 1, 1)     //高光颜色
        _SpecularScale("Specular", Range(0, 0.1)) = 0.01
    }
    SubShader
    {
        pass        //沿法线扩展模型（观察空间在xy方向） 进行描边
        {
            Name "OUTLINE"
            Tags{}
            Cull Front 
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag 
            fixed4 _Color;
            sampler2D _MainTex;
            sampler2D _Ramp;
            fixed _Outline;
            fixed4 _OutlineColor;
            fixed4 _Specular;
            fixed _SpecularScale;

            struct a2v
            {
                float4 vertex:POSITION;
                half3 normal:NORMAL;
            };
            float4 vert(a2v v):SV_POSITION
            {
                float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
                float4 viewNormal = mul(UNITY_MATRIX_MV, v.normal);
                viewNormal.z = 0;
                viewNormal = normalize(viewNormal);
                pos += viewNormal * _Outline;
                pos = mul(UNITY_MATRIX_P, pos);
                return pos;
            }
            fixed4 frag():SV_TARGET0
            {
                return _OutlineColor;
            }
            ENDCG
        }
        pass        //原模型着色
        {
            Tags{"LightMode" = "ForwardBase"}
            Cull Back 

            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma vertex vert 
            #pragma fragment frag 
            #pragma multi_compile_fwdbase 
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
            float4 _Ramp_ST;
            fixed _Outline;
            fixed4 _OutlineColor;
            fixed4 _Specular;
            fixed _SpecularScale;

            struct a2v 
            {   
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float2 texcoord:TEXCOORD0;
            };
            struct v2f 
            {
                float4 pos:SV_POSITION;
                float4 worldPos:TEXCOORD0;
                float3 worldNor:TEXCOORD1;
                float4 uv:TEXCOORD2;        //xy is used for _MainTex ,zw for _Ramp

                SHADOW_COORDS(3)
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNor = UnityObjectToWorldNormal(v.normal);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _Ramp);

                TRANSFER_SHADOW(o);

                return o;
            }
            fixed4 frag(v2f i):SV_TARGET0
            {
                fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT.rgb;

                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed diff = 0.5 * saturate(dot(lightDir, i.worldNor)) + 0.5;
                fixed3 diffuseColor = _LightColor0.rgb * _Color * tex2D(_Ramp, diff.xx) /**saturate(dot(lightDir, i.worldNor) + 0.2)*/;

                fixed3 worldNor = normalize(i.worldNor);
                fixed3 halfVec = normalize(normalize(UnityWorldSpaceViewDir(i.worldPos)) + lightDir);
                fixed3 specularColor = _Specular.rgb * smoothstep(0.97, 0.98, dot(halfVec, i.worldNor));

                /*fixed3 worldNor = i.worldNor;
                fixed spec = dot(worldNor, halfVec);
                fixed w = fwidth(spec) * 2;
                fixed3 specularColor = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1))* step(0.0001, _SpecularScale);*/

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                return fixed4(ambientColor + (diffuseColor + specularColor) * atten, 1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}


//注：  官方案例，物体阴影部分出现高光（由于specular 没乘atten）