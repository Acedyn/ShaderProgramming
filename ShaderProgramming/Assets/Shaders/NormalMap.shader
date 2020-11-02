Shader "Unlit/NormalMap"
{
    Properties
    {
        _Color ("Main Color", Color) = (1, 1, 1, 1)
        _MainTex ("Main Texture", 2D) = "White" {}
        _NormalMap ("Normal Map", 2D) = "White" {}
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
            uniform sampler2D _NormalMap;
            uniform float4 _NormalMap_ST;

            /////////////////////////////////VERTEX SHADER///////////////////////////

            struct VertexInput
            {
                float4 pos : POSITION;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWorld : TEXCOORD1;
                float3 tangentWorld : TEXCOORD2;
                float3 binormalWorld : TEXCOORD3;
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                o.pos = UnityObjectToClipPos(v.pos);
                o.uv = v.uv;

                // Get the normals to world space
                o.normalWorld = UnityObjectToWorldNormal(v.normal);
                // Get the tangent to world space
                o.tangentWorld = UnityObjectToWorldNormal(v.tangent);
                // get the binormal with cross product
                o.binormalWorld = normalize(-cross(o.normalWorld, o.tangentWorld));

                return o;
            }

            ///////////////////////////////FRAGMENT SHADER///////////////////////////

            float3 normalFromColor(float4 color)
            {
                #if defined(UNITY_NO_DXT5nm)
                return color.xyz

                #else
                float3 normal = float3(color.a, color.g, 0.0);
                normal.z = sqrt(1 - dot(normal, normal));
                return normal;
                #endif
            }

            float3 WorldNormalFromNormalMap(sampler2D normalMap, float2 normalTexCoord, float3 tangentWorld, float3 binormalWorld, float3 normalWorld)
            {
                // Color at pixel wich we read from TangentSpace normal map
                float4 colorAtPixel = tex2D(normalMap, normalTexCoord);

                // Normal value converted from color value
                float3 normalAtPixel = normalFromColor(colorAtPixel);

                // Compose TBM matrix
                float3x3 TBNWorld = float3x3(tangentWorld, binormalWorld, normalWorld);
                return normalize(mul(normalAtPixel, TBNWorld));
            }

            float4 frag(VertexOutput i) : COLOR
            {
                float3 worldNormalAtPixel = WorldNormalFromNormalMap(_NormalMap, i.uv, i.tangentWorld, i.binormalWorld, i.normalWorld);
                float3 normalMap = normalFromColor(tex2D(_NormalMap, i.uv));
                //return float4(normalMap, 1);
                //return float4(i.normalWorld, 1);
                //return float4(i.tangentWorld, 1);
                //return float4(i.binormalWorld, 1);
                return float4(worldNormalAtPixel, 1);
            }

            ENDCG
        }
    }
}
