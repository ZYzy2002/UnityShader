using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class godray : PostProcessBase
{
    public Shader godRayShader;
    private Material godRayMaterial = null;
    public Material material
    {
        get
        {
            // 调用PostEffectsBase基类中检查Shader和创建材质的函数
            godRayMaterial = CheckShaderAndCreateMaterial(godRayShader, godRayMaterial);
            return godRayMaterial;
        }
    }


     [Range(0,6)]
    public int radialBlurInteration = 3;          //模糊次数
    
    [Range(1,4)]
    public int downSample = 2;          //渲染纹理 边长缩小倍数


    
    [Range(0.0f,1.0f)]
    public float luminanceThreshold = 0.9f;                 //传入 Shader ，提取该值以上的亮度

    [Range(0.0f,1.0f)]
    public float[] lightPosInScreenUV = new float[2]{0.5f, 0.767f};       //传入 Shader， 径向模糊的中心点

    [Range(0.0f, 1.0f)]
    public float LightRadius = 0.2f;                        //传入 Shader， 提取亮部后，只要靠近中心点的部分

    [Range(0.0f, 40.0f)]
    public float MaskPow = 1.0f;                            //传入 Shader， 对Mask 进行提亮/暗处理
    
    [Range(1, 20)]
    public float SamplerPointCount = 14;                      //传入 Shader， 径向模糊采样次数

     [Range(0, 0.05f)]
    public float SamplerOffset = 0.02f;                            //传入 Shader， 径向模糊 采样点偏移

    public Color LightColor = new Color(1.0f, 0.0f, 0.0f, 0.0f);


    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if(material)
        {
            int downSampleTexWidth = src.width / downSample;
            int downSampleTexHight = src.height / downSample;
            RenderTexture buffer0 = RenderTexture.GetTemporary(downSampleTexWidth, downSampleTexHight, 0);
            RenderTexture buffer1 = RenderTexture.GetTemporary(downSampleTexWidth, downSampleTexHight, 0);

            material.SetFloat("_LuminanceThreshold", luminanceThreshold);
            material.SetColor("_LightPosInScreenUV", new Color(lightPosInScreenUV[0], lightPosInScreenUV[1], 0,0));
            material.SetFloat("_LightRadius", LightRadius);
            material.SetFloat("_MaskPow", MaskPow);
            Graphics.Blit(src, buffer0, material, 0);
            
            for(int i = 0; i < radialBlurInteration; i++)
            {
                material.SetFloat("_SamplerPointCount", SamplerPointCount);
                material.SetFloat("_SamplerOffset", SamplerOffset);
                material.SetColor("_LightColor", LightColor);
                Graphics.Blit(buffer0, buffer1, material, 1);
            }
            material.SetTexture("_BlurTex", buffer1);
            Graphics.Blit(src, dest, material, 2);

            RenderTexture.ReleaseTemporary(buffer0);
            RenderTexture.ReleaseTemporary(buffer1);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
