// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Chapter11/11.3 advertise"
{
    Properties
    {
        //base color 
        _MainTex("Main Texture", 2D) = "White"{}
        _ColorTint("Color Tine", Color) = (1,1,1,1)
        _VerticalBillboarding("Vertical Restraints", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags{"Queue" = "Transparent" "IgnoreProjector" = "True" "RanderType" = "Transparent" "DisableBatching" = "True"}
        pass
        {
            Tags{"LightMode" = "ForwardBase"}
            ZWrite Off 
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma vertex vert
            #pragma fragment frag 
            #pragma multi_compile_fwdbase
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _ColorTint;
            half _VerticalBillboarding;

            struct a2v
            {
                float4 vertex:POSITION;
                float4 texcoord:TEXCOORD;
            };
            struct v2f 
            {
                float4 pos:SV_POSITION;
                float2 mainTexUV:TEXCOORD0;
            };
            v2f vert(a2v v)
            {
                v2f o;

                //获取 从相机到 物体 的方向，   y 轴方向 由_VerticalBillboarding 控制权重
                float3 center = float3(0, 0, 0);
                float3 objViewerPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));

                //构建目标坐标 三维正交向量
                float3 normalDir = objViewerPos - center;
                normalDir.y = _VerticalBillboarding * normalDir.y;       //y轴是向上的分量
                normalDir = normalize(normalDir);

                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);  //upDir取特值， 叉乘得rightDir（rightDir一定垂直normalDir和此时的upDir） 
                float3 rightDir = normalize(cross(upDir, normalDir));
                upDir = normalize(cross(normalDir, rightDir));                                //此时 normalDir 是观测方向， 和upDir rightDir 三者相互垂直， 

                float3 centerOffs = v.vertex.xyz - center;      //减去center 是将顶点从 模型空间 转到 旋转轴点空间
                //float3 localPos = center +rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
                float3 localPos = center + float3(dot(float3(rightDir.x,  normalDir.x,upDir.x), centerOffs), dot(float3(rightDir.y, normalDir.y, upDir.y) , centerOffs), dot(float3(rightDir.z, normalDir.z, upDir.z) , centerOffs));

                o.pos = UnityObjectToClipPos(float4(localPos, 1 ));


                o.mainTexUV = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
                return o;
            };
            float4 frag(v2f i):SV_TARGET0
            {
                return tex2D(_MainTex, i.mainTexUV) *_ColorTint;
            }
            ENDCG
        }

    }
    FallBack "Transparent\VertexLit"
}
