using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class bloom : PostProcessBase
{
    public Shader bloomShader;
    private Material bloomMaterial;

    public Material material
    {
        get
        {
            bloomMaterial = CheckShaderAndCreateMaterial(bloomShader,bloomMaterial); 
            return bloomMaterial;
        }
    }


    [Range(0,6)]
    public int interation = 3;          //模糊次数
    [Range(1,4)]
    public int downSample = 2;          //渲染纹理 边长缩小倍数

    [Range(0.1f,10.0f)]
    public float blurSpread = 0.6f;     //传入 Shader，  卷积核 向外 偏移的UV大小  ，  并且每次迭代 偏移量线性增大
    [Range(0.0f,1.0f)]
    public float luminanceThreshold = 0.8f;       //传入 Shader ，提取该值以上的亮度



    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if(material == null)
        {
            Graphics.Blit(src, dest);
        }
        else
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);
            int downSampleTexWidth = src.width/downSample;
            int downSampleTexHight = src.height/downSample;
            RenderTexture downBuffer0 = RenderTexture.GetTemporary(downSampleTexWidth,downSampleTexHight,0);    
            RenderTexture downBuffer1 = RenderTexture.GetTemporary(downSampleTexWidth,downSampleTexHight,0);    
            Graphics.Blit(src,downBuffer0,material,0);                                          //用 pass0 将源纹理 提取较亮 部分到 一个较小的 buffer 内
            for(int i = 0; i < interation; ++i)                                                   //多次模糊
            {   
                material.SetFloat("_BlurSize",1 +i * blurSpread);                                     //每次循环提高模糊程度， uv偏移默认值：  1,  1.6,  2.2
                Graphics.Blit(downBuffer0,downBuffer1,material,1);                                    //先水平模糊
                Graphics.Blit(downBuffer1,downBuffer0,material,2);                                    //再竖直模糊
            }
            material.SetTexture("_Bloom", downBuffer0);
            Graphics.Blit(src,dest,material,3);                                                 //合并两张纹理， src还是 传入Shader 的"_MainTex"属性， downBuffer1传入Shader的"_Bloom"属性（该属性只在pass3有效，其他pass为默认值）
            RenderTexture.ReleaseTemporary(downBuffer0);
            RenderTexture.ReleaseTemporary(downBuffer1);
        }
    }
}
