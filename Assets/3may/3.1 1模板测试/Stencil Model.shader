Shader "may/Stencil Model"
{
    Properties
    {
        [Header(Stencil)]
        _StencilRefValue ("Stencil Ref Value", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilCompFunc ("Stencil Compare Function", Float) = 8
        [Header(Diffuse)]
        _BaseColor ("Base Color", 2D) = "white" {}
        _ColorTint("Color Tint", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags {"Queue" = "Geometry+2" "RenderType"="Opaque" }
        LOD 100

        pass
        {   
            Name "UseStencil"
            Tags { "LightMode" = "ForwardBase" }
            Stencil 
            {
                Ref [_StencilRefValue]
                Comp [_StencilCompFunc]
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _BaseColor;
            float4 _BaseColor_ST;
            fixed4 _ColorTint;

            struct a2v
            {
                float4 vertex       :POSITION;
                float2 uv           :TEXCOORD0;
                fixed3 normalMS     :NORMAL;
            };

            struct v2f
            {
                float4 pos      :SV_POSITION;
                float2 uv       :TEXCOORD0;
                float4 posWS    :TEXCOORD3;
                SHADOW_COORDS(1)
                half3 normalWS  :TEXCOORD2;
            };
            
            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.normalWS = UnityObjectToWorldNormal(v.normalMS);
                o.uv = TRANSFORM_TEX(v.uv, _BaseColor);
                UNITY_TRANSFER_FOG(o,o.vertex);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 normalWS= normalize(i.normalWS);
                fixed3 lightDirWS = normalize( UnityWorldSpaceLightDir(i.posWS) );
                fixed3 viewDirWS = normalize( UnityWorldSpaceViewDir(i.posWS) );
                // diffuse 
                fixed4 albedo = _ColorTint * tex2D(_BaseColor, i.uv);
                fixed Lambert = max(0, dot(lightDirWS, normalWS));
                fixed3 diffuseColor = albedo * _LightColor0.rgb * Lambert;

                UNITY_LIGHT_ATTENUATION(atten, i, i.posWS)
                return fixed4(diffuseColor * atten, 1);
            }
            ENDCG
        }
    }
}
