// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chapter8/8.7 alpha blend two side"
{
	Properties
	{
		_ColorTint("Color Tint", Color) = (1,1,1,1)
		_BaseColormap_Alpha("Base Color Map with Alpha", 2D) = "white"{}
		_AlphaScale("Alpha Scale", Range(0,2)) = 1
	}
	SubShader
	{
		Tags{"Queue" = "Transparent" "IgoreProjector" = "True" "RanderType" = "Transparent"}
		Pass
		{
			Tags{"LightMode" = "ForwardBase"}
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			#include "UnityCG.cginc"
			fixed4 _ColorTint;
			sampler2D _BaseColormap_Alpha;
			float4 _BaseColormap_Alpha_ST;
			float _AlphaScale;

			struct a2f
			{
				float3 objPos:POSITION;
				float3 objNormal:NORMAL;
				float4 texCoord:TEXCOORD;
			};
			struct v2f
			{
				float4 clipPos:SV_POSITION;
				float4 worldPos:TEXCOORD0;
				float3 worldNormal:TEXCOORD1;
				float2 uv:TEXCOORD2;
			};
			v2f vert(a2f v)
			{
				v2f o;
				o.clipPos = UnityObjectToClipPos(v.objPos);
				o.worldPos = mul(unity_ObjectToWorld, v.objPos);
				o.worldNormal = normalize(mul(unity_WorldToObject, v.objNormal));
				o.uv = TRANSFORM_TEX(v.texCoord.xy, _BaseColormap_Alpha);
				return o;
			}
			float4 frag(v2f f):SV_TARGET0
			{
				fixed4 texPixel = tex2D(_BaseColormap_Alpha, f.uv);
				fixed3 albedo = texPixel * _ColorTint.xyz;

				fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT;
				
				fixed3 diffuseColor = albedo *_LightColor0 *saturate(dot(f.worldNormal, UnityWorldSpaceLightDir(f.worldPos)));

				return float4(ambientColor + diffuseColor, texPixel.a * _AlphaScale);
			}

			ENDCG
		}

		Pass
		{
			Tags{"LightMode" = "ForwardBase"}
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			Cull Back

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			#include "UnityCG.cginc"
			fixed4 _ColorTint;
			sampler2D _BaseColormap_Alpha;
			float4 _BaseColormap_Alpha_ST;
			float _AlphaScale;

			struct a2f
			{
				float3 objPos:POSITION;
				float3 objNormal:NORMAL;
				float4 texCoord:TEXCOORD;
			};
			struct v2f
			{
				float4 clipPos:SV_POSITION;
				float4 worldPos:TEXCOORD0;
				float3 worldNormal:TEXCOORD1;
				float2 uv:TEXCOORD2;
			};
			v2f vert(a2f v)
			{
				v2f o;
				o.clipPos = UnityObjectToClipPos(v.objPos);
				o.worldPos = mul(unity_ObjectToWorld, v.objPos);
				o.worldNormal = normalize(mul(unity_WorldToObject, v.objNormal));
				o.uv = TRANSFORM_TEX(v.texCoord.xy, _BaseColormap_Alpha);
				return o;
			}
			float4 frag(v2f f):SV_TARGET0
			{
				fixed4 texPixel = tex2D(_BaseColormap_Alpha, f.uv);
				fixed3 albedo = texPixel * _ColorTint.xyz;

				fixed3 ambientColor = UNITY_LIGHTMODEL_AMBIENT;
				
				fixed3 diffuseColor = albedo *_LightColor0 *saturate(dot(f.worldNormal, UnityWorldSpaceLightDir(f.worldPos)));

				return float4(ambientColor + diffuseColor, texPixel.a * _AlphaScale);
			}

			ENDCG
		}
	}
}