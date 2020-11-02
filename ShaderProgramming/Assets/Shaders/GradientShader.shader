Shader "Unlit/GradientShader"
{
    Properties
    {
        _Color ("Main Color", Color) = (1, 1, 1, 1)
        _Center ("Circle Center", float) = 0.5
        _Radius ("Circle Radius", float) = 0.5
        _Feather ("Circle Feather", Range(0, 0.5)) = 0.05
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent"
            "Queue" = "Transparent"
            "IgnoreProjector" = "True" 
        }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            uniform half4 _Color;
            uniform float _Center;
            uniform float _Radius;
            uniform float _Feather;

            struct VertexInput
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 pos : POSITION;
                float4 uv : TEXCOORD0;
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float drawCircle(float2 uv, float2 center, float radius, float feather)
            {
                float circle = pow((uv.y - center.y), 2) + pow((uv.x - center.x), 2);
                float radiusSquare = pow(radius, 2);
                if(circle < radiusSquare)
                {
                    return smoothstep(radiusSquare, radiusSquare - feather, circle);
                }
                return 0;
            }

            half4 frag(VertexOutput i) : Color
            {
                float4 color = _Color;
                color.a = drawCircle(i.uv.xy, _Center, _Radius, _Feather);
                return color;
            }

            ENDCG
        }
    }
}
