extends "res://tests/test_case.gd"
## Toques na tela da partida: escolher, despejar, limite de jogadas, propaganda e vitória.

const EASY := {"date": "2026-11-07", "index": 0, "difficulty": "easy", "full_points": 10,
	"par": 3, "hidden": false, "tubes": [[0, 0, 0, 1], [1, 1, 1, 0], []]}

## Com duas garrafas vazias dá para "gastar" jogadas indo e voltando.
const SPARE := {"date": "2026-11-07", "index": 1, "difficulty": "easy", "full_points": 10,
	"par": 3, "hidden": false, "tubes": [[0, 0, 0, 1], [1, 1, 1, 0], [], []]}

var screen: Control


func before_each() -> void:
	GameState.save_path = "user://test_progress_screen.cfg"
	GameState.reset_all()
	GameState.set_setting("tutorial_done", true)  # a partida guiada tem testes próprios
	GameState.fixed_unix = 1794063600  # 7/11/2026 meio-dia em Brasília
	Ads.instant = true
	screen = load("res://scenes/game/game_screen.tscn").instantiate()
	screen.animate = false
	add_child(screen)
	screen.open_with(EASY)


func after_each() -> void:
	screen.free()
	GameState.fixed_unix = -1
	Ads.instant = false


func _solve() -> void:
	for pair in [[0, 2], [1, 0], [2, 1]]:
		screen.tap_bottle(pair[0])
		screen.tap_bottle(pair[1])


func test_tap_selects_then_pours() -> void:
	screen.tap_bottle(0)
	assert_eq(screen.selected, 0, "primeiro toque escolhe")
	screen.tap_bottle(2)
	assert_eq(screen.selected, -1, "segundo toque despeja")
	assert_eq(screen.puzzle.tubes[2], [1])
	assert_eq(screen.get_node("%MovesValue").text, "1 / 3")


func test_empty_bottle_is_not_selected() -> void:
	screen.tap_bottle(2)
	assert_eq(screen.selected, -1)


func test_invalid_pour_keeps_puzzle() -> void:
	screen.tap_bottle(0)  # topo cor 1
	screen.tap_bottle(1)  # topo cor 0: não pode
	assert_eq(screen.puzzle.moves_used(), 0)
	assert_eq(screen.selected, 1, "passa a escolher a garrafa tocada")


func test_win_saves_full_points() -> void:
	_solve()
	assert_true(screen.puzzle.is_solved())
	assert_eq(screen.dialog.title_label.text, "Desafio 1!", "título grande da vitória")
	var card: Control = screen.dialog.inputs()[1]
	assert_eq((card.find_child("Points", true, false) as Label).text, "+10", "pontos em destaque")
	assert_eq(GameState.result("2026-11-07#0").best_points, 10)
	assert_true("Próximo desafio" in screen.dialog.button_texts())


func _waste_three_moves() -> void:
	screen.open_with(SPARE)
	for pair in [[0, 2], [2, 3], [3, 2]]:
		screen.tap_bottle(pair[0])
		screen.tap_bottle(pair[1])


func test_out_of_moves_blocks_until_ad() -> void:
	_waste_three_moves()
	assert_true(screen.out_of_moves())
	assert_eq(screen.dialog.title_label.text, "Acabaram as jogadas")
	screen.dialog.close()
	screen.tap_bottle(1)
	assert_eq(screen.selected, -1, "sem jogadas não dá para continuar")
	screen.dialog.press("+5 jogadas")
	assert_eq(screen.move_limit, 8, "propaganda dá +5")
	assert_false(screen.out_of_moves())


func test_extra_moves_cost_points() -> void:
	_waste_three_moves()
	screen.dialog.press("+5 jogadas")
	for pair in [[1, 0], [2, 1]]:  # resolve com 5 jogadas no total: 2 além do exato
		screen.tap_bottle(pair[0])
		screen.tap_bottle(pair[1])
	assert_true(screen.puzzle.is_solved())
	assert_eq(GameState.result("2026-11-07#1").best_points, 8, "10 - 2")


