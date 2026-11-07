extends "res://tests/test_case.gd"
## Pontos, mistura de dificuldades e datas em Brasília.

# 2026-11-07 15:00 UTC = 12:00 em Brasília
const NOON_BRT := 1794063600


func test_score_for() -> void:
	assert_eq(Rules.score_for(50, 18, 18), 50, "no número exato")
	assert_eq(Rules.score_for(50, 18, 21), 47, "exemplo do documento")
	assert_eq(Rules.score_for(50, 18, 15), 50, "nunca passa da cheia")
	assert_eq(Rules.score_for(10, 8, 30), 0, "nunca negativo")


func test_daily_mix() -> void:
	var counts := {Rules.EASY: 0, Rules.MEDIUM: 0, Rules.HARD: 0}
	for i in Rules.DAILY_COUNT:
		counts[Rules.difficulty_for(i)] += 1
	assert_eq(Rules.DAILY_COUNT, 20)
	assert_eq(counts, {Rules.EASY: 8, Rules.MEDIUM: 7, Rules.HARD: 5})


func test_full_points_table() -> void:
	assert_eq(Rules.FULL_POINTS, {Rules.EASY: 10, Rules.MEDIUM: 25, Rules.HARD: 50})


func test_brasilia_date() -> void:
	assert_eq(Rules.date_for(NOON_BRT), "2026-11-07")
	# 02:00 UTC do dia 8 ainda é dia 7 em Brasília (23:00)
	assert_eq(Rules.date_for(NOON_BRT + 11 * 3600), "2026-11-07")
	assert_eq(Rules.date_for(NOON_BRT + 12 * 3600), "2026-11-08", "meia-noite em Brasília")
	assert_eq(Rules.seconds_to_next_day(NOON_BRT), 12 * 3600)


func test_month() -> void:
	assert_eq(Rules.month_for(NOON_BRT), "2026-11")
	assert_eq(Rules.days_left_in_month(NOON_BRT), 24)
	assert_eq(Rules.pretty_date("2026-11-07"), "7 de novembro")
