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


func test_daily_without_improving_still_counts_for_streak() -> void:
	var key := ChallengeGenerator.key_for(GameState.today(), 0)
	assert_true(GameState.save_result(key, 10, 5))
	GameState.fixed_unix += 86400
	assert_false(GameState.save_result(key, 8, 6), "pior que o melhor")
	assert_eq(int(GameState.streak().count), 2, "resolveu no dia seguinte: a sequência sobe mesmo sem melhorar")


func test_duel_code_from_links() -> void:
	assert_eq(ApiClient.duel_code_from("nalata://duelo/ab12cd"), "AB12CD")
	assert_eq(ApiClient.duel_code_from("https://nalatagame.tech/duelo/AB12CD?x=1"), "AB12CD")
	assert_eq(ApiClient.duel_code_from("utm_source=x&duel=AB12CD"), "AB12CD")
	assert_eq(ApiClient.duel_code_from("duel%3DAB12CD"), "AB12CD")
	assert_eq(ApiClient.duel_code_from("code=XYZ999"), "")
	assert_eq(ApiClient.duel_code_from(""), "")


func test_reminder_time_once_a_day() -> void:
	var noon := 1794063600  # 12h em Brasília
	var seven_pm := noon + 7 * 3600
	assert_eq(Reminders.next_time(noon, false), seven_pm, "hoje às 19h")
	assert_eq(Reminders.next_time(noon, true), seven_pm + 86400, "já jogou: amanhã")
	assert_eq(Reminders.next_time(seven_pm + 60, false), seven_pm + 86400, "passou das 19h: amanhã")
	assert_true(Reminders.message(5)[1].contains("5 dias"), "sequência em risco")
	assert_true(Reminders.message(0)[1].begins_with("Os 20 desafios de hoje chegaram"))
	assert_true(Reminders.message(0, 0, null, false, false)[1].begins_with("Seu próximo nível"), "desafios trancados: fala do nível")
	var last_day := Rules.unix_from_iso("2026-11-30T15:00:00")
	assert_true(Reminders.message(5, last_day, 37)[1].contains("37º"), "ranking fechando: avisa o lugar")
	assert_true(Reminders.message(5, last_day, 37)[1].begins_with("Falta 1 dia"), "último dia: no singular")
	assert_true(Reminders.message(5, last_day - 86400, 37)[1].begins_with("Faltam 2 dias"))
	assert_true(Reminders.message(5, last_day - 10 * 86400, 37)[1].contains("sequência"), "longe do fim do mês: a sequência")
	assert_true(Reminders.message(5, last_day, 37, true)[1].contains("prêmio"), "prêmio vem primeiro")


func test_every_skin_has_a_shape_with_liquid() -> void:
	for skin: String in GameStyle.SKIN_EDGES:
		assert_true(GameStyle.bottle_outline(skin).size() > 6, skin)
		assert_false(GameStyle.band_polygons(GameStyle.LIQUID_TOP, GameStyle.LIQUID_BOTTOM, skin).is_empty(), skin + ": cabe líquido")
	for id: String in Extras.SKINS:
		assert_true(GameStyle.SKIN_EDGES.has(id), id)
	for id: String in Extras.BACKGROUNDS:
		assert_true(SceneBackground.ART.has(Extras.background_kind(id)), id)


func test_achievement_names_cover_the_server() -> void:
	assert_eq(Extras.ACHIEVEMENTS.size(), 24, "as 24 conquistas da proposta")
	assert_eq(Extras.achievement_name("duel_1"), "Primeiro duelo")
	assert_eq(Extras.achievement_icon("exact_10"), "🎯")
	assert_eq(Extras.league_name(9), "Liga Diamante")
	assert_eq(Extras.league_name(3), "Liga Rubi")
	var lines := Extras.win_lines({"streak": 3, "freeBoostsGained": 1, "gifts": ["streak"], "achievements": ["first_win"], "duel": {"won": true, "rivalMoves": 9}, "eventReward": "frame"})
	assert_eq(lines.size(), 4)
	assert_eq(lines[0], "⚔️ Você venceu o duelo!")
	assert_eq(lines[1], "🏅 Nova conquista: Primeira poção")
	assert_eq(lines[3], "👑 Prêmio do evento: uma moldura nova!")