func test_level_continue_without_points_does_not_nag() -> void:
	var level := SPARE.duplicate(true)
	level.mode = "level"
	level.level = 1
	level.full_points = 2  # poucos pontos, para zerar rápido
	screen.open_with(level)
	for pair in [[0, 2], [2, 3], [3, 2]]:
		screen.tap_bottle(pair[0])
		screen.tap_bottle(pair[1])
	screen.dialog.press("+5 jogadas")
	for pair in [[2, 3], [3, 2]]:
		screen.tap_bottle(pair[0])
		screen.tap_bottle(pair[1])
	assert_eq(screen.dialog.title_label.text, "Pontuação zerada")
	screen.dialog.press("Continuar sem pontos")
	screen.tap_bottle(2)
	screen.tap_bottle(3)
	assert_false(screen.dialog.visible, "não repete o aviso a cada jogada")
	for pair in [[1, 0], [3, 1]]:
		screen.tap_bottle(pair[0])
		screen.tap_bottle(pair[1])
	assert_true(screen.puzzle.is_solved())
	assert_eq(GameState.current_level(), 2, "terminou sem pontos e seguiu")


func test_restart_needs_ad_and_new_attempt() -> void:
	screen.open_challenge("2026-11-07", 0)
	assert_eq(GameState.attempts("2026-11-07#0"), 1)
	screen.get_node("%RestartButton").pressed.emit()
	screen.dialog.press("Recomeçar")
	assert_eq(GameState.attempts("2026-11-07#0"), 2, "recomeçar gasta uma tentativa")
	assert_eq(screen.puzzle.moves_used(), 0)


func test_restart_after_midnight_is_closed() -> void:
	screen.open_challenge("2026-11-07", 0)
	GameState.fixed_unix += 86400  # virou o dia com a partida aberta
	screen.get_node("%RestartButton").pressed.emit()
	screen.dialog.press("Recomeçar")
	assert_eq(screen.dialog.title_label.text, "Desafio encerrado")
	assert_eq(GameState.attempts("2026-11-07#0"), 1, "não gasta tentativa de dia encerrado")


func test_open_challenge_from_past_day_is_refused() -> void:
	screen.open_challenge("2026-11-06", 0)
	assert_eq(GameState.attempts("2026-11-06#0"), 0)
	assert_true(screen.dialog.visible, "avisa que acabou")


func test_flow_segments_halfway() -> void:
	var segs: Array = screen.flow_segments([[0, 1.0, false], [1, 1.0, false]], [], 1, 1, 0.5)
	assert_eq(segs[0], [[0, 1.0, false], [1, 0.5, false]], "origem pela metade")
	assert_eq(segs[1], [[1, 0.5, false]], "destino recebendo")


func test_pour_animation_finishes() -> void:
	screen.animate = true
	screen.tap_bottle(0)
	screen.tap_bottle(2)
	assert_true(screen.busy, "animando")
	await get_tree().create_timer(1.2).timeout
	assert_false(screen.busy, "terminou")
	assert_eq(screen.get_node("%MovesValue").text, "1 / 3")


func test_next_skips_solved_challenges() -> void:
	GameState.save_result("2026-11-07#1", 10, 5)
	GameState.save_result("2026-11-07#2", 10, 5)
	assert_eq(screen.next_unsolved_after("2026-11-07", 0), 3, "pula os já resolvidos")
	for i in Rules.DAILY_COUNT:
		GameState.save_result("2026-11-07#%d" % i, 1, 5)
	assert_eq(screen.next_unsolved_after("2026-11-07", 0), -1, "todos resolvidos")


func test_touch_plus_emulated_click_selects_once() -> void:
	# No Android um toque gera InputEventScreenTouch e também um clique emulado.
	var bottle: BottleView = screen.get_node("%RowTop").get_child(0)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	bottle._gui_input(touch)
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	bottle._gui_input(click)
	assert_eq(screen.selected, 0, "garrafa escolhida (não foi solta logo em seguida)")


func test_win_title_names_the_stage() -> void:
	screen.challenge = {"mode": "level", "level": 23}
	assert_eq(screen.win_title(), "Nível 23!")
	screen.challenge = {"mode": "daily", "index": 3}
	assert_eq(screen.win_title(), "Desafio 4!")
	screen.challenge = {"mode": "event", "event_n": 7}
	assert_eq(screen.win_title(), "Fase 7!")
	screen.challenge = {"mode": "duel"}
	assert_eq(screen.win_title(), "Duelo!")


