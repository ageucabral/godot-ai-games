extends Node
## Efeitos sonoros (gerados por `tools/gen_sounds.py`, em `audio/sfx/`) e a música de fundo (`tools/gen_music.py`,
## em `audio/music/`). Disponível como `Sfx`: `Sfx.play("pour")`. O jogador liga e desliga o som e a música na
## engrenagem (guardado no aparelho).

const SOUNDS := ["tap", "click", "pour", "wrong", "bottle_done", "win", "lose"]
## Vozes ao mesmo tempo (um despejo não corta o outro).
const VOICES := 4

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
## Para testes: os últimos sons tocados (nome), em ordem. Guarda só os últimos `PLAYED_MAX`.
var played: Array[String] = []
const PLAYED_MAX := 32
const MUSIC_PATH := "res://audio/music/calm.ogg"
const MUSIC_DB := -14.0
var _music: AudioStreamPlayer


func _ready() -> void:
	for n in SOUNDS:
		var path := "res://audio/sfx/%s.wav" % n
		if ResourceLoader.exists(path):
			_streams[n] = load(path)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	if ResourceLoader.exists(MUSIC_PATH):
		var stream: AudioStreamOggVorbis = load(MUSIC_PATH)
		stream.loop = true
		_music.stream = stream
	add_child(_music)
	_update_music.call_deferred()


func enabled() -> bool:
	return bool(GameState.get_setting("sound", true))


func set_enabled(on: bool) -> void:
	GameState.set_setting("sound", on)


func music_enabled() -> bool:
	return bool(GameState.get_setting("music", true))


func set_music_enabled(on: bool) -> void:
	GameState.set_setting("music", on)
	_update_music()


## Música tocando (em volta) só com ela ligada; os testes e o servidor sem tela não tocam.
func music_playing() -> bool:
	return _music.playing


func _update_music() -> void:
	var on := music_enabled() and _music.stream != null and DisplayServer.get_name() != "headless"
	if on and not _music.playing:
		_music.play()
	elif not on and _music.playing:
		_music.stop()


func play(sound: String, volume_db: float = 0.0) -> void:
	if not enabled() or not _streams.has(sound):
		return
	played.append(sound)
	if played.size() > PLAYED_MAX:
		played.remove_at(0)
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[sound]
	p.volume_db = volume_db
	p.play()
