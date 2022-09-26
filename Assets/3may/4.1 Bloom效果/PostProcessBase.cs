using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
public class PostProcessBase : MonoBehaviour
{
    protected void CheckResources() {                               //在基类的start调用 CheckResources函数  检查是否支持 后处理和渲染目标， 如果不支持就输出警告
        bool isSupported = CheckSupport();

        if (isSupported == false) {
            NotSupported();
        }
    }
    protected bool CheckSupport() {
        if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false) {
            Debug.LogWarning("This platform does not support image effects or render textures.");
            return false;
        }

        return true;
    }
    protected void NotSupported() {
        enabled = false;
    }
    
    protected virtual void Start()                                                          //调用检查函数，PostProcessBase类的子类 不应该 覆写 该函数，或者覆写但调用 该父类的函数
    {
        CheckResources();
    }



    
    protected Material CheckShaderAndCreateMaterial(Shader shader, Material material) {     //由于是后处理，必然要传入着色器，并创建材质，所以该函数由子类调用，用于检查 着色器和材质 是否就位
        if (shader == null) {                                                                   //如果没有传入 shader 则material 为null
            return null;
        }
        if (shader.isSupported && material && material.shader == shader)                        //着色器支持，材质存在，材质对应的着色器和传入的着色器相同
            return material;

        if (!shader.isSupported) {                                                              //着色器不支持
            return null;
        }
        else {                                                                                  //
            material = new Material(shader);
            //material.hideFlags = HideFlags.DontSave;
            if (material)
                return material;
            else
                return null;
        }
    }
    
    
    
    
    
    
    
    // Update is called once per frame
    void Update()
    {
        
    }
}
