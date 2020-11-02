Shader "Unlit/Portal"
{
    Properties
    {
        _Depht ("Depht", Range(0, 10)) = 1
        _MainColor("Color1", color) = (1, 1, 1, 1)
        _SecondaryColor("Color 2", color) = (0, 0, 0, 1)
        _RayColor("Ray Color", color) = (0, 0, 0, 1)
        _ColorBalance("ColorBalance", Range(0, 1)) = 0.0
        _DirBalance("Direction balance", Range(0, 1)) = 0.0
        _Sharpness("Sharpness", Range(0, 1)) = 0.0
        _DirSharpness("Direction sharpness", Range(0, 1)) = 0.0
        _DirIter("Direction iteration", int) = 3
        _Speed ("Speed", Range(0, 10)) = 1
        _DirSpeed ("Direction Speed", Range(0, 10)) = 1
        _FrequencyMin ("Frequency Min", Range(0, 20)) = 0.1
        _FrequencyMax ("Frequency Max", Range(0, 20)) = 0.2
        _FrequencyRay ("Frequency Ray", Range(0, 40)) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            uniform float _Depht;
            uniform float _FrequencyMin;
            uniform float _FrequencyMax;
            uniform float _FrequencyRay;
            uniform float _Speed;
            uniform float _DirSpeed;
            uniform float4 _MainColor;
            uniform float4 _SecondaryColor;
            uniform float4 _RayColor;
            uniform float _ColorBalance;
            uniform float _Sharpness;
            uniform float _DirSharpness;
            uniform float _DirBalance;
            uniform int _DirIter;

            #include "UnityCG.cginc"


            ////////////////////////////////GLOBAL FUNCTIONS//////////////////////////

            float distance2D(float2 position1, float2 position2)
            {
                return sqrt(pow(position2.x - position1.x, 2) + pow(position2.y - position1.y, 2));
            }

            float fit(float value, float inMin, float inMax, float outMin, float outMax)
            {
                return outMin + ((value - inMin) / (inMax - inMin)) * (outMax - outMin);
            }

            float random (float2 seed)
            {
                return frac(sin(dot(seed,float2(12.9898,78.233)))*43758.5453123);
            }

            float2 cartesianToPolar(float2 cartesianCoord, float2 center)
            {
                float2 polarCoord;
                polarCoord.x = distance2D(cartesianCoord, center);
                if(dot(normalize(cartesianCoord - center), float2(0.0, 1.0)) < 0)
                {
                    polarCoord.y = fit(dot(normalize(cartesianCoord - center), float2(1.0, 0.0)), -1, 1, 0, 1);
                }
                else
                {
                    polarCoord.y = 360 - fit(dot(normalize(cartesianCoord - center), float2(1.0, 0.0)), -1, 1, 0, 1);
                }
                polarCoord.y = fit(dot(normalize(cartesianCoord - center), float2(1.0, 0.0)), -1, 1, 0, 1);
                return polarCoord;
            }

            float random (float seed)
            {
                return frac(sin(seed)*43758.5453123);
            }

            float perlin(float2 pos)
            {
                float2 i = floor(pos);
                float2 f = frac(pos);

                float a = random(i);
                float b = random(i + float2(1.0, 0.0));
                float c = random(i + float2(0.0, 1.0));
                float d = random(i + float2(1.0, 1.0));

                float2 u = smoothstep(0.,1.0,f);

                return lerp(a, b, u.x) +
                        (c - a)* u.y * (1.0 - u.x) +
                        (d - b) * u.x * u.y;
            }


            /////////////////////////////////VERTEX SHADER///////////////////////////

            struct appdata
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float4 worldPos : POSITION;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 worldTangent : TEXCOORD3;
                float3 worldBinormal : TEXCOORD4;
            };

            v2f vert (appdata vertIN)
            {
                v2f vertOUT;
                vertOUT.pos = UnityObjectToClipPos(vertIN.pos);
                vertOUT.uv = vertIN.uv;
                vertOUT.worldPos = mul(unity_ObjectToWorld, vertIN.pos);
                vertOUT.worldNormal = UnityObjectToWorldNormal(vertIN.normal);
                vertOUT.worldTangent = UnityObjectToWorldNormal(vertIN.tangent);
                vertOUT.worldBinormal = normalize(cross(vertOUT.worldNormal, vertOUT.worldTangent));
                return vertOUT;
            }

            ///////////////////////////////FRAGMENT SHADER///////////////////////////

            float4 frag (v2f fragIN) : SV_Target
            {
                float depht = _Depht;
                float3 viewAngle = normalize(fragIN.worldPos.xyz - _WorldSpaceCameraPos.xyz);
                float deltaAngleX = fit(dot(viewAngle, fragIN.worldTangent)*depht, -1, 1, 0, 1);
                float deltaAngleY = fit(dot(viewAngle, fragIN.worldBinormal)*depht, -1, 1, 0, 1);

                float2 center = float2(1-deltaAngleX, deltaAngleY);

                float distance = distance2D(center, fragIN.uv);
                float distanceWave = sin(distance*fit(distance, 0, 2, _FrequencyMin, _FrequencyMax)+(_Time.y*_Speed));
                float ramp = fit(distanceWave+_ColorBalance, -1 + _Sharpness, 1 - _Sharpness, -1, 1);
                float4 color = lerp(_MainColor, _SecondaryColor, ramp)*fit(distance, 0, _Depht/2, 1, 0);

                float directionRamp = 1;

                for(int i = 0; i < _DirIter; i++)
                {
                    float3 direction;
                    direction.xy = fragIN.uv - center;
                    direction.z = 0;
                    direction = normalize(direction);
                    float directionAngle = dot(direction, float3(1, 0, 0));
                    float directionWave = sin((directionAngle + (_Time.y*_DirSpeed*sin(random(i))+0.2354))*_FrequencyRay);
                    directionRamp *= clamp(fit(directionWave+_DirBalance, -1 + _DirSharpness, 1 - _DirSharpness, 0, 1), 0, 1);
                }


                float2 polarUV = cartesianToPolar(fragIN.uv, center);
                polarUV.y *= 20;
                polarUV.x += _Time.y*_DirSpeed*2;
                float noise = fit(perlin(polarUV*5),0.4, 0.6, 0, 0.2);

                
                float2 polarUVDot = cartesianToPolar(fragIN.uv, center);
                polarUVDot.y *= 30;
                polarUVDot.x *= 2.0;
                polarUVDot.x += _Time.y*_DirSpeed;
                float noiseDot = clamp(fit(perlin(polarUVDot*5+float2(50, 50)),0.9, 0.99, 0, 1.0), 0, 1);

                float2 polarUVOver = cartesianToPolar(fragIN.uv, float2(0.5, 0.5));
                polarUVOver.y *= 10;
                polarUVOver.x *= 0.2;
                polarUVOver.x += _Time.x*_DirSpeed*5;
                float noiseOverTemp = clamp(fit(perlin(polarUVOver*5+float2(100, 100)),0, 1, 0, 0.1), 0, 1);
                float2 newUV = fragIN.uv + normalize(fragIN.uv - float2(0.5, 0.5))*noiseOverTemp;
                float noiseOver = clamp(fit(distance2D(newUV, float2(0.5, 0.5)), 0.4, 0.5, 0, 0.8), 0, 1);


                float4 circleColor = lerp(_RayColor, color, directionRamp) * clamp(fit(distance, 0.8, _Depht/2, 1, 0), 0, 1);
                float4 rayColor = lerp(circleColor, _MainColor, noise);
                float4 rayDot = lerp(rayColor, _RayColor, noiseDot);
                float4 final = lerp(rayDot, float4(0.1, 0.05, 0.05, 1), noiseOver);
                
                return final;
            }
            ENDCG
        }
    }
}