func test_streak_week_strip() -> void:
	var monday_noon := Rules.unix_from_iso("2026-11-09T15:00:00")  # segunda, meio-dia em Brasília
	var days := Extras.streak_days(4, false, monday_noon)  # jogou 4 dias até ontem; hoje seria o 5º
	assert_eq(days.size(), 7)
	assert_eq(days.map(func(d: Array) -> String: return d[0]), ["Qui", "Sex", "Sáb", "Dom", "Hoje", "Ter", "Qua"])
	assert_eq(days.map(func(d: Array) -> bool: return d[1]), [true, true, true, true, false, false, false])
	assert_eq(days[4][2], "🎁", "dia 5: ajuda grátis")
	assert_eq(days[6][2], "👑", "dia 7: moldura")
	assert_eq(Extras.streak_days(7, true, monday_noon)[6][1], true, "7º dia feito hoje")
	assert_eq(Extras.streak_days(7, true, monday_noon)[6][0], "Hoje")
	assert_eq(Extras.streak_days(0, false, monday_noon)[0][0], "Hoje", "sem sequência: começa hoje")
	assert_eq(Extras.next_streak_rewards(4, false), ["🎁 dia 5: 1 ajuda grátis", "👑 dia 7: moldura"])
	assert_eq(Extras.next_streak_rewards(7, true), ["🧪 dia 30: frasco Coração"])


func test_pieces_explained_in_match() -> void:
	var game_screen: GDScript = load("res://scripts/game/game_screen.gd")
	assert_eq(game_screen.pieces_lines([0, 3, 0], [-1, -1, -1]), ["🧊 Frasco de gelo: derrete depois de 3 jogadas."])
	assert_eq(game_screen.pieces_lines([0, 0], [-1, 1]), ["🔵 Frasco de uma cor: só aceita azul."])
	assert_eq(game_screen.pieces_lines([0, 0], [-1, -1]), [])


func test_event_card_done_is_not_playable() -> void:
	var card := EventCard.new()
	card.set_event({"name": "Natal", "theme": "natal", "endsAt": "2026-11-20T03:00:00Z", "levels": 15, "done": 3, "rewards": []})
	assert_false(card.disabled, "com fases a fazer: toca para jogar")
	card.set_event({"name": "Natal", "theme": "natal", "endsAt": "2026-11-20T03:00:00Z", "levels": 15, "done": 15, "rewards": []})
	assert_true(card.disabled, "evento completo: o servidor recusaria a próxima fase")
	assert_eq(card._count.text, "Evento completo!")
	card.free()


func test_full_bottle_sparks_fly_out() -> void:
	var start: Array = BottleView.done_spark(0, 7, 0.0)
	var end: Array = BottleView.done_spark(0, 7, 1.0)
	assert_true((end[0] as Vector2).y < (start[0] as Vector2).y, "a primeira sobe")
	assert_true((end[0] as Vector2).distance_to(BottleView.SPARK_CENTER) > 60.0, "sai para longe do meio do frasco")
	assert_true(float(end[1]) < float(start[1]), "e diminui")
	var bottle := BottleView.new()
	bottle.celebrate(1)
	assert_eq(bottle._done_color, GameStyle.liquid_color(1), "brilha na cor do líquido")
	bottle.free()


func test_vibration_follows_its_switch() -> void:
	Sfx.vibrated.clear()
	Sfx.play("pour")
	assert_eq(Sfx.vibrated, [], "fora do celular não vibra")
	Sfx.vibrate_override = true
	Sfx.play("pour")
	Sfx.play("click")
	assert_eq(Sfx.vibrated, ["pour"], "vibra ao despejar, não nos botões")
	Sfx.set_vibration_enabled(false)
	Sfx.play("tap")
	assert_eq(Sfx.vibrated, ["pour"], "desligada na engrenagem")
	Sfx.set_vibration_enabled(true)
	Sfx.vibrate_override = null
