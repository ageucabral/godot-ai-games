class_name Rules
extends RefCounted
## Regras do documento do jogo: pontos, desafios do dia e datas (horário de Brasília).

const EASY := "easy"
const MEDIUM := "medium"
const HARD := "hard"

## Cada fase (nível ou desafio) vale o dobro do número exato de jogadas (Ageu, 7/11/2026):
## precisa de 11 jogadas → vale 22 pontos. Cada jogada a mais tira 1 ponto.
const POINTS_PER_MOVE: int = 2
const DIFFICULTY_NAMES := {EASY: "Fácil", MEDIUM: "Médio", HARD: "Difícil"}

## Os 20 desafios do dia: 8 fáceis, 7 médios e 5 difíceis.
const DAILY_EASY: int = 8
const DAILY_MEDIUM: int = 7
const DAILY_HARD: int = 5
const DAILY_COUNT: int = DAILY_EASY + DAILY_MEDIUM + DAILY_HARD

## Ajudas da partida (Ageu, 7/11/2026): embaralhar e frasco extra. Cada uso pede propaganda e tira
## BOOST_COST ponto(s) da fase. Quantidade por fase como nos jogos do gênero (3 embaralhadas, 1 frasco).
const SHUFFLES_PER_STAGE: int = 3
const EXTRA_BOTTLES_PER_STAGE: int = 1
const BOOST_COST: int = 1

## Movimentos ganhos ao assistir uma propaganda quando as jogadas acabam.
const EXTRA_MOVES: int = 5

## Brasília não tem horário de verão desde 2019: sempre UTC-3.
const BRASILIA_OFFSET_SECONDS: int = -3 * 3600

const MONTH_NAMES: Array[String] = ["janeiro", "fevereiro", "março", "abril", "maio", "junho",
	"julho", "agosto", "setembro", "outubro", "novembro", "dezembro"]


## Novas mecânicas (Ageu, 9/11/2026): garrafa de gelo a partir do nível 40 e garrafa de uma cor a partir do 55.
const ICE_FROM: int = 40
const ONLY_FROM: int = 55

## Degraus do modo por níveis (Ageu, 7/11/2026: dificuldade subindo aos poucos, com mais frascos e
## jogadas diferentes). [a partir do nível, cores, cores repetidas, vazias, cobertas, camadas "?", jogadas mínimas]
const LEVEL_STEPS: Array = [
	[1, 3, 0, 2, 0, false, 4],
	[3, 4, 0, 2, 0, false, 6],
	[6, 5, 0, 2, 0, false, 8],
	[10, 5, 0, 2, 1, false, 9],     # aparece o frasco coberto
	[15, 5, 1, 2, 1, false, 10],    # aparece a cor repetida (duas garrafas da mesma cor)
	[20, 6, 0, 2, 1, false, 12],
	[25, 6, 0, 2, 2, false, 13],
	[30, 6, 0, 2, 2, true, 13],     # aparecem as camadas "?"
	[40, 6, 1, 2, 2, true, 14],
	[50, 7, 0, 2, 2, true, 16],
	[65, 7, 0, 2, 3, true, 17],
	[80, 7, 0, 2, 3, true, 18],
]


## Estrelas de uma fase: 3 = jogadas exatas, 2 = até 3 a mais, 1 = só passou (igual ao servidor).
static func stars_for(moves: int, par: int) -> int:
	if moves <= par:
		return 3
	return 2 if moves <= par + 3 else 1


## Dias da sequência que dão uma ajuda grátis (no servidor).
const STREAK_FREE_BOOST_DAYS: Array[int] = [3, 5]


## Sequência depois de resolver uma fase em `today`: o mesmo dia não muda; o dia seguinte soma 1; pulou um dia, volta a 1.
static func next_streak(last: String, count: int, today: String) -> int:
	if last == today:
		return count
	return count + 1 if not last.is_empty() and add_days(last, 1) == today else 1


## Sequência que vale hoje (se o último dia jogado foi antes de ontem, já caiu para 0).
static func live_streak(last: String, count: int, today: String) -> int:
	return count if not last.is_empty() and (last == today or add_days(last, 1) == today) else 0


## "AAAA-MM-DD" mais n dias.
static func add_days(date: String, n: int) -> String:
	var d := Time.get_unix_time_from_datetime_string(date + "T12:00:00")
	return Time.get_date_string_from_unix_time(d + n * 86400)


## Como cada nível é montado: segue o degrau do nível e, dentro dele, pede um pouco mais de jogadas
## a cada 3 níveis (até +3), para a subida ser gradual.
static func level_setup(level: int) -> Dictionary:
	var step: Array = LEVEL_STEPS[0]
	for s in LEVEL_STEPS:
		if level >= int(s[0]):
			step = s
	var bonus := mini((level - int(step[0])) / 3, 3)
	return {"colors": step[1], "repeats": step[2], "empty": step[3], "covers": step[4],
		"hidden": step[5], "min_par": int(step[6]) + bonus,
		"ice": 1 if level >= ICE_FROM else 0, "only": 1 if level >= ONLY_FROM else 0}


## Nome da dificuldade mostrado num nível (pelo degrau): com camadas "?" é difícil,
## com frasco coberto é médio, senão fácil.
static func level_difficulty(level: int) -> String:
	var setup := level_setup(level)
	if setup.hidden:
		return HARD
	if int(setup.covers) > 0:
		return MEDIUM
	return EASY


static func difficulty_for(index: int) -> String:
	if index < DAILY_EASY:
		return EASY
	if index < DAILY_EASY + DAILY_MEDIUM:
		return MEDIUM
	return HARD


## Pontuação cheia de uma fase que pede `par` jogadas.
static func full_points_for(par: int) -> int:
	return maxi(0, par) * POINTS_PER_MOVE


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
