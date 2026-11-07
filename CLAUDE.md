# CLAUDE.md — instruções permanentes do projeto

## Quem é o dono e como trabalhar
- O dono do projeto **não programa e não usa o editor Godot**. Todo o trabalho é feito
  pelo Claude Code na Web. Nunca peça para ele abrir o editor, mover nós ou clicar em nada.
- Converse e explique resultados em **português simples**, sem jargão. Código, nomes de
  arquivos, nós e variáveis ficam em inglês; comentários e textos do jogo em português.
- Trabalhe com autonomia técnica: decida a implementação, mas confirme mudanças de
  rumo do jogo (gênero, regras, estilo) antes de fazê-las.
- **Nunca diga que testes passaram sem tê-los executado** neste ambiente. Se algo não
  pôde ser executado, diga claramente o quê e por quê.

## Tecnologia
- Godot **4.7.2** (versão fixada em `tools/godot_version.env`), linguagem **GDScript** apenas
  (sem C#, sem GDExtension).
- Renderizador **Compatibility** (`gl_compatibility`) — obrigatório para exportar para Web.
  Não troque para Forward+ ou Mobile.
- Jogos **2D** para celular **em pé**: resolução base 720x1280, `stretch/mode = canvas_items`,
  `aspect = expand`, filtro de textura "Linear" (a arte é lisa, não pixel art).
- Exportação Web **sem threads** (`variant/thread_support=false`), para funcionar em
  qualquer hospedagem (ex.: GitHub Pages, itch.io) sem cabeçalhos especiais.

## Como o Godot roda aqui
O ambiente na nuvem não vem com Godot. O hook `SessionStart` em `.claude/settings.json`
roda `tools/session_start.sh`, que instala o Godot automaticamente (download oficial,
conferido por SHA-512) em `~/.local/share/godot-ci` com atalho `~/.local/bin/godot`.
Se faltar, rode manualmente:

```bash
tools/install_godot.sh              # motor (para testes)
tools/install_godot.sh --templates  # + modelos de exportação Web e Android (~1,3 GB de download)
tools/install_android_sdk.sh        # Android SDK mínimo (para gerar APK)
```

## Comandos do dia a dia
| Objetivo | Comando |
|---|---|
| Rodar todos os testes | `tools/run_tests.sh` |
| Rodar só alguns testes | `tools/run_tests.sh game_state` (filtra pelo nome do arquivo) |
| Exportar para Web | `tools/export_web.sh` → `build/web/` |
| Gerar APK de teste para Android | `tools/export_android.sh` → `build/android/na-lata-teste.apk` |
| Abrir o jogo Web num navegador sem tela e tirar foto | `tools/web_smoke_test.sh` → `build/web_screenshot.png` |
| Executar o Godot direto | `tools/godot.sh --headless --path . <args>` |

Depois de criar/renomear arquivos de recurso (imagens, sons, cenas), rode
`tools/godot.sh --headless --path . --import` para o Godot gerar os `.import`/`.uid`,
e **faça commit dos arquivos `.import` e `.uid`** gerados.

## Estrutura de pastas
```
scenes/       Cenas (.tscn) — uma subpasta por área: main/, levels/, ui/ ...
scripts/      Scripts GDScript (.gd); scripts/autoload/ = singletons globais
characters/   Personagens: uma subpasta por personagem com cena, script e sprites
assets/       Recursos visuais: sprites/, ui/, fonts/
audio/        music/ e sfx/
tests/        Testes automatizados (tests/unit/test_*.gd) + executor
tools/        Scripts de instalação, testes e exportação
build/        Saída da exportação (ignorada pelo git)
```

## Regras de código
- Tipagem estática sempre que possível (`var speed: float = 200.0`, `-> void`).
- Nomes: arquivos e pastas em `snake_case`; classes/nós em `PascalCase`.
- Prefira lógica em funções pequenas e testáveis (de preferência `static` ou sem
  depender da árvore de cenas), e deixe os nós só "ligarem" essa lógica.
- Edite `.tscn` com cuidado (formato texto `format=3`). Depois de editar, rode os testes:
  eles verificam que **todas** as cenas e scripts carregam.
- Não adicione plugins/addons de terceiros sem necessidade e sem avisar.
- Recursos (imagens/sons) devem ter licença livre ou ser gerados; registre a origem
  em `assets/CREDITS.md` quando houver.

## Testes
- Executor próprio, sem dependências: `tests/run_tests.gd`.
- Ele primeiro carrega todos os `.gd` e `.tscn` de `scenes/`, `scripts/` e `characters/`
  (pega erros de sintaxe) e depois roda cada função `test_*()` de `tests/unit/test_*.gd`.
- Um teste novo:
  ```gdscript
  extends "res://tests/test_case.gd"

  func test_algo() -> void:
      assert_eq(1 + 1, 2, "soma")
  ```
  Assertivas: `assert_true`, `assert_false`, `assert_eq`, `assert_ne`, `assert_not_null`,
  `assert_almost_eq`. Ganchos: `before_each()`, `after_each()`. Pode usar `await`
  (ex.: `await wait_physics_frames(10)`).
- Toda mecânica nova deve vir com pelo menos um teste.
- Antes de concluir uma tarefa: `tools/run_tests.sh` e, se mexeu em algo visual ou na
  exportação, `tools/export_web.sh` + `tools/web_smoke_test.sh` e olhar a captura.

## Integração contínua
`.github/workflows/godot.yml` roda testes e exportações a cada PR e guarda os artefatos
`jogo-web` e `jogo-android` (APK de teste). `.github/workflows/pages.yml` publica a versão Web
no GitHub Pages a cada mudança na `main` (precisa do Pages ligado com origem "GitHub Actions").

## Estado atual
Jogo: **Na Lata**, quebra-cabeça de separar cores despejando líquido entre garrafinhas
(Android / Google Play). Estilo visual escolhido: **Feira Tropical** (garrafinhas de vidro com
tampinha vermelha, fundo de azulejo, contorno marrom forte, letras Lilita One + Nunito).
Cores, letras, tema e o desenho da garrafa ficam em `scripts/game/tropical_style.gd`.
- `scripts/game/rules.gd`: regras do documento do jogo (pontos 10/25/50, 8+7+5 desafios por dia,
  +5 jogadas por propaganda, datas no horário de Brasília).
- `scripts/game/challenge_generator.gd`: gera os 20 desafios do dia, iguais para todos (semente
  FNV-1a de "AAAA-MM-DD#n"), com o número exato de jogadas calculado por `SortPuzzle.min_moves`.
- `scripts/game/sort_puzzle.gd`: regras de despejar, camadas escondidas ("?") e lista de jogadas.
- `scripts/autoload/game_state.gd`: tentativas e melhor resultado salvos no aparelho.
- `scripts/autoload/ads.gd`: propaganda **simulada** (3 s). O AdMob de verdade entra aqui depois.
- Cena principal `scenes/main/main.tscn`: menu (`scenes/ui/home_screen.tscn`), partida
  (`scenes/game/game_screen.tscn`, com animação de despejo) e ranking (`scenes/ui/ranking_screen.tscn`).
- Ainda não existem: contas e servidor (Supabase), ranking com todos os jogadores, AdMob real.
