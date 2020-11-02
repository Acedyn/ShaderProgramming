Shader "Unlit/OutlineShader"
{
    Properties
    {
        _OutlineThickness("Outline thickness", float) = 0.1
        _OutlineColor("Outline color", color) = (1, 1, 1, 1)
        _InteriorColor("Interior color", color) = (0, 0, 0, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            uniform float4 _OutlineColor;
            uniform float _OutlineThickness;

            #include "UnityCG.cginc"


            float4 outline(float4 pos, float outline)
            {
                float4x4 scale = 0.0;
                scale[0][0] = 1.0 + outline;
                scale[1][1] = 1.0 + outline;
                scale[2][2] = 1.0 + outline;
                scale[3][3] = 1.0;
                return mul(scale, pos);
            }


            struct appdata
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(outline(v.pos, _OutlineThickness));
                o.uv = v.uv;
                return o;
            }


            fixed4 frag (v2f i) : COLOR
            {
                fixed4 col = _OutlineColor;
                return col;
            }
            ENDCG
        }

        Pass
        {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            uniform float4 _InteriorColor;

            struct appdata
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.pos);
                o.uv = v.uv;
                return o;
            }


            fixed4 frag (v2f i) : COLOR
            {
                fixed4 col = _InteriorColor;
                return col;
            }
            ENDCG
        }
    }
}
