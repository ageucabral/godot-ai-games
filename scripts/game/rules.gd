class_name Rules
extends RefCounted
## Regras do documento do jogo: pontos por dificuldade, desafios do dia e datas (horário de Brasília).

const EASY := "easy"
const MEDIUM := "medium"
const HARD := "hard"

## Pontuação cheia de cada dificuldade.
const FULL_POINTS := {EASY: 10, MEDIUM: 25, HARD: 50}
const DIFFICULTY_NAMES := {EASY: "Fácil", MEDIUM: "Médio", HARD: "Difícil"}

## Os 20 desafios do dia: 8 fáceis, 7 médios e 5 difíceis.
const DAILY_EASY: int = 8
const DAILY_MEDIUM: int = 7
const DAILY_HARD: int = 5
const DAILY_COUNT: int = DAILY_EASY + DAILY_MEDIUM + DAILY_HARD

## Pontos fixos de cada nível do modo por níveis (bem menos que os desafios do dia).
const LEVEL_POINTS: int = 2

## Movimentos ganhos ao assistir uma propaganda quando as jogadas acabam.
const EXTRA_MOVES: int = 5

## Brasília não tem horário de verão desde 2019: sempre UTC-3.
const BRASILIA_OFFSET_SECONDS: int = -3 * 3600

const MONTH_NAMES: Array[String] = ["janeiro", "fevereiro", "março", "abril", "maio", "junho",
	"julho", "agosto", "setembro", "outubro", "novembro", "dezembro"]


## Como cada nível é montado: a dificuldade cresce sem fim.
## Mais cores, menos chance de soluções curtas e, a partir do nível 30, camadas escondidas.
static func level_setup(level: int) -> Dictionary:
	var colors := 3
	var min_par := 4
	if level >= 40:
		colors = 7
		min_par = mini(16 + (level - 40) / 20, 20)
	elif level >= 20:
		colors = 6
		min_par = 12 + (level - 20) / 5
	elif level >= 9:
		colors = 5
		min_par = 9
	elif level >= 3:
		colors = 4
		min_par = 6
	return {"colors": colors, "empty": 2, "min_par": min_par, "hidden": level >= 30}


## Nome da dificuldade mostrado num nível (pelas cores usadas).
static func level_difficulty(level: int) -> String:
	var colors: int = level_setup(level).colors
	if colors <= 4:
		return EASY
	if colors == 5:
		return MEDIUM
	return HARD


static func difficulty_for(index: int) -> String:
	if index < DAILY_EASY:
		return EASY
	if index < DAILY_EASY + DAILY_MEDIUM:
		return MEDIUM
	return HARD


## Pontos de uma tentativa: cheia até o número exato de movimentos; cada um a mais tira 1.
static func score_for(full_points: int, par: int, moves_used: int) -> int:
	return maxi(0, full_points - maxi(0, moves_used - par))


static func _local(unix: int) -> Dictionary:
	return Time.get_datetime_dict_from_unix_time(unix + BRASILIA_OFFSET_SECONDS)


## Data de hoje em Brasília, no formato "AAAA-MM-DD".
static func date_for(unix: int) -> String:
	var d := _local(unix)
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


## Mês em Brasília, no formato "AAAA-MM" (o ranking zera a cada mês).
static func month_for(unix: int) -> String:
	return date_for(unix).substr(0, 7)


## Segundos até a meia-noite de Brasília (quando saem os desafios novos).
static func seconds_to_next_day(unix: int) -> int:
	return 86400 - posmod(unix + BRASILIA_OFFSET_SECONDS, 86400)


## Segundos até o ranking do mês terminar (meia-noite do último dia, em Brasília).
static func seconds_to_month_end(unix: int) -> int:
	return (days_left_in_month(unix) - 1) * 86400 + seconds_to_next_day(unix)


## Contagem curta: "12d 05h" ou, no último dia, "05:42:10".
static func short_countdown(secs: int) -> String:
	if secs >= 86400:
		return "%dd %02dh" % [secs / 86400, (secs % 86400) / 3600]
	return "%02d:%02d:%02d" % [secs / 3600, (secs % 3600) / 60, secs % 60]


static func days_in_month(year: int, month: int) -> int:
	if month == 2:
		return 29 if (year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)) else 28
	return 30 if month in [4, 6, 9, 11] else 31


## Dias que faltam para o ranking do mês terminar (contando hoje).
static func days_left_in_month(unix: int) -> int:
	var d := _local(unix)
	return days_in_month(d.year, d.month) - d.day + 1


static func pretty_date(date: String) -> String:
	var parts := date.split("-")
	return I18n.t("{day} de {month}").format({"day": int(parts[2]), "month": I18n.t(MONTH_NAMES[int(parts[1]) - 1])})


static func month_name(month_key: String) -> String:
	return I18n.t(MONTH_NAMES[int(month_key.split("-")[1]) - 1])
