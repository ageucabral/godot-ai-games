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
## Duas músicas: uma calma para os menus e outra para a partida (troca junto com a tela).
const TRACKS := {"menu": "res://audio/music/calm.ogg", "game": "res://audio/music/play.ogg"}
const MUSIC_DB := -14.0
var _music: AudioStreamPlayer
var _tracks: Dictionary = {}
## Música da tela aberta agora: "menu" ou "game".
var track: String = "menu"
## Músicas enviadas pelo painel (Ageu, 9/11/2026; até 3): com alguma, tocam uma depois da outra em todas as telas,
## no lugar das duas do app. Vazio = as do app.
var playlist: Array[AudioStream] = []
var _playlist_at: int = 0
## Vibração leve junto de alguns sons da partida (Ageu, 9/11/2026): [duração em ms, força 0–1]. Liga e desliga na
## engrenagem ("Vibração"), separado do som.
const HAPTICS := {"tap": [12, 0.35], "pour": [22, 0.6], "bottle_done": [45, 1.0], "wrong": [30, 0.5]}
## Para testes: as últimas vibrações (nome do som).
var vibrated: Array[String] = []


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
	for k: String in TRACKS:
		if ResourceLoader.exists(TRACKS[k]):
			var stream: AudioStreamOggVorbis = load(TRACKS[k])
			stream.loop = true
			_tracks[k] = stream
	_music.stream = _tracks.get(track)
	_music.finished.connect(_next_in_playlist)
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


## Troca a música ("menu" ou "game"); a mesma que já toca continua de onde estava.
func set_track(name: String) -> void:
	if name == track or not _tracks.has(name):
		return
	track = name
	if not playlist.is_empty():
		return  # as músicas do painel seguem tocando em qualquer tela
	var was_playing := _music.playing
	_music.stop()
	_music.stream = _tracks[name]
	if was_playing:
		_update_music()


## Troca para as músicas do painel (arquivos .ogg/.mp3 já baixados); lista vazia volta para as do app.
func set_custom_tracks(paths: Array) -> void:
	playlist.clear()
	for path: String in paths:
		var stream: AudioStream = AudioStreamOggVorbis.load_from_file(path) if path.get_extension() == "ogg" \
				else AudioStreamMP3.load_from_file(path)
		if stream:
			stream.set("loop", false)
			playlist.append(stream)
	_playlist_at = 0
	_switch_to(playlist[0] if not playlist.is_empty() else _tracks.get(track))


func _next_in_playlist() -> void:
	if playlist.is_empty():
		return
	_playlist_at = (_playlist_at + 1) % playlist.size()
	_music.stream = playlist[_playlist_at]  # com uma música só, é a mesma: toca de novo
	_update_music()


func _switch_to(stream: AudioStream) -> void:
	if _music.stream == stream:
		return
	_music.stop()
	_music.stream = stream
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


func vibration_enabled() -> bool:
	return bool(GameState.get_setting("vibration", true))


func set_vibration_enabled(on: bool) -> void:
	GameState.set_setting("vibration", on)
	if on and OS.has_feature("mobile"):
		Input.vibrate_handheld(20, 0.5)  # mostra como fica


func play(sound: String, volume_db: float = 0.0) -> void:
	if HAPTICS.has(sound) and vibration_enabled():
		vibrated.append(sound)
		if vibrated.size() > PLAYED_MAX:
			vibrated.remove_at(0)
		# só no celular (a chave fica na engrenagem do celular; na Web não há como desligar)
		if OS.has_feature("mobile"):
			Input.vibrate_handheld(HAPTICS[sound][0], HAPTICS[sound][1])
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
