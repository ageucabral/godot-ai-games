extends "res://tests/test_case.gd"
## Ideias novas (9/11/2026): estrelas, sequência de dias, link do duelo, avisos e frascos.


func before_each() -> void:
	GameState.save_path = "user://test_progress_extras.cfg"
	GameState.reset_all()
	GameState.fixed_unix = 1794063600  # 7/11/2026 meio-dia em Brasília


func after_each() -> void:
	GameState.fixed_unix = -1


func test_stars() -> void:
	assert_eq(Rules.stars_for(11, 11), 3)
	assert_eq(Rules.stars_for(14, 11), 2)
	assert_eq(Rules.stars_for(15, 11), 1)


func test_streak_rules() -> void:
	assert_eq(Rules.add_days("2026-12-31", 1), "2027-01-01")
	assert_eq(Rules.next_streak("", 0, "2026-11-07"), 1)
	assert_eq(Rules.next_streak("2026-11-07", 3, "2026-11-07"), 3, "mesmo dia não muda")
	assert_eq(Rules.next_streak("2026-11-06", 3, "2026-11-07"), 4)
	assert_eq(Rules.next_streak("2026-11-05", 3, "2026-11-07"), 1, "pulou um dia")
	assert_eq(Rules.live_streak("2026-11-06", 3, "2026-11-07"), 3)
	assert_eq(Rules.live_streak("2026-11-05", 3, "2026-11-07"), 0)


func test_local_streak_and_level_stars() -> void:
	assert_eq(int(GameState.streak().count), 0)
	GameState.complete_level(1, 6, 3, 3)
	assert_eq(GameState.level_stars(1), 3)
	var s := GameState.streak()
	assert_eq(int(s.count), 1)
	assert_true(bool(s.played_today))
	GameState.fixed_unix += 86400
	GameState.complete_level(2, 4, 6, 3)
	assert_eq(GameState.level_stars(2), 2)
	assert_eq(int(GameState.streak().count), 2)
	GameState.fixed_unix += 3 * 86400
	assert_eq(int(GameState.streak().count), 0, "parou de jogar")
	assert_eq(int(GameState.streak().best), 2)


func test_duel_code_from_links() -> void:
	assert_eq(Extras.duel_code_from("nalata://duelo/ab12cd"), "AB12CD")
	assert_eq(Extras.duel_code_from("https://nalatagame.tech/duelo/AB12CD?x=1"), "AB12CD")
	assert_eq(Extras.duel_code_from("utm_source=x&duel=AB12CD"), "AB12CD")
	assert_eq(Extras.duel_code_from("duel%3DAB12CD"), "AB12CD")
	assert_eq(Extras.duel_code_from("code=XYZ999"), "")
	assert_eq(Extras.duel_code_from(""), "")


func test_reminder_time_once_a_day() -> void:
	var noon := 1794063600  # 12h em Brasília
	var seven_pm := noon + 7 * 3600
	assert_eq(Reminders.next_time(noon, false), seven_pm, "hoje às 19h")
	assert_eq(Reminders.next_time(noon, true), seven_pm + 86400, "já jogou: amanhã")
	assert_eq(Reminders.next_time(seven_pm + 60, false), seven_pm + 86400, "passou das 19h: amanhã")
	assert_true(Reminders.message(5)[0].contains("5"))
	assert_eq(Reminders.message(0)[0], "Desafios novos no ar")


func test_every_skin_has_a_shape_with_liquid() -> void:
	for skin: String in GameStyle.SKIN_EDGES:
		assert_true(GameStyle.bottle_outline(skin).size() > 6, skin)
		assert_false(GameStyle.band_polygons(GameStyle.LIQUID_TOP, GameStyle.LIQUID_BOTTOM, skin).is_empty(), skin + ": cabe líquido")
	for id: String in Extras.SKINS:
		assert_true(GameStyle.SKIN_EDGES.has(id), id)
	for id: String in Extras.BACKGROUNDS:
		assert_true(SceneBackground.ART.has(Extras.background_kind(id)), id)


func test_achievement_names_cover_the_server() -> void:
	assert_eq(Extras.ACHIEVEMENTS.size(), 16)
	assert_eq(Extras.achievement_name("duel_1"), "Primeiro duelo")
	assert_eq(Extras.league_name(9), "Liga Diamante")
	var lines := Extras.win_lines({"streak": 3, "freeBoostsGained": 1, "achievements": ["first_win"], "duel": {"won": true, "rivalMoves": 9}})
	assert_eq(lines.size(), 3)
	assert_eq(lines[0], "Você venceu o duelo!")
