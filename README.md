# W3 TAA (Witcher 3 classic 1.32) - v0.1 EXPERIMENTAL

Proxy `dxgi.dll` que injeta TAA no Witcher 3 (DX11). **Esqueleto nao testado**: eu nao tenho o jogo,
entao a posicao exata da matriz de projecao precisa ser descoberta no seu PC (modo discovery).

## Opcao A - sem instalar nada: o GitHub compila para voce
1. Crie uma conta gratis em github.com e um repositorio novo (pode ser privado).
2. Envie TODO o conteudo da pasta `w3_taa` (inclusive a pasta oculta `.github`) para o repositorio
   (botao "Add file" > "Upload files"; arraste a pasta inteira).
3. Va na aba **Actions**, abra "build-dxgi-dll" e clique em **Run workflow** (ou espere o build do upload terminar).
4. Quando ficar verde, abra a execucao e baixe o artefato **w3_taa_pronto** (um .zip com `dxgi.dll`, `taa.hlsl`, `taa_mod.ini`).
5. Siga em "Instalacao" abaixo.

Se o build ficar vermelho, copie o texto do erro e me envie.

## Opcao B - Como compilar localmente (Windows, 64 bits)
```
cmake -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release
```
Gera `build/Release/dxgi.dll`. (MinHook e baixado automaticamente.)

## Instalacao
Copie para `The Witcher 3\bin\x64\`:
- `dxgi.dll`
- `taa.hlsl`
- `taa_mod.ini`

Jogue em **modo janela sem bordas ou tela cheia**, DX11, e **desative** o AA nativo do jogo se quiser comparar.

## Fluxo de trabalho

### Passo 1 - Discovery
Com `discovery=1`, abra o jogo, entre no mundo, mexa a camera e feche. Abra `taa_mod.log`.
Procure linhas assim:
```
[discovery] cbuffer 1024 bytes, offset 192: matriz de projecao (m[2][3]=+-1) m00=... m11=...
[discovery] candidato a velocidade: ... fmt=34 1920x1080
```
Me envie o log (ou as linhas) e eu ajusto o `.ini`.

### Passo 2 - Jitter
Preencha no `.ini`:
- `cb_size` = tamanho do cbuffer
- `jitter_x_offset` = offset do `proj[2][0]` = `offset_da_matriz + 8*4`  (matriz row-major: linha 2, coluna 0 -> indice 8 -> +32 bytes)
- `jitter_y_offset` = `offset_da_matriz + 9*4` (+36 bytes)

Se a matriz for column-major, os indices mudam (me avise o que apareceu no log).
Se a imagem ficar tremendo, tente `jitter_sign=-1.0`.

### Passo 3 - Velocidade
Se o log listar um candidato (R16G16) e a imagem tiver ghosting em movimento, ative `use_velocity=1`
e ajuste `velocity_scale` (pode precisar de sinal negativo ou escala diferente).

## Limitacoes conhecidas
- O resolve roda no backbuffer final (pos-tonemap, LDR, com UI). A UI tambem passa pelo TAA -> pode borrar HUD.
  Melhoria futura: mover o resolve para antes do passe de UI.
- Sem sharpening ainda.
- Cada cbuffer de camera pode ser escrito varias vezes por frame (sombras, reflexos); o jitter so deve
  atingir o cbuffer da camera principal. O filtro por `cb_size` ajuda, mas pode precisar refinar.
- Pode nao funcionar com overlays/injetores que tambem fazem hook em `dxgi.dll` (ReShade em modo dxgi).
  Se usar ReShade, renomeie o dele para `d3d11.dll`.
- Uso somente single-player. Nao use online/GOG Galaxy com anti-cheat.
