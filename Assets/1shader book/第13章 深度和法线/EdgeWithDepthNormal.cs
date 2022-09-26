using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeWithDepthNormal : PostEffectsBase
{
    public Shader edgeDetectShader;
    private Material edgeDetectMaterial = null;
    public Material material
    {
        get
        {
            edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
            return edgeDetectMaterial;
        }
    }

    [Range(0.0f, 1.0f)]
    public float edgesOnly = 0.0f;           //  whether use backgroundColor or original texColor;
    public Color edgeColor = Color.black;   //  the color of the edged line
    public Color backgroundColor = Color.white;   
    public float sampleDistance = 1.0f;     //  decide the distance between two sample points . By default , it's one pixel width

    public float sensitivityDepth = 1.0f;
    public float sensitivityNormals = 1.0f;  //  

    void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
    }

    [ImageEffectOpaque]               //在处理半透之前 进行 后处理
    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_EdgeOnly", edgesOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);
            material.SetFloat("_SampleDistance", sampleDistance);
            material.SetVector("_Sensitivity", new Vector4(sensitivityNormals, sensitivityDepth, 0.0f, 0.0f));

            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
