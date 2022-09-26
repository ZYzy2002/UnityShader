Shader "Chapter/11.3 flowing river"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "White"{}
        _ColorTint("Color Tint", Color) = (1,1,1,1)
        _Magnitude("Distortion Magnitude", Float) = 1                   //波动幅度
        _Frequency("Distrotion Frequency", Float) = 1                   //波动频率
        _InvWaveLength("Distortion Inverse Wave Length", Float) = 10    //波长倒数
        _Speed("Speed", Float) = 0.5
        }
    SubShader
    {
        Tags{"Queue" = "Transparent" "IgnoreProjector" = "True" "RanderType" = "Transparent" "DisableBatching" = "True"}    //禁止批处理，
        pass
        {
            Tags{"LightMode" = "ForwardBase"}
            ZWrite Off 
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off //双面显示

            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase
            #pragma vertex vert 
            #pragma fragment frag
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _ColorTint;
            float _Magnitude;
            float _Frequency;
            float _InvWaveLength;
            float _Speed;
            
            struct a2v 
            {
                float4 vertex:POSITION;
                float4 texcoord:TEXCOORD;
            };
            struct v2f
            {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0;
            };
            v2f vert(a2v v)
            {
                v2f o;

                float4 offset;
                offset.x = sin(_Frequency * _Time.y + v.vertex.x *_InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) *_Magnitude;    //sin（ 时间变化 + x/y/z轴坐标变化）* 幅度
                offset.yzw = float3(0,0,0);

                float4 newObjectPos = v.vertex + offset;
                o.pos = UnityObjectToClipPos(newObjectPos);        //在模型空间对X进行偏移
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }
            float4 frag(v2f f) :SV_TARGET0
            {
                return tex2D(_MainTex, f.uv) * _ColorTint;
            }
            ENDCG
        }


        pass        //用于得到阴影深度的Pass，用于产生阴影，
        {
            Tags{"LightMode" = "ShadowCaster"}
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"
            float _Magnitude;
            float _Frequency;
            float _InvWaveLength;
            float _Speed;

            struct a2v
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 texcoord:TEXCOORD;
            };
            struct v2f
            {
                V2F_SHADOW_CASTER;
            };
            v2f vert(a2v v)
            {
                v2f o;

                float4 offset;
                offset.x = sin(_Frequency * _Time.y + v.vertex.x *_InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) *_Magnitude;    //sin（ 时间变化 + x/y/z轴坐标变化）* 幅度
                offset.yzw = float3(0,0,0);

                v.vertex = v.vertex + offset;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);

                return o;
            }
            float4 frag(v2f i):SV_TARGET0
            {
                SHADOW_CASTER_FRAGMENT(i);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
