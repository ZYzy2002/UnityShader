// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Chapter10/10.2 grab pass"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white"{}
        _BumpMap("Normal Map", 2d) = "bump"{}
        _CubeMap("Enviroment Cubemap", Cube) = "_Skybox"{}
        _Distortion("Distortion", Range(0, 100)) = 10           //模拟折射时，图像的扭曲程度，
        _RefractAmount("Refract Amount", Range(0, 1)) = 1 
    }
    SubShader
    {
        Tags{"Queue" = "Transparent" "RanderType" = "Opaque"}
        GrabPass
        {
            "_RefractionTex"    //decide which texture to be writen in
        }
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
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            samplerCUBE _CubeMap;
            float _Distortion;
            float _RefractAmount;
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;    //得到纹理的纹素大小  1/1920

            struct a2v
            {
                float4 vertex:POSITION;
                fixed3 objNor:NORMAL;
                float2 texcoord:TEXCOORD;
                float4 tangent:TANGENT;
            };
            struct v2f
            {
                float4 pos:SV_POSITION;
                float4 worldPos:TEXCOORD5;
                float3 worldNor:TEXCOORD0;
                float4 uv:TEXCOORD1;

                float4 TangentToWorldLine0:TEXCOORD2;
                float4 TangentToWorldLine1:TEXCOORD3;
                float4 TangentToWorldLine2:TEXCOORD4;

                float4 screenPos:TEXCOORD6;         //xy存储顶点 对应的屏幕坐标   z是深度
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNor = UnityObjectToWorldNormal(v.objNor);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                //fixed3 worldBinormal = cross(o.worldNor, worldTangent) * v.tangent.w;
                float3 binormal = cross(o.worldNor, worldTangent) * v.tangent.w;
                o.TangentToWorldLine0 = float4(worldTangent.x, binormal.x, o.worldNor.x, o.worldPos.x);
                o.TangentToWorldLine1 = float4(worldTangent.y, binormal.y, o.worldNor.y, o.worldPos.y);
                o.TangentToWorldLine2 = float4(worldTangent.z, binormal.z, o.worldNor.z, o.worldPos.z);          //此处使用三个寄存器的W变量，保存worldPos， 而不是直接使用 o.worldPos, 节省寄存器。
                
                o.screenPos = ComputeGrabScreenPos(o.pos);          //获取顶点在 屏幕空间 的位置  x:1920  y:1080  z：0 ~ 1近裁剪到远裁剪   w： 
                return o;
            }
            float4 frag(v2f i):SV_TARGET0
            {
                fixed3 tangentNormal;
                tangentNormal.xy= tex2D(_BumpMap, i.uv.zw) * 2 -1;
                tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                //tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                //tangentNormal = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                fixed3 worldNor = normalize(fixed3(dot(i.TangentToWorldLine0.xyz, tangentNormal), dot(i.TangentToWorldLine1.xyz, tangentNormal), dot(i.TangentToWorldLine2.xyz, tangentNormal)));      //从法线贴图得到的世界法线，不是 i.worldNor
                
                //前一个Pass获取屏幕纹理，平移像素坐标后，采样后叠加到屏幕(GrabPass必须在该Pass前)
                float2 offset = tangentNormal.xy * _Distortion * _RefractionTex_TexelSize.xy;   //屏幕坐标平移量: 法线 * 平移乘数 * 屏幕纹素长宽
                i.screenPos.xy = offset + i.screenPos.xy;                                       //或 offset * i.screenPos.z + i.screenPos
                fixed3 refractColor = tex2D(_RefractionTex, i.screenPos.xy / i.screenPos.w);

                //环境映射（反射）
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 reflectColor = texCUBE(_CubeMap, reflect(-worldViewDir, worldNor));

                //diffuse 此处没有阴影计算 直接贴图
                fixed3 baseColor = tex2D(_MainTex, i.uv.xy);

                return float4(lerp(reflectColor + baseColor*0.5, refractColor, _RefractAmount), 1);
                //return fixed4(worldNor, 1);//调试
                return fixed4(i.screenPos.wwww/50);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
