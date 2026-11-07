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
- Todo PR passa pela revisão `/code-review` (com correções) e é juntado pelo Claude ao final.
- Antes de concluir uma tarefa: `tools/run_tests.sh` e, se mexeu em algo visual ou na
  exportação, `tools/export_web.sh` + `tools/web_smoke_test.sh` e olhar a captura.

## Integração contínua
`.github/workflows/godot.yml` roda testes e exportações a cada PR e guarda os artefatos
`jogo-web` e `jogo-android` (APK de teste). `.github/workflows/pages.yml` publica a versão Web
no GitHub Pages a cada mudança na `main` (precisa do Pages ligado com origem "GitHub Actions").

## Estado atual
Jogo: **Na Lata**, quebra-cabeça de separar cores despejando líquido entre garrafinhas
(Android / Google Play). O app abre no **hub Na Lata** (lista de jogos); o primeiro jogo é o
**Poção de Cores**. Estilo visual: colorido e brilhante (frascos de poção, botões "de bala" com brilho,
céu de fim de tarde no menu e noite estrelada na partida, contorno roxo-escuro, letras Lilita One + Nunito).
**Colorido, mas clean, moderno e profissional** (Ageu, 7/11/2026): poucos botões, um caminho só para cada
lugar (nada de selo + aba + avatar levando ao mesmo destino), textos curtos.
Cores, letras, tema, botões e o desenho do frasco ficam em `scripts/game/game_style.gd`; ícones em
`scripts/ui/icons.gd` e fundos animados em `scripts/ui/scene_background.gd`.
- `scripts/game/rules.gd`: regras do documento do jogo (8+7+5 desafios por dia, +5 jogadas por propaganda,
  datas no horário de Brasília). **Pontos** (Ageu, 7/11/2026): toda fase (nível ou desafio) vale o dobro do
  número exato de jogadas (`Rules.full_points_for`: 11 jogadas → 22 pontos); cada jogada a mais tira 1 ponto,
  e a partida mostra o placar caindo ao vivo (fica vermelho e sobe um "-1"). O placar fica num lugar só
  (moeda + "PONTOS", ao lado das jogadas). Ajudas na partida: **embaralhar** (3 por fase) e **frasco extra**
  (1 por fase); cada uso pede propaganda e tira 1 ponto (`Rules.BOOST_COST`). O +5 jogadas aparece só no aviso
  de "Acabaram as jogadas".
- Só os desafios de HOJE podem ser jogados (Ageu, 7/11/2026); dias anteriores ficam encerrados.
- `scripts/game/challenge_generator.gd`: gera os 20 desafios do dia, iguais para todos (semente
  FNV-1a de "AAAA-MM-DD#n"), com o número exato de jogadas calculado por `SortPuzzle.min_moves`.
- **Modo por níveis** (Ageu, 7/11/2026): níveis sem fim, iguais para todos (`scripts/game/level_generator.gd`,
  semente "nivel#N"), com a dificuldade subindo aos poucos em degraus (`Rules.LEVEL_STEPS`): mais cores/frascos,
  **frasco coberto** a partir do 10 (pano com selo de uma cor; abre quando uma garrafa daquela cor fica completa,
  como na foto que o Ageu mandou), **cor repetida** (duas garrafas da mesma cor) a partir do 15 e camadas "?" a
  partir do 30. Os pontos entram no ranking do mês em que o nível foi resolvido. Não dá para rejogar nível passado.
- Frascos cobertos ficam em `SortPuzzle.covers` (o resolvedor respeita); a cor do selo nunca fica debaixo de um
  pano. Desafios médios têm 1 pano e difíceis 2.
- Idiomas: português (padrão), inglês e espanhol em `scripts/game/i18n.gd` (o texto em português é a
  chave). Textos montados com números usam `tr("...") % valores`.
- `scripts/game/sort_puzzle.gd`: regras de despejar, camadas escondidas ("?") e lista de jogadas.
- `scripts/autoload/game_state.gd`: tentativas e melhor resultado salvos no aparelho.
- `scripts/autoload/ads.gd`: propaganda **simulada** (3 s). O AdMob de verdade entra aqui depois.
- Cena principal `scenes/main/main.tscn`: hub (`scenes/ui/hub_screen.tscn`), tela inicial do Poção de Cores
  (`scenes/ui/home_screen.tscn`: pontos do mês, configurações, nome do jogo, mascote, botão "Nível N"
  e barra de baixo Jogos · Ranking · Início · Desafios · Perfil, com a contagem dos desafios do dia), desafios do dia
  (`scenes/ui/daily_screen.tscn`), partida (`scenes/game/game_screen.tscn`, com animação de despejo, pausa
  na engrenagem e confete na vitória) e ranking (`scenes/ui/ranking_screen.tscn`). Perfil e configurações
  ficam em `scripts/ui/menus.gd`.
- **Dois rankings** (Ageu, 7/11/2026): cada jogo tem o seu ranking (aberto pelo menu do jogo) e o
  **Ranking Global** soma todos os jogos e é o que vale prêmios (faixa dourada no hub,
  `scripts/ui/global_rank_banner.gd`). `ranking_screen.gd` tem os dois modos (`open_mode`);
  `GameState.global_month_total` soma os jogos de `GameState.GAME_IDS`. Hoje todo o progresso salvo é do
  Poção de Cores: o segundo jogo vai precisar separar os pontos por jogo no salvamento.
- Ilustrações (OpenRouter/Nano Banana) em `assets/art/`: hub_bg, home_bg, game_bg (1080x1920), splash,
  mascot e potion_card (cartão do jogo no hub).
- Ainda não existem: contas e servidor (Supabase), login Google/Facebook ("Salvar progresso" mostra
  "em breve"), ranking com todos os jogadores, AdMob real, sons.
