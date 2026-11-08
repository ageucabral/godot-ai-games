extends Node
## Efeitos sonoros (gerados por `tools/gen_sounds.py`, em `audio/sfx/`). Disponível como `Sfx`.
## `Sfx.play("pour")`. O jogador liga e desliga o som na engrenagem (guardado no aparelho).

const SOUNDS := ["tap", "click", "pour", "wrong", "bottle_done", "win", "lose"]
## Vozes ao mesmo tempo (um despejo não corta o outro).
const VOICES := 4

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
## Para testes: sons tocados (nome), em ordem.
var played: Array[String] = []


func _ready() -> void:
	for n in SOUNDS:
		var path := "res://audio/sfx/%s.wav" % n
		if ResourceLoader.exists(path):
			_streams[n] = load(path)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func enabled() -> bool:
	return bool(GameState.get_setting("sound", true))


func set_enabled(on: bool) -> void:
	GameState.set_setting("sound", on)


func play(sound: String, volume_db: float = 0.0) -> void:
	if not enabled() or not _streams.has(sound):
		return
	played.append(sound)
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[sound]
	p.volume_db = volume_db
	p.play()
