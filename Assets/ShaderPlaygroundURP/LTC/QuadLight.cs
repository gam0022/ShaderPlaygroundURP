using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static Unity.Mathematics.math;
using Unity.Mathematics;

[ExecuteAlways]
public class QuadLight : MonoBehaviour
{
    public Vector4[] points = new Vector4[4];
    public Material[] materials;

    readonly int QuadPointID = Shader.PropertyToID("_QuadPoints");

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        float width = 0.5f;
        points[0] = transform.TransformPoint(new Vector3(-width, -width, 0f));
        points[1] = transform.TransformPoint(new Vector3( width, -width, 0f));
        points[2] = transform.TransformPoint(new Vector3( width,  width, 0f));
        points[3] = transform.TransformPoint(new Vector3(-width,  width, 0f));

        foreach(var material in materials)
        {
            material.SetVectorArray(QuadPointID, points);
        }
    }
}
