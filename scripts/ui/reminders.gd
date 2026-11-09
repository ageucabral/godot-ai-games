class_name Reminders
extends RefCounted
## Aviso no celular (só no Android com o plugin): no máximo um por dia, às 19h de Brasília, só para o que importa,
## nesta ordem: prêmio para resgatar, ranking do mês fechando (últimos 2 dias), sequência em risco e desafios novos.
## Fica sempre só um agendado: cada abertura do app troca pelo próximo.
## O jogador liga e desliga na engrenagem; no Android 13+ o sistema pede a permissão na primeira vez.

const HOUR := 19
## A partir de qual nível o jogo oferece os avisos (uma vez só).
const ASK_FROM_LEVEL := 3


static func enabled() -> bool:
	return bool(GameState.get_setting("reminders", true))


## O plugin com os avisos (null na Web, no computador, nos testes e com o plugin antigo).
static func plugin() -> Object:
	return Server.native_with("notifications_allowed")


## Hora do próximo aviso (Unix): hoje às 19h se ainda não jogou hoje e ainda não passou; senão amanhã às 19h.
static func next_time(now: int, played_today: bool) -> int:
	var at := now + Rules.seconds_to_next_day(now) - 86400 + HOUR * 3600  # hoje às 19h
	return at + 86400 if played_today or now >= at else at


## [título, texto] do aviso para a hora `at`. `streak` = dias seguidos; `position` = lugar no Ranking Global do mês
## (null = fora); `prize` = tem prêmio para resgatar; `daily` = os desafios do dia já liberaram (Rules.UNLOCKS).
static func message(streak: int, at: int = 0, position: Variant = null, prize: bool = false, daily: bool = true) -> Array[String]:
	if prize:
		return ["Na Lata", I18n.t("Você tem um prêmio para resgatar. Abra o app e peça o seu!")]
	var days := Rules.days_left_in_month(at) if at > 0 else 99
	if position != null and days == 1:
		return ["Na Lata", I18n.t("Falta 1 dia para o ranking do mês fechar. Você está em %dº.") % int(position)]
	if position != null and days <= 2:
		return ["Na Lata", I18n.t("Faltam %d dias para o ranking do mês fechar. Você está em %dº.") % [days, int(position)]]
	if streak >= 2:
		return [I18n.t("Poção de Cores"), "🔥 " + I18n.t("Sua sequência de %d dias acaba à meia-noite. Uma fase basta!") % streak]
	if not daily:
		return [I18n.t("Poção de Cores"), I18n.t("Seu próximo nível te espera!") + " 🧪"]
	return [I18n.t("Poção de Cores"), I18n.t("Os %d desafios de hoje chegaram! Seja o primeiro a resolver") % Rules.DAILY_COUNT + " 🧪"]


## Agenda (ou desliga) o aviso. Chamado ao abrir o app, ao sair dele e ao mudar a escolha.
static func update() -> void:
	var p := plugin()
	if p == null:
		return
	if not enabled() or not p.notificationsAllowed():
		p.cancelReminder()
		return
	var s := GameState.streak()
	var at := next_time(GameState.now_unix(), bool(s.played_today))
	var month := GameState.global_month_total(Rules.month_for(at))
	var m := message(int(s.count), at, month.get("position"), not Prizes.pending_payouts().is_empty(),
		Rules.unlocked("daily", GameState.current_level()))
	p.scheduleReminder(at * 1000, m[0], m[1])


## Liga ou desliga pela engrenagem. Ao ligar, pede a permissão do Android se faltar.
static func set_enabled(on: bool) -> void:
	GameState.set_setting("reminders", on)
	var p := plugin()
	if on and p != null and not p.notificationsAllowed():
		p.requestNotifications()
		await Server.wait_signal(Signal(p, "notifications_allowed"), 60.0, [false, null])
	update()


## Oferece os avisos uma vez, depois das primeiras fases (o Android 13+ só mostra se o jogador quiser).
static func maybe_ask(dialog: DialogBox) -> void:
	var p := plugin()
	if p == null or Server.get_flag("reminders_asked") or GameState.current_level() < ASK_FROM_LEVEL or p.notificationsAllowed():
		return
	Server.set_flag("reminders_asked")
	dialog.open("Avisos no celular", I18n.t("Quer um aviso por dia quando os desafios novos chegarem? No máximo um por dia."), [
		["Quero avisos", func() -> void: set_enabled(true), true],
		["Agora não", func() -> void: GameState.set_setting("reminders", false)],
	])