func test_covered_bottle_cannot_be_used_until_color_done() -> void:
	# garrafa 3 coberta, abre quando a cor 1 ficar completa
	var data := {"date": "2026-11-07", "index": 0, "difficulty": "medium", "full_points": 6,
		"par": 3, "hidden": false, "tubes": [[0, 0, 0, 1], [1, 1, 1, 0], [], [2, 2, 2, 2]], "covers": [-1, -1, -1, 1]}
	screen.open_with(data)
	screen.tap_bottle(3)
	assert_eq(screen.selected, -1, "coberta não pode ser escolhida")
	screen.tap_bottle(0)
	screen.tap_bottle(3)
	assert_eq(screen.puzzle.tubes[3], [2, 2, 2, 2], "coberta não recebe líquido")
	assert_true(screen.puzzle.is_covered(3))
	for pair in [[0, 2], [1, 0], [2, 1]]:
		screen.tap_bottle(pair[0])
		screen.tap_bottle(pair[1])
	assert_false(screen.puzzle.is_covered(3), "completar a cor 1 tira o pano")


func test_points_drop_live_after_par() -> void:
	_waste_three_moves()
	screen.dialog.press("+5 jogadas")
	assert_eq(screen._points_value.text, "10")
	screen.tap_bottle(2)
	screen.tap_bottle(3)
	assert_eq(screen._points_value.text, "9", "cada jogada a mais tira 1 na hora")


func test_points_show_in_one_place() -> void:
	screen.open_with(EASY)
	assert_eq(screen._points_value.text, "10", "o placar mostra quanto a fase vale")
	assert_eq(screen._subtitle.text, "Fácil", "o subtítulo não repete os pontos")


func test_extra_bottle_costs_one_point() -> void:
	screen.open_with(EASY)
	screen.get_node("%BottleButton").pressed.emit()
	assert_true(screen.dialog.visible, "pede confirmação")
	screen.dialog.press("+1 frasco")
	assert_eq(screen.puzzle.tubes.size(), 4, "ganhou uma garrafa vazia")
	assert_eq(screen._points_value.text, "9", "custa 1 ponto")
	assert_eq(screen.bottles_left, 0)
	assert_true(screen.get_node("%BottleButton").disabled, "só um por fase")


func test_shuffle_costs_one_point_and_keeps_colors() -> void:
	var data := SPARE.duplicate(true)
	data.tubes = [[0, 1, 0, 1], [1, 0, 1, 0], [], []]
	screen.open_with(data)
	var before: Array = []
	for t in screen.puzzle.tubes:
		before.append_array(t)
	before.sort()
	screen.get_node("%ShuffleButton").pressed.emit()
	screen.dialog.press("Embaralhar")
	var after: Array = []
	for t in screen.puzzle.tubes:
		after.append_array(t)
	after.sort()
	assert_eq(after, before, "as mesmas camadas, só misturadas")
	assert_eq(screen.shuffles_left, Rules.SHUFFLES_PER_STAGE - 1)
	assert_eq(screen._points_value.text, "9", "custa 1 ponto")
	assert_true(SortPuzzle.min_moves(screen.puzzle.tubes) >= 0, "continua com solução")


func test_boost_blocked_when_it_would_zero_a_daily() -> void:
	var data := EASY.duplicate(true)
	data.full_points = 1
	screen.open_with(data)
	assert_true(screen.get_node("%BottleButton").disabled, "ajuda zeraria o desafio: fica desligada")
	screen.get_node("%BottleButton").pressed.emit()
	assert_false(screen.dialog.visible, "nem pergunta")


func test_levels_hide_difficulty() -> void:
	var level := SPARE.duplicate(true)
	level.mode = "level"
	level.level = 3
	screen.open_with(level)
	assert_false(screen._subtitle.visible, "nível não mostra Fácil/Médio")
	screen.open_with(EASY)
	assert_true(screen._subtitle.visible, "desafio mostra a dificuldade")


func test_boost_dialog_shows_real_cost() -> void:
	screen.open_with(EASY)
	screen.get_node("%BottleButton").pressed.emit()
	assert_true(screen.dialog.text_label.text.ends_with("custa 1 ponto."), "custo padrão")
	screen.dialog.press("Voltar")
	var data := SPARE.duplicate(true)
	data["params"] = {"boost_cost": 2}
	screen.open_with(data)
	screen.get_node("%ShuffleButton").pressed.emit()
	assert_true(screen.dialog.text_label.text.ends_with("custa 2 pontos."), "custo das regras da partida")
