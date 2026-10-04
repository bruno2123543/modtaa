// taa.hlsl - resolve temporal (v0.1)
// Entradas: t0 = frame atual (com jitter), t1 = historico, t2 = velocidade (opcional)

cbuffer CB : register(b0) {
  float2 texel;
  float  blend;      // peso do frame atual (1.0 no primeiro frame)
  float  useVel;     // 1 = usar buffer de velocidade
  float  velScale;   // escala/sinal da velocidade -> UV
  float3 pad;
};

Texture2D    gCur  : register(t0);
Texture2D    gHist : register(t1);
Texture2D    gVel  : register(t2);
SamplerState gLin  : register(s0);

struct VSOut { float4 pos : SV_Position; float2 uv : TEXCOORD0; };

VSOut VS(uint id : SV_VertexID) {
  VSOut o;
  o.uv  = float2((id << 1) & 2, id & 2);
  o.pos = float4(o.uv * float2(2, -2) + float2(-1, 1), 0, 1);
  return o;
}

float3 ToYCoCg(float3 c) {
  return float3(0.25 * c.r + 0.5 * c.g + 0.25 * c.b,
                0.5 * c.r - 0.5 * c.b,
                -0.25 * c.r + 0.5 * c.g - 0.25 * c.b);
}
float3 FromYCoCg(float3 c) {
  return float3(c.x + c.y - c.z, c.x + c.z, c.x - c.y - c.z);
}

float4 PS(VSOut i) : SV_Target {
  float2 uv = i.uv;
  float3 cur = gCur.SampleLevel(gLin, uv, 0).rgb;

  // vizinhanca 3x3 em YCoCg
  float3 mn = 1e9, mx = -1e9, m1 = 0, m2 = 0;
  [unroll] for (int y = -1; y <= 1; y++) {
    [unroll] for (int x = -1; x <= 1; x++) {
      float3 c = ToYCoCg(gCur.SampleLevel(gLin, uv + float2(x, y) * texel, 0).rgb);
      mn = min(mn, c); mx = max(mx, c);
      m1 += c; m2 += c * c;
    }
  }
  float3 mu = m1 / 9.0;
  float3 sigma = sqrt(max(m2 / 9.0 - mu * mu, 0));
  float3 lo = max(mn, mu - 1.25 * sigma);
  float3 hi = min(mx, mu + 1.25 * sigma);

  // reprojecao
  float2 velUV = 0;
  if (useVel > 0.5) velUV = gVel.SampleLevel(gLin, uv, 0).rg * velScale;
  float2 huv = uv - velUV;

  float3 hist = ToYCoCg(gHist.SampleLevel(gLin, huv, 0).rgb);
  float3 histC = clamp(hist, lo, hi);

  // rejeita historico fora da tela
  float outside = any(huv < 0 || huv > 1) ? 1.0 : 0.0;
  float a = saturate(blend + outside);

  // reduz peso do historico quando o clamp mexeu muito (ghosting)
  float clampDist = length(hist - histC);
  a = saturate(a + clampDist * 4.0);

  float3 res = lerp(histC, ToYCoCg(cur), a);
  return float4(FromYCoCg(res), 1);
}
