class_name LevelGenerator
extends RefCounted
## Cria os níveis do modo por níveis, sem fim. O mesmo número gera SEMPRE o mesmo nível
## em qualquer aparelho (semente do texto "nivel#N"), para o ranking ser justo.


## Níveis já gerados nesta sessão.
static var _cache: Dictionary = {}


static func key_for(level: int) -> String:
	return "nivel#%d" % level


## Devolve {mode, level, difficulty, tubes, covers, par, full_points, hidden} ou {} se falhar.
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
	var puzzle: Dictionary = {}
	# se nenhum sorteio servir, continua sorteando com a mesma semente (igual em todo aparelho);
	# um nível que nunca gera deixaria o jogador preso nele para sempre
	# a cada duas rodadas sem sucesso, um pano a menos (a última rodada fica sem panos)
	for _try in 6:
		var shape: Dictionary = setup.duplicate()
		shape.covers = maxi(0, int(setup.covers) - _try / 2) if _try < 5 else 0
		puzzle = ChallengeGenerator.build_puzzle(rng, shape, GameStyle.LIQUIDS.size(), true)
		if not puzzle.is_empty():
			break
	if puzzle.is_empty():
		push_error("Não consegui gerar o nível %d" % level)
		return {}
	return {
		"mode": "level", "level": level, "difficulty": Rules.level_difficulty(level),
		"tubes": puzzle.tubes, "covers": puzzle.covers, "par": puzzle.par, "full_points": Rules.full_points_for(puzzle.par), "hidden": setup.hidden,
	}
