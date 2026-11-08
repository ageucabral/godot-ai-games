extends Control
## Cena principal: hub Na Lata (Ranking Global e lista de jogos) e, no Poção de Cores, o menu,
## os desafios do dia, a partida e o ranking do jogo.

@onready var hub: Control = $Hub
@onready var home: Control = $Home
@onready var daily: Control = $Daily
@onready var game: Control = $Game
@onready var ranking: Control = $Ranking

var dialog: DialogBox
## Para onde o botão Menu da partida volta (menu inicial ou desafios do dia).
var _return_screen: Control
## Para onde o Voltar do ranking leva (hub no Ranking Global, menu do jogo no ranking do jogo).
var _ranking_return: Control
## Prêmios já avisados nesta abertura do app (o aviso "Você ganhou!" sai uma vez).
var _announced: Dictionary = {}


func _ready() -> void:
	theme = GameStyle.build_theme()
	dialog = DialogBox.new()
	add_child(dialog)
	_return_screen = home
	_ranking_return = home
	hub.game_requested.connect(open_game)
	hub.global_ranking_requested.connect(open_global_ranking)
	home.hub_requested.connect(func() -> void: show_screen(hub))
	home.level_requested.connect(play_level)
	home.daily_requested.connect(func() -> void: show_screen(daily))
	home.ranking_requested.connect(open_game_ranking)
	daily.play_requested.connect(request_play)
	daily.back_requested.connect(func() -> void: show_screen(home))
	game.back_requested.connect(_leave_game)
	game.next_requested.connect(request_play)
	game.next_level_requested.connect(play_level)
	ranking.back_requested.connect(func() -> void: show_screen(_ranking_return))
	ranking.invite_requested.connect(func() -> void: Prizes.open_invite(dialog))
	ranking.claim_requested.connect(func(payout_id: String) -> void: Prizes.open_claim(dialog, payout_id))
	Server.home_updated.connect(_on_server_home)
	show_screen(hub)
	_connect_server()


## Entra no servidor (como visitante ou com a conta Google salva) e traz o progresso de lá. Se nunca conseguiu
## entrar (sem internet no 1º uso), o jogo segue só no aparelho; depois de entrar, jogar pede internet
## (os pontos só valem conferidos pelo servidor).
func _connect_server() -> void:
	if not Server.enabled:
		return
	await Server.load_config()
	if Account.check_gate(dialog):
		return  # versão antiga ou manutenção: não deixa jogar (o "Tentar de novo" continua daqui)
	await Account.connect_and_onboard(dialog)


## Voltou para o app (estava em segundo plano): confere de novo manutenção e versão mínima.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and Server.enabled and is_inside_tree():
		_recheck_gate()


func _recheck_gate() -> void:
	if await Server.load_config():
		Account.check_gate(dialog)


## Saiu da partida pelo menu: mede quem desistiu no meio e encerra a partida guiada.
func _leave_game() -> void:
	var info: Dictionary = game.quit_info()
	if not info.is_empty():
		Server.track("match_quit", info)
	game.end_tutorial(false)
	show_screen(_return_screen)


## Chegou o menu do Poção pelo servidor: redesenha a tela aberta (menos a partida).
func _on_server_home() -> void:
	for s in [hub, home, daily, ranking]:
		if s.visible and s.has_method("refresh"):
			s.refresh()
	# ganhou um prêmio: avisa uma vez por abertura (fora da partida e sem outra janela aberta)
	if game.visible:
		return
	for d: DialogBox in [dialog, hub.dialog, home.dialog]:
		if d.visible:
			return
	for p in Prizes.pending_payouts():
		var id := str(p.get("id", ""))
		if not _announced.has(id):
			_announced[id] = true
			Prizes.announce(dialog, p)
			return


## Entra num jogo do hub: mostra o menu do jogo com a tela de abertura por cima.
func open_game(_game_id: String) -> void:
	show_screen(home)
	add_child(SplashOverlay.new())


## Ranking Global (soma todos os jogos, vale prêmios), aberto pelo hub.
func open_global_ranking() -> void:
	_ranking_return = hub
	ranking.open_mode("global")
	show_screen(ranking)


## Ranking só do Poção de Cores, aberto pelo menu do jogo.
func open_game_ranking() -> void:
	_ranking_return = home
	ranking.open_mode("game", "potion")
	show_screen(ranking)


func show_screen(screen: Control) -> void:
	for s in [hub, home, daily, game, ranking]:
		s.visible = (s == screen)
	if screen != game:
		Server.track("screen_view", {"screen": str(screen.name).to_lower()})
	if screen.has_method("refresh"):
		screen.refresh()
	if Server.online() and screen != game:
		Server.refresh_home()  # pontos e desafios atualizados pelo servidor


## Abre o próximo nível do modo por níveis (sempre grátis; recomeçar pede propaganda).
## Se o jogador saiu no meio do nível, volta para a mesma partida (recomeçar do zero pede propaganda).
func play_level() -> void:
	_return_screen = home
	var resume: bool = game.can_resume_level(GameState.current_level())
	show_screen(game)
	if not resume:
		game.open_level(GameState.current_level())


## Abre um desafio de hoje. A primeira tentativa é grátis; as próximas pedem propaganda.
func request_play(date: String, index: int) -> void:
	_return_screen = daily
	if date != GameState.today():
		# só os desafios de hoje podem ser jogados
		dialog.open("Desafio encerrado", tr("Este desafio era de %s. Agora só valem os desafios de hoje.") % Rules.pretty_date(date), [
			["Ver desafios de hoje", func() -> void: show_screen(daily), true],
		])
		return
	var key := ChallengeGenerator.key_for(date, index)
	if GameState.attempts(key) == 0:
		_start(date, index)
		return
	var r := GameState.result(key)
	var text := tr("Você já tentou este desafio.")
	if r.completed:
		text = tr("Seu melhor aqui: %d pontos em %d jogadas.") % [r.best_points, r.best_moves]
	dialog.open(tr("Desafio %d") % (index + 1), text + tr("\nUma nova tentativa pede uma propaganda."), [
		["Assistir e jogar", func() -> void: _start_with_ad(date, index), true],
		["Voltar", func() -> void: show_screen(daily)],
	])


## Nova tentativa: pelo servidor, a propaganda vira um `rewardId` que ele confere.
func _start_with_ad(date: String, index: int) -> void:
	if not Server.online():
		Ads.show_rewarded(func() -> void: _start(date, index))
		return
	var reward_id: String = await Server.rewarded("retry", {"mode": ChallengeGenerator.key_for(date, index)})
	if reward_id.is_empty():
		dialog.open("Ops!", tr(ApiClient.error_text({"code": "REWARD_NOT_VERIFIED"})), [
			["Voltar", func() -> void: show_screen(daily), true],
		])
		return
	_start(date, index, reward_id)


func _start(date: String, index: int, reward_id: String = "") -> void:
	show_screen(game)
	game.open_challenge(date, index, reward_id)
