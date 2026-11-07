extends Control
## Cena principal: troca entre o menu, a partida e o ranking.

@onready var home: Control = $Home
@onready var game: Control = $Game
@onready var ranking: Control = $Ranking

var dialog: DialogBox


func _ready() -> void:
	theme = TropicalStyle.build_theme()
	dialog = DialogBox.new()
	add_child(dialog)
	home.play_requested.connect(request_play)
	home.ranking_requested.connect(func() -> void: show_screen(ranking))
	game.back_requested.connect(func() -> void: show_screen(home))
	game.next_requested.connect(request_play)
	ranking.back_requested.connect(func() -> void: show_screen(home))
	show_screen(home)


func show_screen(screen: Control) -> void:
	for s in [home, game, ranking]:
		s.visible = (s == screen)
	if screen.has_method("refresh"):
		screen.refresh()


## Abre um desafio. A primeira tentativa é grátis; as próximas pedem propaganda.
func request_play(date: String, index: int) -> void:
	var key := ChallengeGenerator.key_for(date, index)
	if GameState.attempts(key) == 0:
		_start(date, index)
		return
	var r := GameState.result(key)
	var text := "Você já tentou este desafio."
	if r.completed:
		text = "Seu melhor aqui: %d pontos em %d jogadas." % [r.best_points, r.best_moves]
	dialog.open("Desafio %d" % (index + 1), text + "\nUma nova tentativa pede uma propaganda.", [
		["Assistir e jogar", func() -> void: Ads.show_rewarded(func() -> void: _start(date, index)), true],
		["Voltar", func() -> void: pass],
	])


func _start(date: String, index: int) -> void:
	show_screen(game)
	game.open_challenge(date, index)
