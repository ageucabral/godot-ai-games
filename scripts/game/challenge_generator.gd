class_name ChallengeGenerator
extends RefCounted
## Cria os desafios do dia. O mesmo dia e número geram SEMPRE o mesmo desafio,
## em qualquer aparelho, para que todos joguem igual. Jogando pelo servidor (Android), as fases
## vêm de lá; este gerador vale na Web e nos testes.

## Como cada dificuldade é montada: cores, cores repetidas (duas garrafas da mesma cor),
## garrafas vazias, garrafas cobertas (abrem ao completar uma cor), jogadas mínimas e camadas "?".
const SETUP := {
	Rules.EASY: {"colors": [3, 4], "repeats": 0, "empty": 2, "covers": 0, "min_par": 5, "hidden": false},
	Rules.MEDIUM: {"colors": [5], "repeats": 0, "empty": 2, "covers": 1, "min_par": 9, "hidden": false},
	Rules.HARD: {"colors": [6], "repeats": 0, "empty": 2, "covers": 2, "min_par": 12, "hidden": true},
}


## Limite da busca do número exato de jogadas ao gerar (mantém a geração rápida, inclusive na Web).
const MAX_STATES: int = 150000

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


## Devolve {mode, date, index, difficulty, tubes, covers, par, full_points, hidden}.
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
	var shape: Dictionary = setup.duplicate()
	shape.colors = color_options[index % color_options.size()]
	var puzzle := build_puzzle(rng, shape, GameStyle.DAILY_LIQUIDS, false)
	if puzzle.is_empty():
		push_error("Não consegui gerar o desafio %s" % key_for(date, index))
		return {}
	return {
		"mode": "daily", "date": date, "index": index, "difficulty": difficulty, "tubes": puzzle.tubes,
		"covers": puzzle.covers,
		"par": puzzle.par, "full_points": Rules.full_points_for(puzzle.par), "hidden": setup.hidden,
	}


## Sorteia garrafas até achar uma com pelo menos `min_par` jogadas. Devolve {tubes, covers, par} ou {}.
## `shape` = {colors, repeats, empty, covers, min_par} (repeats e covers podem faltar = 0).
## Com `accept_best` (níveis), tenta no máximo 8 vezes (cada cálculo das 7 cores leva quase 1 s)
## e, se nenhuma chegar lá, fica com a mais longa que tiver solução.
static func build_puzzle(rng: RandomNumberGenerator, shape: Dictionary, palette_size: int, accept_best: bool) -> Dictionary:
	var best: Dictionary = {}
	for attempt in (8 if accept_best else 50):
		var palette := _pick_colors(rng, shape.colors, palette_size)
		for r in int(shape.get("repeats", 0)):
			palette.append(palette[r % palette.size()])  # mesma cor em duas garrafas (8 camadas)
		var tubes := _shuffled_tubes(rng, palette, shape.empty)
		if _has_finished_tube(tubes):
			continue
		var covers := _pick_covers(rng, tubes, palette, int(shape.get("covers", 0)))
		if _has_finished_tube(tubes):
			continue  # as trocas do pano podem ter montado uma garrafa pronta
		var ice := _pick_ice(rng, tubes, covers, int(shape.get("ice", 0)))
		var only := _pick_only(rng, tubes, palette, int(shape.get("only", 0)))
		var par := SortPuzzle.min_moves(tubes, MAX_STATES, covers, ice, only)
		if par >= shape.min_par:
			return _built(tubes, covers, par, ice, only)
		if par > 0 and par > int(best.get("par", 0)):
			best = _built(tubes, covers, par, ice, only)
	return best if accept_best else {}


## Escolhe quais garrafas cheias ficam cobertas e qual cor abre cada uma (cores diferentes).
## A cor que abre não pode ter camada debaixo de um pano (senão nunca daria para completá-la):
## as camadas dela que caíram numa garrafa coberta trocam de lugar com camadas de garrafas abertas.
## Mexe em `tubes`. Devolve a lista de panos (uma entrada por garrafa).
static func _pick_covers(rng: RandomNumberGenerator, tubes: Array, palette: Array, count: int) -> Array:
	var covers: Array = _no_covers(tubes.size())
	if count <= 0:
		return covers
	var filled: Array = []
	for i in tubes.size():
		if not (tubes[i] as Array).is_empty():
			filled.append(i)
	_shuffle(rng, filled)
	var distinct: Array = []
	for c in palette:
		if not distinct.has(c):
			distinct.append(c)
	_shuffle(rng, distinct)
	# sobra pelo menos uma cor sem pano e garrafas abertas suficientes para guardar as cores-chave
	var n := mini(count, mini(filled.size() - 2, distinct.size() - 1))
	if n <= 0:
		return covers
	var chosen: Array = filled.slice(0, n)
	var open_filled: Array = filled.slice(n)
	var keys: Array = distinct.slice(0, n)
	for ci in chosen:
		var tube: Array = tubes[ci]
		for li in tube.size():
			if not keys.has(tube[li]):
				continue
			# troca com uma camada de garrafa aberta que não seja cor-chave
			var spots: Array = []
			for oi in open_filled:
				for lj in (tubes[oi] as Array).size():
					if not keys.has(tubes[oi][lj]):
						spots.append([oi, lj])
			if spots.is_empty():
				return _no_covers(tubes.size())
			var spot: Array = spots[rng.randi_range(0, spots.size() - 1)]
			var tmp = tube[li]
			tube[li] = tubes[spot[0]][spot[1]]
			tubes[spot[0]][spot[1]] = tmp
	for n_i in n:
		covers[chosen[n_i]] = keys[n_i]
	return covers


static func _built(tubes: Array, covers: Array, par: int, ice: Array, only: Array) -> Dictionary:
	var out := {"tubes": tubes, "covers": covers, "par": par}
	if not ice.is_empty():
		out["ice"] = ice
	if not only.is_empty():
		out["only"] = only
	return out


## Gelo: `count` garrafas cheias e descobertas ficam presas de 3 a 6 jogadas. [] = fase sem gelo.
static func _pick_ice(rng: RandomNumberGenerator, tubes: Array, covers: Array, count: int) -> Array:
	if count <= 0:
		return []
	var ice: Array = []
	var free: Array = []
	for i in tubes.size():
		ice.append(0)
		if not (tubes[i] as Array).is_empty() and int(covers[i]) < 0:
			free.append(i)
	for _n in mini(count, free.size()):
		var at: int = free.pop_at(rng.randi_range(0, free.size() - 1))
		ice[at] = rng.randi_range(3, 6)
	return ice


## Frasco de uma cor: a última garrafa vazia só aceita uma cor da fase. [] = fase sem ele.
static func _pick_only(rng: RandomNumberGenerator, tubes: Array, palette: Array, count: int) -> Array:
	if count <= 0:
		return []
	var only: Array = []
	for i in tubes.size():
		only.append(-1)
	var at := -1
	for i in tubes.size():
		if (tubes[i] as Array).is_empty():
			at = i
	if at >= 0:
		only[at] = palette[rng.randi_range(0, palette.size() - 1)]
	return only


static func _no_covers(count: int) -> Array:
	var out: Array = []
	for i in count:
		out.append(-1)
	return out


static func _pick_colors(rng: RandomNumberGenerator, count: int, palette_size: int) -> Array:
	var all: Array = range(palette_size)
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
		if SortPuzzle.is_complete(t):
			return true
	return false


## Embaralha com a semente (Fisher-Yates), sem depender do embaralhador do motor.
static func _shuffle(rng: RandomNumberGenerator, arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
