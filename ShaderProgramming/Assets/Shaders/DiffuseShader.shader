Shader "Unlit/Diffuse"
{
    Properties
    {
        _Diffuse ("Diffuse %", Range(0, 1)) = 1
        [KeywordEnum(Off, Vert, Frag)]_Lighting("Lighting Mode", float) = 0
    }
    SubShader
    {

        Pass
        {
            
            Tags 
            { 
                "LightMode" = "ForwardBase"
            }

            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _LIGHTING_OFF _LIGHTING_VERT _LIGHTING_FRAG

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            uniform float _Diffuse;
            uniform float4 _LightColorO;

            ////////////////////////////////GLOBAL FUNCTIONS//////////////////////////
            
            float3 LambertDiffuse(float3 normal, float3 lightDir, float3 lightColor, float diffuseFactor, float attenuation)
            {
                return lightColor * diffuseFactor * attenuation * max(0, dot(normal, lightDir));
            }


            /////////////////////////////////VERTEX SHADER///////////////////////////

            struct VertexInput
            {
                float4 pos : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWorld : TEXCOORD1;
                #if _LIGHTING_VERT
                float4 surfaceColor: COLOR0;
                #endif
            };


            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                o.pos = UnityObjectToClipPos(v.pos);
                o.uv = v.uv;

                // Get the normals to world space
                o.normalWorld = UnityObjectToWorldNormal(v.normal);

                #if _LIGHTING_VERT
                float3 lightDir = normalize(_WorldSpaceLightPos0);
                float3 lightColor = _LightColor0.xyz;
                float attenuation = 1;
                o.surfaceColor = float4(LambertDiffuse(o.normalWorld, lightDir, lightColor, _Diffuse, attenuation), 1.0);
                #endif

                return o;
            }


            ///////////////////////////////FRAGMENT SHADER///////////////////////////

            float4 frag(VertexOutput i) : COLOR
            {
                float3 worldNormalAtPixel = i.normalWorld;
                
                #if _LIGHTING_FRAG
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightColor = _LightColor0.xyz;
                float attenuation = 1;
                return float4(LambertDiffuse(worldNormalAtPixel, lightDir, lightColor, _Diffuse, attenuation), 1.0);

                #elif _LIGHTING_VERT
                return i.surfaceColor;

                #else
                return float4(_LightColor0.xyz, 1);

                #endif
            }

            ENDCG
        }
    }
}
