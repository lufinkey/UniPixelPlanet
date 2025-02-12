Shader "PixelPlanets/Standard/GasLayers"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
	    _Pixels("Pixels", range(10,100)) = 0.0
	    _Rotation("Rotation",range(0.0, 6.28)) = 0.0    		    
    	_Light_origin("Light origin", Vector) = (0.39,0.39,0.39,0.39)
	    _Time_speed("Time Speed",range(-1.0, 1.0)) = 0.2
	    _Stretch("Stretch",range(1.0,3.0)) = 2.0
    	_Cloud_cover("Cloud Cover",range(0.0, 1.0)) = 0.3
	    _Cloud_curve("Cloud Curve",range(1.0, 2.0)) = 1.3
	    _Light_border_1("Light border1",range(0.0, 1.0)) = 0.52
	    _Light_border_2("Light border2",range(0.0, 1.0)) = 0.62
    	_Bands("Bands",float) = 1.0

        _ColorScheme("ColorScheme", 2D) = "white" {}
    	_Dark_ColorScheme("Dark ColorScheme", 2D) = "white" {}

	    _Size("Size",float) = 50.0
	    _OCTAVES("OCTAVES", range(0,20)) = 0
	    _Seed("Seed",range(1, 10)) = 7.46
	    time("time",float) = 0.0
    }
    SubShader
    {
        //Tags { "RenderType"="Opaque" }
        Tags { "RenderType"="Opaque" "IgnoreProjector" = "True"}
        LOD 100

        Pass
        {
			Tags { "LightMode"="ForwardBase"}

			CULL Off
			ZWrite Off // don't write to depth buffer 
         	Blend SrcAlpha OneMinusSrcAlpha // use alpha blending
        	
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "../cginc/hlmod.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Pixels;
            float _Rotation;
			float2 _Light_origin;    	
			float _Time_speed;
            float _Stretch;
            float _Cloud_curve;
            float _Cloud_cover;
            float _Light_border_1;
			float _Light_border_2;
            float _Bands;
			sampler2D _ColorScheme;
            sampler2D _Dark_ColorScheme;
            float _Size;
            int _OCTAVES;
            int _Seed;
			float time;
            
			struct Input
	        {
	            float2 uv_MainTex;
	        };
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
			float rand(float2 coord) {
				coord = mod(coord, float2(2.0,1.0)*round(_Size));
				return frac(sin(dot(coord.xy ,float2(12.9898,78.233))) * 15.5453 * _Seed);
			}

			float noise(float2 coord){
				float2 i = floor(coord);
				float2 f = frac(coord);
				
				float a = rand(i);
				float b = rand(i + float2(1.0, 0.0));
				float c = rand(i + float2(0.0, 1.0));
				float d = rand(i + float2(1.0, 1.0));

				float2 cubic = f * f * (3.0 - 2.0 * f);

				return lerp(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
			}

			float fbm(float2 coord){
				float value = 0.0;
				float scale = 0.5;

				for(int i = 0; i < _OCTAVES ; i++){
					value += noise(coord) * scale;
					coord *= 2.0;
					scale *= 0.5;
				}
				return value;
			}


			// by Leukbaars from https://www.shadertoy.com/view/4tK3zR
			float circleNoise(float2 uv) {
			    float uv_y = floor(uv.y);
			    uv.x += uv_y*.31;
			    float2 f = frac(uv);
				float h = rand(float2(floor(uv.x),floor(uv_y)));
			    float m = (length(f-0.25-(h*0.5)));
			    float r = h*0.25;
			    return smoothstep(0.0, r, m*0.75);
			}

			float turbulence(float2 uv) {
				float c_noise = 0.0;
				
				
				// more iterations for more turbulence
				for (int i = 0; i < 10; i++) {
					c_noise += circleNoise((uv * _Size *0.3) + (float(i+1)+10.) + (float2(time * _Time_speed, 0.0)));
				}
				return c_noise;
			}
			bool dither(float2 uv_pixel, float2 uv_real) {
				return mod(uv_pixel.x+uv_real.y,2.0/_Pixels) <= 1.0 / _Pixels;
			}

			float2 spherify(float2 uv) {
				float2 centered= uv *2.0-1.0;
				float z = sqrt(1.0 - dot(centered.xy, centered.xy));
				float2 sphere = centered/(z + 1.0);
				return sphere * 0.5+0.5;
			}

			float2 rotate(float2 coord, float angle){
				coord -= 0.5;
				//coord *= float2x2(float2(cos(angle),-sin(angle)),float2(sin(angle),cos(angle)));
            	coord = mul(coord,float2x2(float2(cos(angle),-sin(angle)),float2(sin(angle),cos(angle))));
				return coord + 0.5;
			}

			fixed4 frag(v2f i) : COLOR {
				// pixelize uv
            	
				float2 uv = floor(i.uv*_Pixels)/_Pixels;				
				//uv.y = 1 - uv.y;				
			
				float light_d = distance(uv, _Light_origin) ;
	
				// we use this value later to dither between colors
				bool dith = dither(uv, i.uv);
				uv = rotate(uv, _Rotation);

				
				// map to sphere
				uv = spherify(uv);

				// a band is just one dimensional noise
				float band = fbm(float2(0.0, uv.y*_Size*_Bands));
				
				// turbulence value is circles on top of each other
				float turb = turbulence(uv);

				// by layering multiple noise values & combining with turbulence and _Bands
				// we get some dynamic looking shape	
				float fbm1 = fbm(uv*_Size);
				float fbm2 = fbm(uv*float2(1.0, 2.0)*_Size+fbm1+float2(-time*_Time_speed,0.0)+turb);

				
				// all of this is just increasing some contrast & applying light
				fbm2 *= pow(band,2.0)*7.0;
				float light = fbm2 + light_d * 1.8;
				fbm2 += pow(light_d , 1.0)-0.3;	
				fbm2 = smoothstep(-0.2, 4.0-fbm2, light);
				
				// here apply the dither value
				if (dith ) {
					fbm2 *= 1.1;
				}
				
				// finally add colors
				float posterized = floor(fbm2*4.0)/2.0;
				float3 col;
				if (fbm2 < 0.625) {
					col = tex2D(_ColorScheme, float2(posterized, uv.y)).rgb;
				} else {
					col = tex2D(_Dark_ColorScheme, float2(posterized-1.0, uv.y)).rgb;
				}
				
				float a = step(length(uv-float2(0.5,0.5)), 0.5);
				return fixed4(col, a);
			}
            
            ENDCG
        }
    }
}
