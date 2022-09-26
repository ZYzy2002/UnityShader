Shader "zd/掉漆金属"
{
    Properties
    {
        _MetalDomain("金属的范围", Range(0, 1)) = 0.5
        _NoiseMap(">金属的范围 为金属，< 为油漆",2D) = "white"{}
        _MetalColor("金属颜色", Color)  = (1, 1, 1, 1)
        _CoatColor("油漆颜色", Color) = (1, 1, 1, 1)
        _MetalSpecularDomain("金属高光范围", Range(1, 100)) = 10
        _CoatSpecularDomain("油漆高光范围", Range(1, 100)) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        pass 
        {
            Name "metal with coat"
            ZTest On ZWrite On Cull Back Blend Off
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma vertex vert 
            #pragma fragment frag 
            #pragma multi_compile_fwdbase

            fixed _MetalDomain;
            sampler2D _NoiseMap;
            half4 _NoiseMap_ST;
            fixed4 _MetalColor;
            fixed4 _CoatColor;
            float _MetalSpecularDomain;
            float _CoatSpecularDomain;

            struct a2v 
            {
                float4 vertex:POSITION;
                fixed3 normalMS:NORMAL;
                half2 texcoord:TEXCOORD;
            };
            struct v2f 
            {
                float4 pos:SV_POSITION;
                half2 uv:TEXCOORD;
                SHADOW_COORDS(1)
                float4 posWS:TEXCOORD2;
                fixed3 normalWS:TEXCOORD3;
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _NoiseMap);
                o.normalWS = UnityObjectToWorldNormal(v.normalMS);
                
                TRANSFER_SHADOW(o);
                return o;
            }
            fixed4 frag(v2f i):SV_TARGET0
            {
                fixed3 normalWS = normalize(i.normalWS);
                fixed3 viewDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
                fixed3 lightDirWS = normalize(UnityWorldSpaceLightDir(i.posWS));
                fixed fresnel = pow(1- dot(viewDirWS, normalWS),5);

                //ambient diffuse
                fixed3 ambientDiffuse = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //ambient highlight
                
                fixed3 fresnelColor = fresnel.xxx ;

                //diffuseColor
                fixed Lambert =  saturate(dot(normalWS, lightDirWS));
                fixed3 metalicDiffuseColor = _MetalColor * _LightColor0 * Lambert;
                fixed3 coatDiffuseColor = _CoatColor * _LightColor0 * Lambert;
                
                //specular 
                fixed3 halfVector = normalize(viewDirWS + lightDirWS);
                fixed3 MetalSpecularColor = _LightColor0 * pow(max(0, dot(halfVector, normalWS)), _MetalSpecularDomain);
                fixed3 CoatSpecularColor = _LightColor0 * pow(max(0, dot(halfVector, normalWS)), _CoatSpecularDomain);
                
                UNITY_LIGHT_ATTENUATION(atten, i , i.posWS);

                //return fixed4( lerp(float3(1,1,1), float3(0, 0, 0) ,step( _MetalDomain, tex2D(_NoiseMap, i.uv).x) ),1);
                

                return fixed4(ambientDiffuse + lerp(coatDiffuseColor +CoatSpecularColor, fresnelColor + metalicDiffuseColor + MetalSpecularColor ,step( _MetalDomain, tex2D(_NoiseMap, i.uv).x)),1);
            }
            ENDCG
        }
        
    }
    FallBack "Diffuse"
}
