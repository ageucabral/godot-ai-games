extends Control
## Cena principal: hub Na Lata (lista de jogos) e, no Poção de Cores, o menu, os desafios do dia,
## a partida e o ranking.

@onready var hub: Control = $Hub
@onready var home: Control = $Home
@onready var daily: Control = $Daily
@onready var game: Control = $Game
@onready var ranking: Control = $Ranking

var dialog: DialogBox
## Para onde o botão Menu da partida volta (menu inicial ou desafios do dia).
var _return_screen: Control


func _ready() -> void:
	theme = GameStyle.build_theme()
	dialog = DialogBox.new()
	add_child(dialog)
	_return_screen = home
	hub.game_requested.connect(open_game)
	home.hub_requested.connect(func() -> void: show_screen(hub))
	home.level_requested.connect(play_level)
	home.daily_requested.connect(func() -> void: show_screen(daily))
	home.ranking_requested.connect(func() -> void: show_screen(ranking))
	daily.play_requested.connect(request_play)
	daily.back_requested.connect(func() -> void: show_screen(home))
	game.back_requested.connect(func() -> void: show_screen(_return_screen))
	game.next_requested.connect(request_play)
	game.next_level_requested.connect(play_level)
	ranking.back_requested.connect(func() -> void: show_screen(home))
	show_screen(hub)


## Entra num jogo do hub: mostra o menu do jogo com a tela de abertura por cima.
func open_game(_game_id: String) -> void:
	show_screen(home)
	add_child(SplashOverlay.new())


func show_screen(screen: Control) -> void:
	for s in [hub, home, daily, game, ranking]:
		s.visible = (s == screen)
	if screen.has_method("refresh"):
		screen.refresh()


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
		["Assistir e jogar", func() -> void: Ads.show_rewarded(func() -> void: _start(date, index)), true],
		["Voltar", func() -> void: show_screen(daily)],
	])


func _start(date: String, index: int) -> void:
	show_screen(game)
	game.open_challenge(date, index)
