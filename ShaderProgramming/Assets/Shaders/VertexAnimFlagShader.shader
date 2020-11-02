Shader "Unlit/VertexAnimFlag"
{
    Properties
    {
        _Color ("Main Color", Color) = (1, 1, 1, 1)
        _MainTex ("Main Texture", 2D) = "White" {}
        _Amplitude ("Amplitude", float) = 1.0
        _Frequency ("Frequency", float) = 1.0
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
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            uniform half4 _Color;
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform float _Amplitude;
            uniform float _Frequency;

            /////////////////////////////////VERTEX SHADER///////////////////////////

            struct VertexInput
            {
                float4 pos : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 pos : POSITION;
                float4 uv : TEXCOORD0;
            };

            float4 VertexAnimFlag(float4 vertPos, float2 uv)
            {
                vertPos.z += sin((uv.x + _Time.y) * _Frequency) * _Amplitude;
                return vertPos;
            }

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                o.pos = VertexAnimFlag(v.pos, v.uv.xy);
                o.pos = UnityObjectToClipPos(o.pos);
                o.uv = v.uv;
                return o;
            }

            ///////////////////////////////FRAGMENT SHADER///////////////////////////

            half4 frag(VertexOutput i) : COLOR
            {
                float4 color = _Color;
                return color;
            }

            ENDCG
        }
    }
}
