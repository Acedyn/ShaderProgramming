Shader "Unlit/Specular"
{
    Properties
    {
        [KeywordEnum(Off, Vert, Frag)]_Lighting("Lighting Mode", float) = 0
        _SpecularMap("SpecularMap", 2D) = "black" {}
        _SpecularFactor("Specular %", Range(0, 1)) = 1
        _SpecularPower("Specular Power", float) = 100
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

            uniform sampler2D _SpecularMap;
            uniform float _SpecularFactor;
            uniform float _SpecularPower;

            ////////////////////////////////GLOBAL FUNCTIONS//////////////////////////

            float3 specularBlinnPhong(float3 normal, float3 lightDir, float3 worldSpaceViewDir, float3 specularColor, float specularFactor, float attenuation, float specularPower)
            {
                float3 halfwayDir = normalize(lightDir + worldSpaceViewDir);
                return specularColor * specularFactor * attenuation * pow(max(0, dot(normal, halfwayDir)), specularPower);
            }

            /////////////////////////////////VERTEX SHADER///////////////////////////

            struct VertexInput
            {
                float4 pos : POSITION;
                float3 normal : NORMAL;
            };

            struct VertexOutput
            {
                float4 pos : POSITION;
                float4 worldPos : TEXCOORD2;
                float3 normalWorld : TEXCOORD1;
                #if _LIGHTING_VERT
                    float4 surfaceColor: COLOR0;
                #endif
            };


            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                o.pos = UnityObjectToClipPos(v.pos);
                o.worldPos = v.pos;

                // Get the normals to world space
                o.normalWorld = UnityObjectToWorldNormal(v.normal);

                #if _LIGHTING_VERT
                float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos.xyz - o.worldPos);
                float3 lightDir = normalize(_WorldSpaceLightPos0);
                float3 lightColor = _LightColor0.xyz;
                float attenuation = 1;
                o.surfaceColor = float4(specularBlinnPhong(o.normalWorld, lightDir, worldSpaceViewDir, lightColor, _SpecularFactor, attenuation, _SpecularPower), 1.0);
                #endif

                return o;
            }


            ///////////////////////////////FRAGMENT SHADER///////////////////////////

            float4 frag(VertexOutput i) : COLOR
            {
                float3 worldNormalAtPixel = i.normalWorld;
                
                #if _LIGHTING_FRAG
                float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float3 lightDir = normalize(_WorldSpaceLightPos0);
                float3 lightColor = _LightColor0.xyz;
                float attenuation = 1;
                return float4(specularBlinnPhong(i.normalWorld, lightDir, worldSpaceViewDir, lightColor, _SpecularFactor, attenuation, _SpecularPower), 1.0);

                #elif _LIGHTING_VERT
                return i.surfaceColor;

                #else
                return float4(_WorldSpaceLightPos0.xyz, 1);

                #endif
            }

            ENDCG
        }
    }
}
