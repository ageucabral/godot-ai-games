extends "res://tests/test_case.gd"
## Desafios do dia: iguais para todos, com solução e número exato de movimentos.


func test_same_day_same_challenge() -> void:
	var a := ChallengeGenerator.generate("2026-11-07", 3)
	var b := ChallengeGenerator.generate("2026-11-07", 3)
	assert_eq(a, b, "mesmo dia e número geram o mesmo desafio")
	assert_ne(a.tubes, ChallengeGenerator.generate("2026-11-08", 3).tubes, "outro dia muda")


func test_fixed_seed_value() -> void:
	# Garante que a semente não muda entre versões (o servidor vai usar a mesma conta).
	assert_eq(ChallengeGenerator.seed_for("2026-11-07#0"), ChallengeGenerator.seed_for("2026-11-07#0"))
	assert_eq(ChallengeGenerator.seed_for("a"), 0xE40C292C, "FNV-1a de 'a'")


func test_every_daily_challenge_is_valid() -> void:
	for i in Rules.DAILY_COUNT:
		var c := ChallengeGenerator.generate("2026-11-07", i)
		assert_eq(c.difficulty, Rules.difficulty_for(i), "dificuldade %d" % i)
		assert_eq(c.full_points, Rules.FULL_POINTS[c.difficulty])
		assert_eq(SortPuzzle.min_moves(c.tubes), c.par, "par confere %d" % i)
		assert_true(c.par >= ChallengeGenerator.SETUP[c.difficulty].min_par, "não é fácil demais %d" % i)
		assert_eq(c.hidden, c.difficulty == Rules.HARD, "camadas escondidas só nos difíceis")
		var layers := 0
		for t in c.tubes:
			layers += (t as Array).size()
		assert_eq(layers % SortPuzzle.CAPACITY, 0, "camadas completas %d" % i)
