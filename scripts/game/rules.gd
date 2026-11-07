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

## Movimentos ganhos ao assistir uma propaganda quando as jogadas acabam.
const EXTRA_MOVES: int = 5

## Brasília não tem horário de verão desde 2019: sempre UTC-3.
const BRASILIA_OFFSET_SECONDS: int = -3 * 3600

const MONTH_NAMES: Array[String] = ["janeiro", "fevereiro", "março", "abril", "maio", "junho",
	"julho", "agosto", "setembro", "outubro", "novembro", "dezembro"]


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
	return "%d de %s" % [int(parts[2]), MONTH_NAMES[int(parts[1]) - 1]]


static func month_name(month_key: String) -> String:
	return MONTH_NAMES[int(month_key.split("-")[1]) - 1]
