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
	Ads.instant = true
	screen = load("res://scenes/game/game_screen.tscn").instantiate()
	screen.animate = false
	add_child(screen)
	screen.open_with(EASY)


func after_each() -> void:
	screen.free()
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
	assert_eq(screen.dialog.title_label.text, "Na Lata!")
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


func test_restart_needs_ad_and_new_attempt() -> void:
	screen.open_challenge("2026-11-07", 0)
	assert_eq(GameState.attempts("2026-11-07#0"), 1)
	screen.get_node("%RestartButton").pressed.emit()
	screen.dialog.press("Assistir e recomeçar")
	assert_eq(GameState.attempts("2026-11-07#0"), 2, "recomeçar gasta uma tentativa")
	assert_eq(screen.puzzle.moves_used(), 0)


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
