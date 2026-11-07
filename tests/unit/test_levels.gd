extends "res://tests/test_case.gd"
## Modo por níveis: sem fim, mesmo nível para todos, dificuldade crescente e pontos fixos.


func before_each() -> void:
	GameState.save_path = "user://test_progress_levels.cfg"
	GameState.reset_all()
	GameState.fixed_unix = 1794063600  # 7/11/2026 meio-dia em Brasília


func after_each() -> void:
	GameState.fixed_unix = -1


func test_same_level_same_puzzle() -> void:
	var a := LevelGenerator.generate(5)
	LevelGenerator._cache.clear()
	var b := LevelGenerator.generate(5)
	assert_eq(a.tubes, b.tubes, "nível igual para todos")
	assert_eq(a.par, b.par)
	assert_eq(a.full_points, Rules.full_points_for(a.par), "vale o dobro das jogadas")
	assert_eq(a.mode, "level")


func test_difficulty_grows() -> void:
	var last_colors := 0
	var last_par := 0
	for level in [1, 3, 9, 20, 30, 40, 100, 1000]:
		var s := Rules.level_setup(level)
		assert_true(s.colors >= last_colors, "cores não diminuem no nível %d" % level)
		assert_true(s.min_par >= last_par, "jogadas mínimas não diminuem no nível %d" % level)
		last_colors = s.colors
		last_par = s.min_par
	assert_false(Rules.level_setup(29).hidden)
	assert_true(Rules.level_setup(30).hidden, "camadas escondidas a partir do 30")
	assert_true(Rules.level_setup(1000).colors <= GameStyle.LIQUIDS.size(), "não passa das cores que existem")


func test_levels_are_solvable() -> void:
	for level in [1, 2, 9, 12, 16, 20]:
		var data := LevelGenerator.generate(level)
		assert_false(data.is_empty(), "gerou o nível %d" % level)
		var s := Rules.level_setup(level)
		assert_eq(data.tubes.size(), s.colors + s.repeats + s.empty)
		assert_eq(SortPuzzle.min_moves(data.tubes, 400000, data.covers), data.par, "par confere no nível %d" % level)
		assert_true(data.par > 0, "nível %d tem solução" % level)


func test_complete_level_counts_once() -> void:
	assert_eq(GameState.current_level(), 1)
	GameState.complete_level(1, 2, 7)
	GameState.complete_level(1, 2, 7)
	assert_eq(GameState.current_level(), 2, "só avança uma vez")
	var total := GameState.month_total("2026-11")
	assert_eq(total.points, 2)
	assert_eq(total.levels, 1)
	assert_eq(total.moves, 7)
	assert_eq(GameState.month_total("2026-12").points, 0, "conta no mês em que foi resolvido")


func test_daily_puzzles_unchanged_by_new_color() -> void:
	# as cores dos desafios do dia ficam entre as 6 primeiras
	for i in Rules.DAILY_COUNT:
		for tube in ChallengeGenerator.generate("2026-11-07", i).tubes:
			for c in tube:
				assert_true(c < GameStyle.DAILY_LIQUIDS)


func test_month_countdown() -> void:
	assert_eq(Rules.short_countdown(90000), "1d 01h")
	assert_eq(Rules.short_countdown(3725), "01:02:05")
	# 30/11/2026 meio-dia em Brasília: faltam 12 h
	assert_eq(Rules.seconds_to_month_end(1794063600 + 23 * 86400), 12 * 3600)


func test_mascot_floats_and_hops() -> void:
	assert_eq(MascotView.float_offset(0.0, 0.0), 0.0)
	assert_true(MascotView.float_offset(0.0, 1.0) < -40.0, "pulinho sobe")


func test_new_kinds_of_play_appear_gradually() -> void:
	assert_eq(Rules.level_setup(9).covers, 0, "sem pano no começo")
	assert_eq(Rules.level_setup(10).covers, 1, "o pano aparece no nível 10")
	assert_eq(Rules.level_setup(14).repeats, 0)
	assert_eq(Rules.level_setup(15).repeats, 1, "a cor repetida aparece no nível 15")
	var last_covers := 0
	for level in range(1, 200):
		var s := Rules.level_setup(level)
		assert_true(s.covers >= last_covers, "panos não diminuem no nível %d" % level)
		last_covers = s.covers


func test_covered_levels_have_covers() -> void:
	var data := LevelGenerator.generate(12)
	var covered := 0
	for c in data.covers:
		if int(c) >= 0:
			covered += 1
	assert_eq(covered, 1, "nível 12 tem um frasco coberto")
