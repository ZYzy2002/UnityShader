// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Chapter10/10.2 grab pass"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white"{}
        _BumpMap("Normal Map", 2d) = "bump"{}
        _CubeMap("Enviroment Cubemap", Cube) = "_Skybox"{}
        _Distortion("Distortion", Range(0, 100)) = 10           //ģ������ʱ��ͼ���Ť���̶ȣ�
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
            float4 _RefractionTex_TexelSize;    //�õ���������ش�С  1/1920

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

                float4 screenPos:TEXCOORD6;         //xy�洢���� ��Ӧ����Ļ����   z�����
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
                o.TangentToWorldLine2 = float4(worldTangent.z, binormal.z, o.worldNor.z, o.worldPos.z);          //�˴�ʹ�������Ĵ�����W����������worldPos�� ������ֱ��ʹ�� o.worldPos, ��ʡ�Ĵ�����
                
                o.screenPos = ComputeGrabScreenPos(o.pos);          //��ȡ������ ��Ļ�ռ� ��λ��  x:1920  y:1080  z��0 ~ 1���ü���Զ�ü�   w�� 
                return o;
            }
            float4 frag(v2f i):SV_TARGET0
            {
                fixed3 tangentNormal;
                tangentNormal.xy= tex2D(_BumpMap, i.uv.zw) * 2 -1;
                tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                //tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                //tangentNormal = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                fixed3 worldNor = normalize(fixed3(dot(i.TangentToWorldLine0.xyz, tangentNormal), dot(i.TangentToWorldLine1.xyz, tangentNormal), dot(i.TangentToWorldLine2.xyz, tangentNormal)));      //�ӷ�����ͼ�õ������編�ߣ����� i.worldNor
                
                //ǰһ��Pass��ȡ��Ļ����ƽ����������󣬲�������ӵ���Ļ(GrabPass�����ڸ�Passǰ)
                float2 offset = tangentNormal.xy * _Distortion * _RefractionTex_TexelSize.xy;   //��Ļ����ƽ����: ���� * ƽ�Ƴ��� * ��Ļ���س���
                i.screenPos.xy = offset + i.screenPos.xy;                                       //�� offset * i.screenPos.z + i.screenPos
                fixed3 refractColor = tex2D(_RefractionTex, i.screenPos.xy / i.screenPos.w);

                //����ӳ�䣨���䣩
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 reflectColor = texCUBE(_CubeMap, reflect(-worldViewDir, worldNor));

                //diffuse �˴�û����Ӱ���� ֱ����ͼ
                fixed3 baseColor = tex2D(_MainTex, i.uv.xy);

                return float4(lerp(reflectColor + baseColor*0.5, refractColor, _RefractAmount), 1);
                //return fixed4(worldNor, 1);//����
                return fixed4(i.screenPos.wwww/50);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
