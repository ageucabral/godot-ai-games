class_name ChallengeGenerator
extends RefCounted
## Cria os desafios do dia. O mesmo dia e número geram SEMPRE o mesmo desafio,
## em qualquer aparelho, para que todos joguem igual. (Depois o servidor fará isso.)

## Quantas cores e garrafas vazias cada dificuldade usa.
const SETUP := {
	Rules.EASY: {"colors": [3, 4], "empty": 2, "min_par": 5, "hidden": false},
	Rules.MEDIUM: {"colors": [5], "empty": 2, "min_par": 10, "hidden": false},
	Rules.HARD: {"colors": [6], "empty": 2, "min_par": 14, "hidden": true},
}


## Desafios já gerados nesta sessão (gerar um difícil leva um instante).
static var _cache: Dictionary = {}


static func key_for(date: String, index: int) -> String:
	return "%s#%d" % [date, index]


## Semente estável (FNV-1a de 32 bits) a partir do texto do dia + número do desafio.
static func seed_for(text: String) -> int:
	var h: int = 2166136261
	for b in text.to_utf8_buffer():
		h = ((h ^ b) * 16777619) & 0xFFFFFFFF
	return h


## Devolve {tubes, par, difficulty, full_points, hidden, date, index}.
static func generate(date: String, index: int) -> Dictionary:
	var key := key_for(date, index)
	if not _cache.has(key):
		_cache[key] = _generate(date, index)
	return (_cache[key] as Dictionary).duplicate(true)


static func _generate(date: String, index: int) -> Dictionary:
	var difficulty := Rules.difficulty_for(index)
	var setup: Dictionary = SETUP[difficulty]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_for(key_for(date, index))
	var color_options: Array = setup.colors
	var n_colors: int = color_options[index % color_options.size()]
	for attempt in 50:
		var palette := _pick_colors(rng, n_colors)
		var tubes := _shuffled_tubes(rng, palette, setup.empty)
		if _has_finished_tube(tubes):
			continue
		var par := SortPuzzle.min_moves(tubes)
		if par < setup.min_par:
			continue
		return {
			"date": date, "index": index, "difficulty": difficulty, "tubes": tubes, "par": par,
			"full_points": Rules.FULL_POINTS[difficulty], "hidden": setup.hidden,
		}
	push_error("Não consegui gerar o desafio %s" % key_for(date, index))
	return {}


static func _pick_colors(rng: RandomNumberGenerator, count: int) -> Array:
	var all: Array = range(TropicalStyle.LIQUIDS.size())
	_shuffle(rng, all)
	return all.slice(0, count)


static func _shuffled_tubes(rng: RandomNumberGenerator, palette: Array, empty: int) -> Array:
	var pool: Array = []
	for c in palette:
		for i in SortPuzzle.CAPACITY:
			pool.append(c)
	_shuffle(rng, pool)
	var tubes: Array = []
	for i in palette.size():
		tubes.append(pool.slice(i * SortPuzzle.CAPACITY, (i + 1) * SortPuzzle.CAPACITY))
	for i in empty:
		tubes.append([])
	return tubes


static func _has_finished_tube(tubes: Array) -> bool:
	for t in tubes:
		if (t as Array).size() == SortPuzzle.CAPACITY and SortPuzzle.top_run(t) == SortPuzzle.CAPACITY:
			return true
	return false


## Embaralha com a semente (Fisher-Yates), sem depender do embaralhador do motor.
static func _shuffle(rng: RandomNumberGenerator, arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
