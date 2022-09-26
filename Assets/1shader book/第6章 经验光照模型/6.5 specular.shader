// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chapter6/6.5 specular"
{
    Properties
    {
       _DiffuseColor("Diffuse",Color) = (1,1,1,1)
       _Gloss("Gloss",Range(8,256))=20      //高光范围
       _Specular("Specular Color Offset",Color)= (1,1,1,1)
    }
    SubShader
    {

        //*******
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "lighting.cginc"
            half4 _DiffuseColor;
            half _Gloss;
            half4 _Specular;

            struct a2v
            {
                half4 normal :NORMAL;
                float4 objectPosition : POSITION;
            };

            struct v2f
            {
                half4 sv_position:SV_POSITION;
                half4 worldPosition:TEXCOORD0;
                half4 worldNormal:TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.sv_position = UnityObjectToClipPos(v.objectPosition);
                o.worldPosition = mul(unity_ObjectToWorld, v.objectPosition);
                o.worldNormal = normalize(mul(unity_WorldToObject, v.normal));
                return o;
            }
            
            half4 frag(v2f i): SV_Target
            {
                half4 ambientColor = UNITY_LIGHTMODEL_AMBIENT;      //间接光照

                half4 LightDirection = normalize(_WorldSpaceLightPos0);
                half4 diffuseColor = _LightColor0 * _DiffuseColor * saturate( dot(LightDirection,i.worldNormal));              //漫反射光照

                half4 viewDirection = half4( normalize(_WorldSpaceCameraPos.xyz - i.worldPosition.xyz), 1.0);
                half4 halfVector = normalize(viewDirection + LightDirection);
                half4 specularColor = _LightColor0 * _Specular* pow(saturate( dot(halfVector, i.worldNormal)), _Gloss);     //高光

                return ambientColor + diffuseColor + specularColor;
            }
    
           

            ENDCG
        }
        
        //end of a pass 
    }
    FallBack "Specular"
}
