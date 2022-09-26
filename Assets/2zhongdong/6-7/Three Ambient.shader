Shader "zd/Three Ambient"
{
    Properties
    {
        [Header(AmbientColor)]
        _BottomAmbient ("Ambient Bottom",   Color) = (1,1,1,1)
        _AroundAmbient ("Ambient Around",   Color) = (1,1,1,1)
        _TopAmbient("Top Ambient", Color) = (0, 0, 0.5, 1)
        [Header(SpecularColor)]
        _SpecularPow("Specular Pow", Range(0.1, 30)) = 8
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "three Ambient"
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _BottomAmbient;
            fixed4 _AroundAmbient;
            fixed4 _TopAmbient;
            half _SpecularPow;

            struct a2v 
            {
                float4 vertex:POSITION;
                fixed3 normalMS:NORMAL;
            };
            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 posWS:TEXCOORD;
                half3 normalWS:TEXCOORD1;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.normalWS = UnityObjectToWorldNormal(v.normalMS);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target0
            {
                fixed3 normalWS = normalize(i.normalWS);
                fixed3 viewDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
                fixed3 lightDirWS = normalize(UnityWorldSpaceLightDir(i.posWS));

                //ambient 
                fixed topMask = dot(fixed3(0, 1, 0), normalWS);
                fixed bottomMask = dot(fixed3(0, -1, 0), normalWS);
                fixed aroundMask = 1 - topMask - bottomMask;
                fixed3 ambientColor = _BottomAmbient * bottomMask + _AroundAmbient * aroundMask + _TopAmbient * topMask;

                //diffuse

                //specular
                fixed3 halfVector = normalize(viewDirWS + lightDirWS);
                fixed Blinn_Phone = max(0, dot(halfVector, normalWS));
                fixed3 SpecularColor = _LightColor0 * pow(Blinn_Phone, _SpecularPow);

                //edge specular  只有边缘顶部有的高光

                return fixed4( ambientColor + SpecularColor, 1);
            }
            ENDCG
        }
    }
}
