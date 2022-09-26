Shader "Chapter15/15.2 WaterWave"
{
    Properties
    {
        _Color("Main Color", Color) = (0, 0.15, 0.115, 1)   //水面颜色
        _MainTex("Base Color", 2D) = "white"{}              //水面纹理
        _WaveMap("Wave Noise Map", 2D) = "bump"{}          //水面的噪声纹理, 该纹理时噪声纹理生成的 法线贴图（直接将 噪声纹理 的属性 改为 法线纹理  从灰度创建
        _CubeMap("Enviroment CubeMap", Cube) = "Skybox"{}

        _WaveSpeedX("Wave Speed X", Range(-1, 1)) = 0.1 
        _WaveSpeedY("Wave Speed Y", Range(-1, 1)) = 0.1 

        _Distortion("Distortion", Range(0, 100)) = 10   //水面折射 强度
    }
    SubShader
    {
        Tags{"Queue" = "Transparent" "RenderType" = "Opaque"}
        GrabPass
        {
            "_GraspScreen"
        }
        pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #pragma vertex vert 
            #pragma fragment frag 
            #pragma multi_compile_fwdbase
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _WaveMap;
            float4 _WaveMap_ST;
            samplerCUBE _CubeMap;
            fixed _WaveSpeedX;
            fixed _WaveSpeedY;
            float _Distortion;
            
            sampler2D _GraspScreen;
            float4 _GraspScreen_TexelSize;

            struct a2v 
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float3 tangent:TANGENT;
                float2 texcoord:TEXCOORD;
            };
            struct v2f 
            {
                float4 pos:SV_POSITION;
                float4 uv:TEXCOORD0;
                float4 T2Wrow0:TEXCOORD1;
                float4 T2Wrow1:TEXCOORD2;
                float4 T2Wrow2:TEXCOORD3;

                float4 screenPos:TEXCOORD4;
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap);

                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = normalize(mul((float3x3)unity_ObjectToWorld, v.tangent));
                float3 worldBinormal = normalize(cross(worldNormal, worldTangent));
                o.T2Wrow0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.T2Wrow1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.T2Wrow2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                o.screenPos = ComputeGrabScreenPos(o.pos);
                return o;
            }
            fixed4 frag(v2f i):SV_TARGET0
            {
                float2 speed = float2(_WaveSpeedX, _WaveSpeedY);

                float3 worldPos = float3(i.T2Wrow0.w, i.T2Wrow1.w, i.T2Wrow2.w);
                float3 tangentNor;
                //tangentNor.xy = tex2D(_WaveMap, i.uv.zw + speed * _Time.y).xy * 2 - float2(1, 1);//动画
                //tangentNor.z = sqrt(1 - dot(tangentNor.xy, tangentNor.xy));
                tangentNor = normalize( UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed *_Time.y)).rgb );
                tangentNor = normalize( tangentNor + UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed *_Time.y)).rgb );
                float3 worldNormal = normalize(float3(dot(i.T2Wrow0.xyz, tangentNor), dot(i.T2Wrow1.xyz, tangentNor), dot(i.T2Wrow2.xyz, tangentNor)));

                fixed3 screenRefraction = tex2D(_GraspScreen, i.screenPos.xy / i.screenPos.w + _GraspScreen_TexelSize * tangentNor.xy * _Distortion);

                fixed3 viewDir = normalize(WorldSpaceViewDir(float4(worldPos,1)));
                fixed3 reflectDir = reflect(-viewDir, worldNormal);
                fixed3 lightDir = WorldSpaceLightDir(float4(worldPos,1));
                fixed3 diffuseColor = _LightColor0 * _Color /** saturate(dot(lightDir, worldNormal))*/ * tex2D(_MainTex, i.uv.xy + speed * _Time.y) * texCUBE(_CubeMap, reflectDir);

                fixed fresnel = pow(1 - saturate(dot(viewDir,worldNormal)), 4);

                //return fixed4(diffuseColor, 1);
                return fixed4(diffuseColor * fresnel + screenRefraction * (1 - fresnel), 1);
            }
            ENDCG
        }
    }   
    FallBack Off//"Diffuse"
}
