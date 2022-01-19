Shader "DualKawaseBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Offset("float", Float) = 0
        
    }
    SubShader
    {

        Pass
        {
            Name "DownSample"
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 uv01: TEXCOORD1;
                float4 uv23: TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float2 _MainTex_TexelSize;
                float _Offset;
            CBUFFER_END

            TEXTURE2D(_MainTex);          SAMPLER(sampler_MainTex);

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
#if UNITY_UV_STARTS_TOP
                o.uv.y = 1 - o.uv.y;
#endif          
                _MainTex_TexelSize *= 0.5;
                float2 offset = float2(1 + _Offset, 1 + _Offset);
                o.uv01.xy = o.uv - _MainTex_TexelSize * offset;
                o.uv01.zw = o.uv + _MainTex_TexelSize * offset;
                o.uv23.xy = o.uv - float2(_MainTex_TexelSize.x, -_MainTex_TexelSize.y) * offset;
                o.uv23.zw = o.uv + float2(_MainTex_TexelSize.x, -_MainTex_TexelSize.y) * offset;

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * 4;
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv01.xy);
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv01.zw);
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv23.xy);
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv23.zw);

                return col * 0.125;
            }

            ENDHLSL
        }

        Pass
        {
            Name "UpSample"
            HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 uv01:TEXCOORD1;
                float4 uv23:TEXCOORD2;
                float4 uv45:TEXCOORD3;
                float4 uv67:TEXCOORD4;
            };

            CBUFFER_START(UnityPerMaterial)
                float2 _MainTex_TexelSize;
                float _Offset;
            CBUFFER_END

            TEXTURE2D(_MainTex);          SAMPLER(sampler_MainTex);

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
#if UNITY_UV_STARTS_TOP
                o.uv.y = 1 - o.uv.y;
#endif
                _MainTex_TexelSize *= 0.5;
                float2 offset = float2(1 + _Offset, 1 + _Offset);
                o.uv01.xy = o.uv + float2(-_MainTex_TexelSize.x * 2, 0) * offset;
                o.uv01.zw = o.uv + float2(-_MainTex_TexelSize.x, _MainTex_TexelSize.y) * offset;
                o.uv23.xy = o.uv + float2(0, _MainTex_TexelSize.y * 2) * offset;
                o.uv23.zw = o.uv + _MainTex_TexelSize * offset;
                o.uv45.xy = o.uv + float2(_MainTex_TexelSize.x * 2, 0) * offset;
                o.uv45.zw = o.uv + float2(_MainTex_TexelSize.x, -_MainTex_TexelSize.y) * offset;
                o.uv67.xy = o.uv + float2(0, -_MainTex_TexelSize.y * 2) * offset;
                o.uv67.zw = o.uv - _MainTex_TexelSize * offset;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
               half4 col = 0;
               col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv01.xy);
               col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv01.zw) * 2;
               col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv23.xy);
               col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv23.zw) * 2;
               col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv45.xy);
               col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv45.zw) * 2;
               col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv67.xy);
               col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv67.zw) * 2;

                return col * 0.0833;
            }

            ENDHLSL
        }
    }
}
