class_name LevelGenerator
extends RefCounted
## Cria os níveis do modo por níveis, sem fim. O mesmo número gera SEMPRE o mesmo nível
## em qualquer aparelho (semente do texto "nivel#N"), para o ranking ser justo.


## Níveis já gerados nesta sessão.
static var _cache: Dictionary = {}


static func key_for(level: int) -> String:
	return "nivel#%d" % level


## Devolve {mode, level, difficulty, tubes, par, full_points, hidden} ou {} se falhar.
static func generate(level: int) -> Dictionary:
	if level < 1:
		return {}
	if not _cache.has(level):
		_cache[level] = _generate(level)
	return (_cache[level] as Dictionary).duplicate(true)


static func _generate(level: int) -> Dictionary:
	var setup := Rules.level_setup(level)
	var rng := RandomNumberGenerator.new()
	rng.seed = ChallengeGenerator.seed_for(key_for(level))
	var puzzle := ChallengeGenerator.build_puzzle(rng, setup.colors, setup.empty, setup.min_par,
		TropicalStyle.LIQUIDS.size(), true)
	if puzzle.is_empty():
		push_error("Não consegui gerar o nível %d" % level)
		return {}
	return {
		"mode": "level", "level": level, "difficulty": Rules.level_difficulty(level),
		"tubes": puzzle.tubes, "par": puzzle.par, "full_points": Rules.LEVEL_POINTS, "hidden": setup.hidden,
	}
