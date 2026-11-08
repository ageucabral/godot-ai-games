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
| Gerar o pacote da Google Play (AAB assinado) | `NALATA_KEYSTORE=… NALATA_KEYSTORE_PASSWORD=… NALATA_KEY_ALIAS=… NALATA_KEY_PASSWORD=… tools/export_android_release.sh` → `build/android/na-lata.aab` |
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
- `scripts/autoload/game_state.gd`: nível, tentativas e melhor resultado salvos no aparelho (pelo servidor, cópia
  do que ele conferiu).
- `scripts/autoload/ads.gd`: propaganda premiada. No Android com o plugin é o AdMob de verdade; sem o plugin
  (Web, testes) é uma **simulação** de 3 s.
- Cena principal `scenes/main/main.tscn`: hub (`scenes/ui/hub_screen.tscn`), tela inicial do Poção de Cores
  (`scenes/ui/home_screen.tscn`: pontos do mês, configurações, nome do jogo, mascote, botão "Nível N"
  e, logo abaixo, o botão laranja "Desafios do dia 3/20" (fica roxo com "Desafios feitos!" quando o dia acaba);
  na lateral direita, ícones de linha Jogos · Ranking (`scripts/ui/side_button.gd`); sem barra embaixo, o perfil fica dentro da engrenagem (Ageu, 8/11/2026)), desafios do dia
  (`scenes/ui/daily_screen.tscn`), partida (`scenes/game/game_screen.tscn`, só mostra Fácil/Médio/Difícil nos desafios; com animação de despejo, pausa
  na engrenagem e confete na vitória) e ranking (`scenes/ui/ranking_screen.tscn`). Perfil e configurações
  ficam em `scripts/ui/menus.gd`.
- **Dois rankings** (Ageu, 7/11/2026): cada jogo tem o seu ranking (aberto pelo menu do jogo) e o
  **Ranking Global** soma todos os jogos e é o que vale prêmios (faixa dourada no hub,
  `scripts/ui/global_rank_banner.gd`). `ranking_screen.gd` tem os dois modos (`open_mode`);
  `GameState.global_month_total` soma os jogos de `GameState.GAME_IDS`. Hoje todo o progresso salvo é do
  Poção de Cores: o segundo jogo vai precisar separar os pontos por jogo no salvamento.
- Ilustrações (OpenRouter/Nano Banana) em `assets/art/`: hub_bg, home_bg, game_bg (1080x1920), splash,
  mascot e potion_card (cartão do jogo no hub). Os fundos e o cartão sempre usam essas imagens (não há desenho
  de reserva no código).
- **Servidor** (Ageu, 8/11/2026): o jogo usa a API do app antigo (`ageucabral/na-lata-web`, api.nalatagame.tech;
  rotas `/pocao/*` em `docs/api.md` de lá). `scripts/autoload/server.gd` (autoload `Server`) entra como visitante e
  faz as chamadas; `scripts/net/api_client.gd` tem as funções puras. **Ligado só no Android** (`Server.enabled`); na
  Web e nos testes o jogo continua só no aparelho. Pelo servidor: as fases vêm de lá, as ajudas e novas tentativas
  pedem uma recompensa (`POST /rewards` → propaganda → `rewardId`), o fim manda a lista de jogadas e os pontos
  mostrados são os que o servidor conferiu; `GameState.apply_server_home` copia nível, desafios de hoje e pontos do
  mês para as telas. Testes com servidor de mentira em `tests/unit/test_server_flow.gd`.
- **Plugin Android** (`android/plugin`, Kotlin, singleton `NaLata`): login com Google (Credential Manager, cliente
  Web `Server.GOOGLE_WEB_CLIENT_ID`) e propaganda premiada do AdMob com SSV (`customData` = rewardId do servidor,
  `userId` = id do jogador; bloco vem do `GET /config`). O `.aar` compilado fica em `addons/nalata_android/bin/`
  (refazer com `tools/build_android_plugin.sh` ao mudar o Kotlin) e entra no APK pelo `addons/nalata_android`
  (export plugin). Por isso o Android exporta com **Gradle build** (`android/build`, instalado pelo
  `tools/export_android.sh`; API 36, build-tools 36.1.0). Sem o plugin, `Ads` simula e "Sua conta" diz que o login com Google fica no app da Play Store.
  Testes com plugin de mentira (`Server.native_override`). O plugin também lê o convite do link da Play (install
  referrer), abre o "compartilhar" do Android e pede o token do Play Integrity.
- **Conta, ajuda e prêmios** (Ageu, 8/11/2026; só jogando pelo servidor): `scripts/ui/account.gd` tem a idade na
  primeira abertura (com o código de convite que veio pelo link da Play), país e apelido depois de entrar com Google,
  "Sua conta" (apagar conta dentro do app, exigência da Play), "Ajuda e termos" (fale conosco, privacidade, termos,
  regulamento) e o aviso que não deixa jogar com **versão antiga** (`minAppVersion` do painel) ou **manutenção**.
  `scripts/ui/prizes.gd`: convidar amigos (regra dos **3 amigos que jogam 3 dias** continua, Ageu 8/11/2026), aviso
  "Você ganhou!" (lista `payouts` do `GET /pocao/home`) e resgate por Pix (com cotação) ou USDT. O Ranking Global mostra
  os prêmios do mês e os botões Convidar/Resgatar. A engrenagem: Sua conta · Idioma · Som · Como jogar · Ajuda e termos.
- **Play Integrity**: o plugin pede o token (nonce `nalata:<aparelho>:<ms>`, projeto Cloud 969286539124) e manda no
  login; o servidor confere com a conta de serviço `PLAY_INTEGRITY_CREDENTIALS` e só bloqueia com "Exigir Play
  Integrity" ligado no painel. Falta o dono ligar o projeto Cloud na Play Console e criar a conta de serviço.
- **Sons** (`scripts/autoload/sfx.gd`, autoload `Sfx`; arquivos gerados por `tools/gen_sounds.py`), liga/desliga na
  engrenagem. **Primeira partida guiada** no nível 1 (setinha com `SortPuzzle.hint_move`). **Medição**: `Server.track`
  manda `POST /events` (app_open, screen_view, tutorial_done/skipped, match_quit, invite_shared).
- Ainda não existem: música, aviso de consentimento de anúncios (Europa), avisos no celular.
  O APK de teste usa o pacote `com.ageucabral.nalata` (instala ao lado do app da Play). A versão da Play é o
  preset **"Android Play"**: AAB, pacote `app.nalata.android` (atualização do app Expo, que parou no versionCode 17),
  versionCode 21+ (o 20 foi só rascunho), versão 1.3.1 (versionCode 22; a 1.3.0 está **publicada na Play**; o dono quer seguir em 1.3.x), ícones do app antigo em `assets/icons/`. A chave de envio (upload key, do expo.dev)
  **nunca** vai para o git: entra por variáveis `NALATA_*` no `tools/export_android_release.sh`.
  Para a Play vão também x86/x86_64 (Chromebooks e aparelhos Intel; a Play entrega só a parte de cada aparelho) e as
  bibliotecas nativas comprimidas. Avisos da Play que não têm conserto: o Godot exige OpenGL ES 3.0 (celulares muito
  antigos ficam de fora) e o motor oficial não traz símbolos de depuração nem usa R8.
  A cada nova versão da Play, suba `version/code` (e `version/name` + `Menus.VERSION`).
