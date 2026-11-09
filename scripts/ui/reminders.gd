class_name Reminders
extends RefCounted
## Aviso no celular (só no Android com o plugin): no máximo um por dia, às 19h de Brasília, lembrando da
## sequência de dias ou dos desafios novos. Fica sempre só um agendado: cada abertura do app troca pelo próximo.
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
	var local := now + Rules.BRASILIA_OFFSET_SECONDS
	var at := local - posmod(local, 86400) + HOUR * 3600
	if played_today or local >= at:
		at += 86400
	return at - Rules.BRASILIA_OFFSET_SECONDS


## [título, texto] do aviso: com sequência, lembra dela; senão, dos desafios novos.
static func message(streak: int) -> Array[String]:
	if streak >= 2:
		return [I18n.t("%d dias seguidos!") % streak, I18n.t("Resolva uma fase hoje para não perder a sequência.")]
	return [I18n.t("Desafios novos no ar"), I18n.t("Os 20 desafios de hoje estão esperando por você.")]


## Agenda (ou desliga) o aviso. Chamado ao abrir o app, ao sair dele e ao mudar a escolha.
static func update() -> void:
	var p := plugin()
	if p == null:
		return
	if not enabled() or not p.notificationsAllowed():
		p.cancelReminder()
		return
	var s := GameState.streak()
	var m := message(int(s.count))
	p.scheduleReminder(next_time(GameState.now_unix(), bool(s.played_today)) * 1000, m[0], m[1])


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
