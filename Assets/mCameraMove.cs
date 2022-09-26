using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class mCameraMove : MonoBehaviour
{
    // Start is called before the first frame update


    private Camera movedCamera;
    public Camera camera
    {
        get
        {
            if(movedCamera == null)
            {
                movedCamera = GetComponent<Camera>();
            }
            return movedCamera;
        }
    }

    private bool[] keyStateDownWASDQEF;
    public float moveSpeed;
    private bool isRButtonDown;
    private Vector3 lastFrameCursorPos;
    public float rotateSpeed;


    void Start()
    {
        keyStateDownWASDQEF = new bool[7];
        moveSpeed = 0.05f;
        rotateSpeed = 0.5f;
        isRButtonDown = false;
    }

    // Update is called once per frame
    void Update()
    {
        if(Input.GetKeyDown(KeyCode.W))
        {
            keyStateDownWASDQEF[0] = true;
        }
        if(Input.GetKeyDown(KeyCode.A))
        {
            keyStateDownWASDQEF[1] = true;
        }
        if(Input.GetKeyDown(KeyCode.S))
        {
            keyStateDownWASDQEF[2] = true;
        }
        if(Input.GetKeyDown(KeyCode.D))
        {
            keyStateDownWASDQEF[3] = true;
        }
        if(Input.GetKeyDown(KeyCode.Q))
        {
            keyStateDownWASDQEF[4] = true;
        }
        if(Input.GetKeyDown(KeyCode.E))
        {
            keyStateDownWASDQEF[5] = true;
        }
        if(Input.GetKeyDown(KeyCode.F))
        {
            keyStateDownWASDQEF[6] = true;
        }

        if(Input.GetKeyUp(KeyCode.W))
        {
            keyStateDownWASDQEF[0] = false;
        }
        if(Input.GetKeyUp(KeyCode.A))
        {
            keyStateDownWASDQEF[1] = false;
        }
        if(Input.GetKeyUp(KeyCode.S))
        {
            keyStateDownWASDQEF[2] = false;
        }
        if(Input.GetKeyUp(KeyCode.D))
        {
            keyStateDownWASDQEF[3] = false;
        }
        if(Input.GetKeyUp(KeyCode.Q))
        {
            keyStateDownWASDQEF[4] = false;
        }
        if(Input.GetKeyUp(KeyCode.E))
        {
            keyStateDownWASDQEF[5] = false;
        }
        if(Input.GetKeyUp(KeyCode.F))
        {
            keyStateDownWASDQEF[6] = false;
        }

        if(Input.GetMouseButtonDown(1))
        {
            isRButtonDown = true;
        }
        if(Input.GetMouseButtonUp(1))
        {
            isRButtonDown = false;
        }





        if(keyStateDownWASDQEF[0])
        {
            //camera.transform.Translate(camera.transform.forward * moveSpeed);
            camera.transform.Translate(Vector3.forward * moveSpeed);
        }
        if(keyStateDownWASDQEF[1])
        {
            camera.transform.Translate(-Vector3.right * moveSpeed);
        }
        if(keyStateDownWASDQEF[2])
        {
            camera.transform.Translate(-Vector3.forward * moveSpeed);
        }
        if(keyStateDownWASDQEF[3])
        {
            camera.transform.Translate(Vector3.right * moveSpeed);
        }
        if(keyStateDownWASDQEF[4])
        {
            camera.transform.Translate(-Vector3.up * moveSpeed);
        }
        if(keyStateDownWASDQEF[5])
        {
            camera.transform.Translate(Vector3.up * moveSpeed);
        }
        if(keyStateDownWASDQEF[6])
        {
            camera.transform.rotation = new Quaternion{};
        }

        Vector3 thisFrameCursorPos = Input.mousePosition;
        if(isRButtonDown)
        {
            Vector3 delta;
            delta.x = -(thisFrameCursorPos - lastFrameCursorPos).y * rotateSpeed;
            delta.y = (thisFrameCursorPos - lastFrameCursorPos).x * rotateSpeed;
            delta.z = 0;
            camera.transform.Rotate(delta);
        }
        lastFrameCursorPos = thisFrameCursorPos;

    }
}
