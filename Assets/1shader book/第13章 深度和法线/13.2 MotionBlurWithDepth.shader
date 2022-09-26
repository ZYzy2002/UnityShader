Shader "Chapter13/13.2 MotionBlurWithDepth"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BlurSize("Blur Size", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        half _BlurSize;

        sampler2D _CameraDepthTexture;
        float4x4 _PreviousViewProjectionMatrix;
        float4x4 _CurrentViewProjectionInverseMatrix;

        struct v2f 
        {
            float4 pos:SV_POSITION;
            half2 uv:TEXCOORD;
            half2 uv_depth:TEXCOORD1;
        };
        v2f vert(appdata_base v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;
            #if UNITY_UV_STARTS_AT_TOP
                if(_MainTex_TexelSize.y < 0)
                o.uv_depth.y = 1 - o.uv_depth;
            #endif
            return o;
        }
        fixed4 frag(v2f i):SV_TARGET0
        {
            float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
            float4 currentNDCPos = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);       //������  ��Ӧ��  NDC�µ� ����
            float4 D = mul(_CurrentViewProjectionInverseMatrix, currentNDCPos);             //�õ� δ����γ����� ��������
            float4 worldPos = D / D.w;                                          //��γ��� �õ���������       ����ǰ֡��  �������꣩

            float4 previousClipPos = mul(_PreviousViewProjectionMatrix, worldPos);      //Ĭ�� ֮ǰ֡����ǰ֡  ����� worldPos ���ֲ��䣬��ֻ�����絽�ü� ����仯 ��������ƶ� �Ż��� ȫ�� ģ��Ч����
            float4 previousNDCPos = previousClipPos / previousClipPos.w;                

            float2 velocity = (currentNDCPos - previousNDCPos).xy;      //��ǰ���ص� �ٶ�

            fixed4 currentColor = tex2D(_MainTex, i.uv);
            i.uv += velocity * _BlurSize;
            fixed4 previousColor1 = tex2D(_MainTex, i.uv);
            i.uv += velocity * _BlurSize;
            fixed4 previousColor2 = tex2D(_MainTex, i.uv);

            return (currentColor + previousColor1 + previousColor2)/3;
        }

        ENDCG

        pass
        {
            Tags{}
            ZTest Always ZWrite Off Cull Off 
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag 
            ENDCG        
        }
    }
    FallBack Off//"Diffuse"
}
