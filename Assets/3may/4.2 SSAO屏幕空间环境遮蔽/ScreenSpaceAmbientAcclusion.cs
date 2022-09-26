using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class ScreenSpaceAmbientAcclusion : PostProcessBase
{
    private Camera mainCamera;
    public Camera camera 
    {
        get 
        {
            if(mainCamera == null)
            {
                mainCamera= GetComponent<Camera>();
            }
            return mainCamera;
        }
    }
    public Shader SSAOShader;
    private Material ssaoMaterial;

    
    public Material ssaoMat
    {
        get
        {
            ssaoMaterial = CheckShaderAndCreateMaterial(SSAOShader, ssaoMaterial); 
            return ssaoMaterial;
        }
    }

    public Shader BlurShader;
    private Material blurMaterial;
    public Material blurMat
    {
        get
        {
            blurMaterial = CheckShaderAndCreateMaterial(BlurShader, blurMaterial); 
            return blurMaterial;
        }
    }

    void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.DepthNormals;   
    }
    
    [Range(1,256)]
    public int SampleCount;
    [Range(0.01f, 0.5f)]
    public float SampleRadius;                      //SSAO 相机空间 随机半径最大值。
    public Color AOColor = new Color(0.0f,0.0f,0.0f);

    [Range(0.0f, 0.1f)]
    public float UVOffset;                          //双边模糊采样UV偏移。
    [Range(0.0f, 1.0f)]
    public float BilaterFilterFactor;               //法线比较的敏感度，值越大，法线差别对模糊的影响越小。
    
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Matrix4x4 cameraProj = camera.projectionMatrix;
        ssaoMat.SetMatrix("_Matrix_P",cameraProj);
        ssaoMat.SetMatrix("_Matrix_IP", cameraProj.inverse);         //传入投影矩阵逆矩阵
        ssaoMat.SetInt("_SampleCount", SampleCount);
        ssaoMat.SetFloat("_SampleRadius", SampleRadius);
        ssaoMat.SetColor("_AOColor", AOColor);

        
        RenderTexture buffer0 = RenderTexture.GetTemporary(src.width / 2, src.height / 2, 0);       //downsample
        RenderTexture buffer1 = RenderTexture.GetTemporary(src.width / 2, src.height / 2, 0);
        Graphics.Blit(src, buffer0, ssaoMat, 0);

        blurMat.SetFloat("_UVOffset",UVOffset);              //模糊AO图
        blurMat.SetFloat("_BilaterFilterFactor",BilaterFilterFactor);
        Graphics.Blit(buffer0, buffer1, blurMat,0);
        Graphics.Blit(buffer1, buffer0, blurMat, 1);
        
        blurMat.SetTexture("_AoTex", buffer0);                   //与原图叠加
        
        Graphics.Blit(src, dest, blurMat, 2);
        Graphics.Blit(src, dest, blurMat, 2);
    }
}
