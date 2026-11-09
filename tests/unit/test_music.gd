extends "res://tests/test_case.gd"
## Músicas de fundo enviadas pelo painel: baixa uma vez, guarda no aparelho e toca no lugar das do app.

const DIR := "user://test_music"
var downloads: Array = []


func before_each() -> void:
	downloads = []
	Server.music_dir = DIR
	Server.music_download = func(url: String, dest: String) -> bool:
		downloads.append(url)
		var f := FileAccess.open(dest, FileAccess.WRITE)
		f.store_buffer(FileAccess.get_file_as_bytes("res://audio/music/calm.ogg"))
		return true
	_clear()


func after_each() -> void:
	Server.config = {}
	Server.music_download = Callable()
	Server.music_dir = "user://music"
	_clear()
	Sfx.set_custom_tracks([])


func _clear() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func test_music_file_name() -> void:
	assert_eq(ApiClient.music_file_name({"slot": 2, "mime": "audio/mpeg", "version": "ab12"}), "2-ab12.mp3")
	assert_eq(ApiClient.music_file_name({"slot": 1, "mime": "audio/ogg", "version": "ff", "url": "/pocao/music/1?v=ff"}), "1-ff.ogg")
	assert_eq(ApiClient.music_file_name({"slot": 4, "mime": "audio/ogg", "version": "ff", "url": "/pocao/music/4?v=ff"}), "", "vaga fora de 1–3")
	assert_eq(ApiClient.music_file_name({"slot": 1, "mime": "audio/wav", "version": "ff"}), "", "formato que o jogo não toca")
	assert_eq(ApiClient.music_file_name({"slot": 1, "mime": "audio/ogg", "version": "../x"}), "", "versão estranha")


func test_admin_music_downloads_once_and_replaces_built_in() -> void:
	Server.config = {"music": [{"slot": 1, "mime": "audio/ogg", "version": "aa11", "url": "/pocao/music/1?v=aa11"}, {"slot": 3, "mime": "audio/ogg", "version": "cc33", "url": "/pocao/music/3?v=cc33"}]}
	await Server.sync_music()
	assert_eq(downloads, ["/pocao/music/1?v=aa11", "/pocao/music/3?v=cc33"])
	assert_eq(Sfx.playlist.size(), 2, "toca as duas do painel")
	Sfx.set_track("game")
	assert_eq(Sfx.playlist.size(), 2, "trocar de tela não volta para as do app")

	# Abrir de novo: não baixa outra vez. Trocar a 3 baixa só ela e apaga a velha.
	Server.config = {"music": [{"slot": 1, "mime": "audio/ogg", "version": "aa11", "url": "/pocao/music/1?v=aa11"}, {"slot": 3, "mime": "audio/ogg", "version": "dd44", "url": "/pocao/music/3?v=dd44"}]}
	await Server.sync_music()
	assert_eq(downloads.size(), 3)
	assert_eq(Array(DirAccess.get_files_at(DIR)), ["1-aa11.ogg", "3-dd44.ogg"])

	# Sem internet (sem /config): usa as guardadas.
	Server.config = {}
	Sfx.set_custom_tracks([])
	await Server.sync_music()
	assert_eq(Sfx.playlist.size(), 2)

	# O painel tirou todas: volta para as do app.
	Server.config = {"music": []}
	await Server.sync_music()
	assert_eq(Sfx.playlist.size(), 0)
	assert_eq(DirAccess.get_files_at(DIR).size(), 0)
	Sfx.set_track("menu")


func test_failed_download_is_skipped() -> void:
	Server.music_download = func(_url: String, _dest: String) -> bool: return false
	Server.config = {"music": [{"slot": 1, "mime": "audio/ogg", "version": "aa11", "url": "/pocao/music/1?v=aa11"}]}
	await Server.sync_music()
	assert_eq(Sfx.playlist.size(), 0, "sem o arquivo, segue com as do app")
