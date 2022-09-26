// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"Chapter7/7.1 single texture"
{
	Properties
	{
		_ColorOffset("Base Color Tint",Color) = (1,1,1,1)
		_BaseColorMap("Base Color Map",2D) = "White"{}
		_Specular("Specular Color",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(8.0,256.0))=20.0
	}
	SubShader
	{
		pass
		{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "lighting.cginc"
			#include "UnityCG.cginc"

			float4 _ColorOffset;
			sampler2D _BaseColorMap;
			float4 _BaseColorMap_ST;
			float4 _Specular;
			float _Gloss;

			struct a2f
			{
				float4 objectPos: POSITION;
				float4 objectNormal: NORMAL;
				float4 texcoord: TEXCOORD0;
			};
			struct v2f
			{
				float4 clipPos: SV_POSITION;
				float4 worldNormal: TEXCOORD0;
				float4 worldPos: TEXCOORD1;
				float2 uv: TEXCOORD2;
			};

			v2f vert(a2f v)
			{
				v2f o;
				o.clipPos = UnityObjectToClipPos(v.objectPos);
				o.worldNormal = normalize( mul(unity_WorldToObject, v.objectNormal) );
				o.worldPos = mul(unity_ObjectToWorld, v.objectPos);
				o.uv = TRANSFORM_TEX(v.texcoord, _BaseColorMap);
				return o;
			}

			float4 frag(v2f f): SV_TARGET0
			{
				//间接光
				float4 ambientColor = UNITY_LIGHTMODEL_AMBIENT;
				//满反射
				float4 albedo = tex2D(_BaseColorMap, f.uv) * _ColorOffset;
				float4 worldLightDir = float4(UnityWorldSpaceLightDir(f.worldPos), 1.0);
				float4 diffuseColor = albedo * _LightColor0 * saturate(0.5 * dot(_WorldSpaceLightPos0, f.worldNormal) + 0.5);
				//高光
				float4 viewDir = float4(normalize (UnityWorldSpaceViewDir(f.worldPos)), 1);
				float4 halfVector = normalize(viewDir + worldLightDir);
				float4 specularColor = _Specular * _LightColor0 * pow(saturate( dot(halfVector, f.worldNormal)), _Gloss);

				return ambientColor + diffuseColor + specularColor;
			}

			ENDCG
		}

	}
	FallBack "Specular"

}