class_name Extras
extends RefCounted
## As ideias novas do Poção de Cores, desenhadas como na proposta aprovada pelo Ageu (9/11/2026): sequência de dias
## (abre sozinha uma vez por dia), conquistas com ícone e barra, Meus frascos (frascos, molduras e fundos), cartão do
## duelo e o cartão da vitória. Os números vêm do servidor (`GameState.extras`); sem servidor só a sequência e as
## estrelas funcionam.

## Conquistas (ids do servidor, na ordem da tela): [nome, ícone, texto quando feita, unidade do progresso].
const ACHIEVEMENTS := {
	"exact_10": ["Mão certeira", "🎯", "10 fases exatas", "exatas"],
	"ice_20": ["Quebra-gelo", "🧊", "abriu 20 gelos", "gelos"],
	"covers_50": ["Tira-pano", "🧵", "abriu 50 panos", "panos"],
	"streak_7": ["Semana de fogo", "🔥", "7 dias seguidos", "dias"],
	"daily_all": ["Todos do dia", "📅", "20 desafios num dia", "hoje"],
	"top_100": ["Top 100", "🏆", "no ranking do mês", ""],
	"invite_3": ["Bom de convite", "🤝", "3 amigos jogando", "amigos"],
	"level_100": ["Nível 100", "🧪", "chegou ao nível 100", ""],
	"duel_5": ["Duelista", "⚔️", "venceu 5 duelos", "duelos"],
	"first_win": ["Primeira poção", "⚗️", "resolveu a 1ª fase", ""],
	"streak_3": ["Chama acesa", "🕯️", "3 dias seguidos", "dias"],
	"level_25": ["Nível 25", "🌱", "chegou ao nível 25", ""],
	"level_50": ["Nível 50", "🌳", "chegou ao nível 50", ""],
	"exact_50": ["Alquimista perfeito", "💎", "50 fases exatas", "exatas"],
	"only_20": ["Uma cor só", "🔵", "encheu 20 frascos de uma cor", "frascos"],
	"daily_100": ["Cem desafios", "📆", "100 desafios do dia", "desafios"],
	"duel_1": ["Primeiro duelo", "🤺", "venceu um duelo", ""],
	"league_up": ["Subiu de liga", "🚀", "subiu na Liga da semana", ""],
	"event_1": ["Festeiro", "🎉", "completou um evento", ""],
	"streak_30": ["Mês de fogo", "☄️", "30 dias seguidos", "dias"],
	"exact_100": ["Na mosca", "🏹", "100 fases exatas", "exatas"],
	"top_10": ["Top 10", "🥇", "entre os 10 do mês", ""],
	"event_3": ["Rei das festas", "🎪", "completou 3 eventos", "eventos"],
	"level_200": ["Nível 200", "🏰", "chegou ao nível 200", ""],
}
## Frascos: [nome, como ganhar]. Os liberados vêm do servidor (`looks.skins`). Os de evento são "event:<tema>".
const SKINS := {
	"classic": ["Clássico", ""],
	"cauldron": ["Caldeirão", "🌱 nível 25"],
	"tube": ["Tubo de ensaio", "🎯 10 exatas"],
	"heart": ["Coração", "🔥 30 dias"],
	"golden": ["Dourado", "🏆 Top 100"],
	"event:halloween": ["Abóbora", "🎃 evento"],
	"crystal": ["Cristal", "🚀 subir de liga"],
	"event:natal": ["Natal", "🎄 evento"],
	"event:carnaval": ["Carnaval", "🎭 evento"],
}
## Fundos da partida: [nome, fundo da tela (SceneBackground), como ganhar].
const BACKGROUNDS := {"night": ["Noite estrelada", "night", ""], "sunset": ["Pôr do sol", "sky", "🔥 3 dias"],
	"sky": ["Céu de dia", "day", "📅 dia completo"], "event:halloween": ["Halloween", "halloween", "🎃 evento"],
	"event:natal": ["Natal", "natal", "🎄 evento"], "event:carnaval": ["Carnaval", "carnaval", "🎭 evento"]}
## Molduras do apelido no ranking: [nome, cor, como ganhar]. A de fogo é o prêmio do dia 7 da sequência.
const FRAMES := {"fire": ["Fogo", Color("ff7a1f"), "🔥 7 dias"], "league": ["Liga", Color("8b45f0"), "🚀 subir de liga"],
	"gold": ["Ouro", Color("ffc72e"), "🏆 Top 100"], "event:halloween": ["Abóbora", Color("ff9a1f"), "🎃 evento"],
	"event:natal": ["Natal", Color("e0303f"), "🎄 evento"], "event:carnaval": ["Carnaval", Color("e04fd0"), "🎭 evento"]}
## Visuais que só aparecem na lista depois de ganhos (os outros aparecem sempre, com cadeado e como ganhar).
const HIDDEN_UNTIL_WON := ["crystal", "event:natal", "event:carnaval"]
## Ligas (0 = a primeira): [nome, medalha].
const LEAGUES: Array = [["Liga Bronze", "🥉"], ["Liga Prata", "🥈"], ["Liga Ouro", "🥇"], ["Liga Rubi", "♦️"], ["Liga Diamante", "💎"]]
## Tema do evento: [cor, ícone].
const EVENT_THEMES := {"halloween": [Color("ff7a1f"), "🎃"], "natal": [Color("e0303f"), "🎄"], "carnaval": [Color("e04fd0"), "🎭"]}
## Ícone de cada prêmio da trilha do evento (o último, o fundo, usa o ícone do tema).
const EVENT_REWARD_ICONS := {"boost": "🎁", "skin": "🧪", "frame": "👑"}
## Prêmios da sequência: [dia, ícone, prêmio].
const STREAK_REWARDS: Array = [[3, "🎁", "1 ajuda grátis"], [5, "🎁", "1 ajuda grátis"], [7, "👑", "moldura"], [30, "🧪", "frasco Coração"]]
## Endereço do link do duelo (a página abre o app ou a Play).
const DUEL_URL := "https://nalatagame.tech/duelo/%s"
const WEEKDAYS := ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
const LOCKED_TILE := Color("efe9df")


## Fundo da partida (SceneBackground) do visual escolhido.
static func background_kind(bg: String) -> String:
	return BACKGROUNDS[bg][1] if BACKGROUNDS.has(bg) else "night"


## Liga pelo número (o servidor manda de 0 a 4).
static func league_name(tier: int) -> String:
	return LEAGUES[clampi(tier, 0, LEAGUES.size() - 1)][0]


static func league_medal(tier: int) -> String:
	return LEAGUES[clampi(tier, 0, LEAGUES.size() - 1)][1]


## Nome da conquista no idioma do jogo.
static func achievement_name(id: String) -> String:
	return I18n.t(ACHIEVEMENTS[id][0]) if ACHIEVEMENTS.has(id) else id


## Ícone (emoji) da conquista, usado também como selo ao lado do apelido.
static func achievement_icon(id: String) -> String:
	return ACHIEVEMENTS[id][1] if ACHIEVEMENTS.has(id) else ""


static func event_icon(theme: String) -> String:
	return EVENT_THEMES[theme][1] if EVENT_THEMES.has(theme) else "🎉"


static func event_color(theme: String) -> Color:
	return EVENT_THEMES[theme][0] if EVENT_THEMES.has(theme) else Color("e04fd0")


## Cor da moldura do apelido (transparente = sem moldura).
static func frame_color(frame: Variant) -> Color:
	return FRAMES[frame][1] if frame is String and FRAMES.has(frame) else Color(0, 0, 0, 0)


# ---------- sequência de dias ----------

## As 7 caixinhas da sequência: [dia da semana ("Hoje" para hoje), aceso, ícone do prêmio, é hoje].
## O ciclo de 7 dias anda junto com a sequência: a 1ª caixa é o 1º dia da semana de sequência em que está hoje.
## Número do dia de hoje na sequência (se ainda não jogou hoje, hoje seria o próximo).
static func _streak_today(count: int, played_today: bool) -> int:
	return count if played_today else count + 1


static func streak_days(count: int, played_today: bool, today_unix: int) -> Array:
	var t := _streak_today(count, played_today)
	var base := 7 * int((t - 1) / 7)
	var out: Array = []
	for k in 7:
		var d := base + k + 1
		var weekday: int = Time.get_datetime_dict_from_unix_time(today_unix + (d - t) * 86400).weekday
		var lit := d < t or (d == t and played_today)
		var icon := ""
		if not lit:
			for r: Array in STREAK_REWARDS:
				if int(r[0]) == d:
					icon = r[1]
		out.append(["Hoje" if d == t else WEEKDAYS[weekday], lit, icon, d == t])
	return out


## Os próximos 2 prêmios da sequência: "🎁 dia 5: 1 ajuda grátis".
static func next_streak_rewards(count: int, played_today: bool) -> Array[String]:
	var t := _streak_today(count, played_today)
	var out: Array[String] = []
	for r: Array in STREAK_REWARDS:
		if out.size() < 2 and (int(r[0]) > t or (int(r[0]) == t and not played_today)):
			out.append("%s %s" % [r[1], I18n.t("dia %d: %s") % [int(r[0]), I18n.t(r[2])]])
	return out


static func open_streak(dialog: DialogBox) -> void:
	var s := GameState.streak()
	var count := int(s.count)
	var title := "🔥 " + (I18n.t("%d dias seguidos!") % count if count > 0 else I18n.t("Comece sua sequência!"))
	dialog.open_card(title, I18n.t("Jogue todo dia para manter a chama acesa."), [["Continuar", func() -> void: pass, true]], GameStyle.GOLD)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	# "Hoje" é o dia de Brasília: meio-dia dele, para o dia da semana não escorregar
	var noon := GameState.now_unix() + Rules.seconds_to_next_day(GameState.now_unix()) - 43200
	for d: Array in streak_days(count, bool(s.played_today), noon):
		row.add_child(_streak_box(d))
	var rewards := next_streak_rewards(count, bool(s.played_today))
	if not free_boosts_line().is_empty():
		rewards.append(free_boosts_line())
	var foot := GameStyle.make_label("    ".join(rewards), 22, true, Color(GameStyle.INK, 0.85))
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	box.add_child(foot)
	dialog.add_content(box)


## Uma caixinha da sequência: chama acesa, prêmio do dia ou vazia, e o dia da semana embaixo.
static func _streak_box(d: Array) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(66, 66)
	var st := StyleBoxFlat.new()
	st.bg_color = Color("ff9a2e") if d[1] else Color("efe8ff")
	st.border_color = GameStyle.GOLD if d[3] and d[1] else GameStyle.INK
	st.set_border_width_all(4)
	st.set_corner_radius_all(14)
	tile.add_theme_stylebox_override("panel", st)
	var icon := GameStyle.make_label("🔥" if d[1] else str(d[2]), 34)
	icon.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	tile.add_child(icon)
	col.add_child(tile)
	col.add_child(GameStyle.make_label(d[0], 20, true))
	return col


# ---------- missões do dia ----------

## "🎁 Ajudas grátis guardadas: N" (vazio sem nenhuma), usado na sequência e nas missões.
static func free_boosts_line() -> String:
	var free := int(GameState.streak().free_boosts)
	return "🎁 " + I18n.t("Ajudas grátis guardadas: %d") % free if free > 0 else ""

## Nome de cada missão do servidor (`id` → texto).
const MISSION_NAMES := {"solve3": "Resolva 3 fases", "exact1": "Faça 1 fase com jogadas exatas", "daily3": "Jogue 3 desafios do dia"}


## Missões do dia: 3 tarefas, cada uma com barra de progresso e "Resgatar" quando concluída (+1 ajuda grátis).
static func open_missions(dialog: DialogBox) -> void:
	var text := I18n.t("Cada missão concluída dá 1 ajuda grátis. Missões novas à meia-noite.")
	if not free_boosts_line().is_empty():
		text += "\n" + free_boosts_line()
	dialog.open_card("🎯 " + I18n.t("Missões do dia"), text, [["Fechar", func() -> void: pass, true]], GameStyle.GOLD)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	for m: Dictionary in GameState.missions():
		box.add_child(_mission_row(dialog, m))
	dialog.add_content(box)


static func _mission_row(dialog: DialogBox, m: Dictionary) -> Control:
	var id := str(m.get("id", ""))
	var goal := int(m.get("goal", 1))
	var value := int(m.get("value", 0))
	var claimed := bool(m.get("claimed", false))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	var name := GameStyle.make_label(MISSION_NAMES.get(id, id), 24, true)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(name)
	var sub := "%d/%d" % [value, goal]
	if id == "daily3" and not Rules.unlocked("daily", GameState.current_level()):
		sub = I18n.t("Abre no nível %d") % Rules.unlock_level("daily")  # os desafios do dia ainda estão trancados
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	var bar := ProgressLine.new(float(value) / float(goal))
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(bar)
	var count := GameStyle.make_label(sub, 20, true, Color(GameStyle.INK, 0.8))
	count.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	line.add_child(count)
	col.add_child(line)
	row.add_child(col)
	if claimed:
		var ok := GameStyle.make_label("✓", 30, true, GameStyle.GREEN)
		ok.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		ok.custom_minimum_size = Vector2(150, 0)
		row.add_child(ok)
	elif value >= goal:
		var b := GameStyle.make_button("Resgatar", true, 24)
		b.custom_minimum_size = Vector2(150, 56)
		b.pressed.connect(func() -> void: _claim_mission(dialog, id))
		row.add_child(b)
	else:
		var gift := GameStyle.make_label("🎁", 30)
		gift.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		gift.custom_minimum_size = Vector2(150, 0)
		row.add_child(gift)
	return row


## Pede a ajuda grátis da missão ao servidor e redesenha a janela.
static func _claim_mission(dialog: DialogBox, id: String) -> void:
	dialog.open("Carregando…", "", [])
	var res: Dictionary = await Server.call_api("POST", "/pocao/missions/%s/claim" % id)
	if res.ok:
		GameState.apply_mission_claim(res.data)
		Sfx.play("win")
	else:
		await Server.refresh_home()  # já resgatada em outro aparelho, ou ainda não concluída: mostra o estado certo
	open_missions(dialog)


## Mostra a sequência sozinha na primeira abertura do dia (só jogando pelo servidor). true se abriu.
static func maybe_show_streak(dialog: DialogBox) -> bool:
	if GameState.extras.is_empty() or str(GameState.get_setting("streak_seen", "")) == GameState.today():
		return false
	GameState.set_setting("streak_seen", GameState.today())
	open_streak(dialog)
	return true


# ---------- conquistas, frascos e fundos ----------

## Conquistas e Meus frascos: uma página só, com as duas abas (entra pela engrenagem).
static func open_collection(dialog: DialogBox, tab: String = "achievements") -> PageView:
	var page := PageView.new("Conquistas")
	dialog.get_parent().add_child(page)
	page.set_tabs([["achievements", "Conquistas", _fill_achievements.bind(page)], ["looks", "Meus frascos", _fill_looks.bind(page)]], tab)
	return page


## Progresso de uma conquista para a tela: [valor, meta]. "Todos do dia" mostra os desafios de hoje.
static func achievement_progress(a: Dictionary) -> Array[int]:
	if str(a.get("id", "")) == "daily_all":
		return [Menus.daily_done(), Rules.DAILY_COUNT]
	return [int(a.get("value", 0)), int(a.get("goal", 1))]


static func _fill_achievements(body: VBoxContainer, page: PageView) -> void:
	var list: Array = GameState.extras.get("achievements", [])
	if list.is_empty():
		body.add_child(_note("As conquistas aparecem jogando pelo app da Play Store."))
		return
	var done := list.filter(func(a: Dictionary) -> bool: return bool(a.get("unlocked", false))).size()
	body.add_child(GameStyle.make_label(I18n.t("%d de %d conquistadas") % [done, list.size()], 26, true, GameStyle.ACCENT))
	body.add_child(_note("Toque numa conquista feita para usá-la como selo ao lado do seu apelido no ranking."))
	var badge := str(GameState.looks().get("badge", ""))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 18)
	body.add_child(grid)
	for a: Dictionary in list:
		var id := str(a.get("id", ""))
		var cell := _achievement_cell(a, id == badge)
		if bool(a.get("unlocked", false)):
			cell.set_meta("label", achievement_name(id))
			cell.pressed.connect(func() -> void: _set_look(page, {"badge": null if id == badge else id}))
		else:
			cell.disabled = true
		grid.add_child(cell)


## Uma conquista: medalha redonda com o ícone (colorida se feita), nome e o progresso (ou "seu selo").
static func _achievement_cell(a: Dictionary, chosen: bool) -> Button:
	var id := str(a.get("id", ""))
	var unlocked := bool(a.get("unlocked", false))
	var info: Array = ACHIEVEMENTS.get(id, [id, "🏅", "", ""])
	var cell := Button.new()
	cell.flat = true
	cell.focus_mode = Control.FOCUS_NONE
	cell.custom_minimum_size = Vector2(190, 246)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 4)
	cell.add_child(col)
	col.add_child(Medal.new(info[1], unlocked, chosen))
	var name := GameStyle.make_label(info[0], 22, true, GameStyle.INK if unlocked else Color(GameStyle.INK, 0.75))
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(name)
	var p := achievement_progress(a)
	if not unlocked and p[1] > 1:
		col.add_child(ProgressLine.new(float(p[0]) / float(p[1])))
		var unit := I18n.t(info[3]) if not str(info[3]).is_empty() else ""
		var txt := GameStyle.make_label(("%d/%d %s" % [p[0], p[1], unit]).strip_edges(), 19, false, Color(GameStyle.INK, 0.6))
		txt.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		col.add_child(txt)
	else:
		var how := GameStyle.make_label("seu selo" if chosen else info[2], 19, chosen, GameStyle.ACCENT if chosen else Color(GameStyle.INK, 0.6))
		how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(how)
	_ignore_mouse(col)
	return cell


## Meus frascos: frasco, moldura do apelido e fundo da partida, cada um com "usando", "ganho" ou como ganhar.
static func _fill_looks(body: VBoxContainer, page: PageView) -> void:
	if GameState.extras.is_empty():
		body.add_child(_note("Os frascos aparecem jogando pelo app da Play Store."))
		return
	var looks := GameState.looks()
	var skins: Array = looks.get("skins", [])
	var frames: Array = looks.get("frames", [])
	var bgs: Array = looks.get("backgrounds", [])
	var shown := func(table: Dictionary, have: Array) -> Array:
		return table.keys().filter(func(id: String) -> bool: return have.has(id) or not HIDDEN_UNTIL_WON.has(id))
	body.add_child(_grid_with(shown.call(SKINS, skins), func(id: String) -> Control:
		return _look_tile(SKINS[id][0], _skin_preview(id), skins.has(id), str(looks.get("skin", "classic")) == id, SKINS[id][1],
			func() -> void: _set_look(page, {"skin": id}))))
	body.add_child(GameStyle.make_label("Moldura no ranking", 26, true, GameStyle.ACCENT))
	body.add_child(_grid_with(shown.call(FRAMES, frames), func(id: String) -> Control:
		var chosen := str(looks.get("frame", "")) == id
		return _look_tile(FRAMES[id][0], _frame_preview(FRAMES[id][1]), frames.has(id), chosen, FRAMES[id][2],
			func() -> void: _set_look(page, {"frame": null if chosen else id}), true)))
	body.add_child(GameStyle.make_label("Fundo da partida", 26, true, GameStyle.ACCENT))
	body.add_child(_grid_with(shown.call(BACKGROUNDS, bgs), func(id: String) -> Control:
		return _look_tile(BACKGROUNDS[id][0], _bg_preview(BACKGROUNDS[id][1], bgs.has(id)), bgs.has(id), str(looks.get("bg", "night")) == id,
			BACKGROUNDS[id][2], func() -> void: _set_look(page, {"bg": id}))))


static func _grid_with(ids: Array, make: Callable) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for id: String in ids:
		grid.add_child(make.call(id))
	return grid


## Grava a escolha (campos de `PUT /pocao/looks`) no servidor e remonta a aba aberta.
static func _set_look(page: PageView, choice: Dictionary) -> void:
	var res: Dictionary = await Server.call_api("PUT", "/pocao/looks", choice)
	if not res.ok:
		if is_instance_valid(page):
			page.body.add_child(_note(ApiClient.error_text(res)))
		return
	var l: Variant = GameState.extras.get("looks")
	if l is Dictionary:
		l.merge(choice, true)
	GameState.progress_changed.emit()
	if is_instance_valid(page):
		page.show_tab(page.tab)


## Quadradinho de um frasco, moldura ou fundo: prévia, nome e "usando", "ganho" ou como ganhar.
## `toggle`: tocar no que está em uso tira (moldura).
static func _look_tile(title: String, preview: Control, have: bool, chosen: bool, how: String, pick: Callable, toggle: bool = false) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(186, 250)
	b.focus_mode = Control.FOCUS_NONE
	b.set_meta("label", title)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color.WHITE if have else LOCKED_TILE
		st.border_color = GameStyle.GOLD if chosen else (GameStyle.INK if have else Color(GameStyle.INK, 0.35))
		st.set_border_width_all(6 if chosen else 4)
		st.set_corner_radius_all(20)
		b.add_theme_stylebox_override(state, st)
	b.disabled = not have
	if have and (toggle or not chosen):
		b.pressed.connect(pick)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 10
	v.offset_bottom = -10
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.modulate = Color.WHITE if have else Color(1, 1, 1, 0.45)
	v.add_child(preview)
	v.add_child(GameStyle.make_label(title, 20, true, GameStyle.INK if have else Color(GameStyle.INK, 0.55)))
	var status := GameStyle.make_label(I18n.t("usando") if chosen else (I18n.t("ganho") if have else emoji_text(how)), 18, true,
		GameStyle.ACCENT if chosen else (Color("2f9a1a") if have else Color(GameStyle.INK, 0.6)))
	status.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	v.add_child(status)
	_ignore_mouse(v)
	return b


static func _ignore_mouse(node: Node) -> void:
	for c in node.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(c)


static func _skin_preview(id: String) -> Control:
	var center := CenterContainer.new()
	var bottle := BottleView.new()
	bottle.set_bottle_width(46.0)
	bottle.skin = id
	bottle.segments = BottleView.segments_from([0, 1, 4], [false, false, false])
	center.add_child(bottle)
	return center


## Prévia da moldura: "Você" dentro de uma faixa com a borda da cor dela.
static func _frame_preview(color: Color) -> Control:
	var center := CenterContainer.new()
	center.add_child(framed(GameStyle.make_label("Você", 22, true), color, Color("f6ead6")))
	return center


## Põe `inner` dentro de uma faixa arredondada com borda `edge` (a moldura do apelido; transparente = borda fina escura).
static func framed(inner: Control, edge: Color, bg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = edge if edge.a > 0 else GameStyle.INK
	st.set_border_width_all(6 if edge.a > 0 else 4)
	st.set_corner_radius_all(30)
	st.content_margin_left = 16
	st.content_margin_right = 16
	st.content_margin_top = 6
	st.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", st)
	p.add_child(inner)
	return p


static func _bg_preview(kind: String, have: bool) -> Control:
	if not have:
		var lock := GameStyle.make_label("🔒", 44)
		lock.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		lock.custom_minimum_size = Vector2(0, 120)
		lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		return lock
	var tex := TextureRect.new()
	tex.texture = load(SceneBackground.ART.get(kind, SceneBackground.ART.night))
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex.custom_minimum_size = Vector2(0, 120)
	return tex


static func _note(text: String) -> Label:
	var l := GameStyle.make_label(text, 22, false, Color(GameStyle.INK, 0.7))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


# ---------- vitória ----------

## Faixas da vitória (duelo, conquista nova, ajuda grátis, prêmio do evento). `extras` = PocaoResult.extras.
static func win_lines(extras: Variant) -> Array[String]:
	var out: Array[String] = []
	if not extras is Dictionary:
		return out
	var e: Dictionary = extras
	var duel: Variant = e.get("duel")
	if duel is Dictionary:
		out.append("⚔️ " + (I18n.t("Você venceu o duelo!") if bool(duel.get("won", false)) else
			I18n.t("Seu amigo fez em %d jogadas. Não foi desta vez!") % int(duel.get("rivalMoves", 0))))
	for id in e.get("achievements", []):
		out.append("🏅 " + I18n.t("Nova conquista: %s") % achievement_name(str(id)))
	# ajudas grátis ganhas agora, com o motivo (`gifts` do servidor)
	for g in e.get("gifts", []):
		match str(g):
			"streak":
				out.append("🎁 " + I18n.t("%d dias seguidos: ganhou uma ajuda grátis!") % int(e.get("streak", 0)))
			"comeback":
				out.append("🎁 " + I18n.t("Que bom te ver de volta! Ganhou uma ajuda grátis."))
			"exact_run":
				out.append("🎁 " + I18n.t("3 vitórias exatas seguidas: ganhou uma ajuda grátis!"))
	var reward := {"boost": "🎁 Prêmio do evento: uma ajuda grátis!", "skin": "🧪 Prêmio do evento: um frasco novo!",
		"frame": "👑 Prêmio do evento: uma moldura nova!", "bg": "🎉 Prêmio do evento: um fundo novo!"}
	var kind := str(e.get("eventReward", ""))
	if reward.has(kind):
		out.append(emoji_text(reward[kind]))
	return out


## Traduz um texto que começa com um emoji ("🔥 30 dias"): o emoji fica e o resto vai para o idioma do jogo.
static func emoji_text(text: String) -> String:
	var at := text.find(" ")
	if at <= 0 or text.unicode_at(0) < 0x2190:
		return I18n.t(text)
	return text.left(at) + " " + I18n.t(text.substr(at + 1))


## Cartão da vitória: "Jogadas exatas: 14 de 14", "+28" grande, "pontos no ranking do mês", um aviso e as faixas.
## `counts` = a fase vale pontos (o duelo não vale).
static func win_card(points: int, used: int, par: int, counts: bool, lines: Array[String], note: String = "") -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var moves_text := I18n.t("Jogadas exatas: %d de %d") % [used, par] if used <= par else I18n.t("Jogadas: %d (exato: %d)") % [used, par]
	var moves := GameStyle.make_label(moves_text, 26, true, Color(GameStyle.INK, 0.8))
	moves.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	box.add_child(moves)
	if counts:
		var pts := GameStyle.make_label("+%d" % points, 84, true, GameStyle.ACCENT)
		pts.name = "Points"
		pts.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		pts.add_theme_font_override("font", GameStyle.title_font())
		box.add_child(pts)
		box.add_child(GameStyle.make_label("pontos no ranking do mês", 22, false, Color(GameStyle.INK, 0.7)))
	if not note.is_empty():
		var n := _note(note)
		n.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		box.add_child(n)
	for line in lines:
		box.add_child(chip(line))
	return box


## Faixa arredondada com borda escura (ex.: "🏅 Nova conquista: Mão certeira").
static func chip(text: String) -> Control:
	var center := CenterContainer.new()
	var l := GameStyle.make_label(text, 22, true)
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	center.add_child(framed(l, Color(0, 0, 0, 0), Color("fff9ee")))
	return center


# ---------- duelo ----------

## Cria o duelo da partida resolvida e abre o "compartilhar" com o link. `back` = volta para a janela de antes.
static func share_duel(dialog: DialogBox, match_id: String, moves: int, back: Callable) -> void:
	dialog.open("Carregando…", "", [])
	var res: Dictionary = await Server.call_api("POST", "/pocao/duels", {"matchId": match_id})
	if not res.ok:
		dialog.open("Ops!", I18n.t(ApiClient.error_text(res)), [["Voltar", back, true]])
		return
	var link := DUEL_URL % str(res.data.get("code", ""))
	var text := I18n.t("Fiz esta fase do Poção de Cores em %d jogadas. Consegue fazer em menos?") % moves + "\n" + link
	Server.track("duel_shared")
	Prizes.share_text(dialog, text, "Duelo copiado", "O link foi copiado. Cole numa conversa para desafiar um amigo.", back)


## Duelo recebido por link: o cartão "Ana VS Você" com a fase. `play` = Callable(code) que abre a fase.
static func open_duel(dialog: DialogBox, code: String, play: Callable) -> void:
	dialog.open("Carregando…", "", [])
	var res: Dictionary = await Server.call_api("GET", "/pocao/duels/%s" % code.uri_encode())
	if not res.ok:
		dialog.open("Duelo", I18n.t(ApiClient.error_text(res)), [["Fechar", func() -> void: pass, true]])
		return
	var d: Dictionary = res.data
	if bool(d.get("mine", false)):
		dialog.open("Duelo", I18n.t("Este duelo é seu. Mande o link para um amigo."), [["Fechar", func() -> void: pass, true]])
		return
	if bool(d.get("expired", false)):
		dialog.open("Duelo", I18n.t("Este duelo já acabou."), [["Fechar", func() -> void: pass, true]])
		return
	var creator := str(d.get("creator", ""))
	var text := I18n.t("%s te desafiou na mesma fase. Faça com menos jogadas para ganhar.") % creator
	var played: Variant = d.get("played")
	if played is Dictionary:
		text += "\n" + (I18n.t("Você já venceu este duelo.") if bool(played.get("won", false)) else I18n.t("Você já tentou. Pode jogar de novo."))
	text += "\n" + I18n.t("O duelo não vale pontos no ranking.")
	dialog.open_hero("Duelo!", text, [
		["Aceitar duelo", func() -> void: play.call(code), true],
		["Agora não", func() -> void: pass],
	])
	dialog.add_content(_versus(creator, int(d.get("creatorMoves", 0))))
	var tubes: Array = d.get("tubes", [])
	if not tubes.is_empty():
		dialog.add_content(_mini_bottles(tubes))


## "A  VS  ?": quem desafiou (com as jogadas) e você (sua vez).
static func _versus(creator: String, moves: int) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	row.add_child(_player(creator.left(1).to_upper(), Color("e04fa0"), creator, I18n.t("%d jogadas") % moves))
	var vs := GameStyle.make_title("VS", 52, GameStyle.PURPLE)
	vs.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	row.add_child(vs)
	row.add_child(_player("?", GameStyle.PURPLE, I18n.t("Você"), I18n.t("sua vez")))
	return row


static func _player(letter: String, color: Color, name: String, sub: String) -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(150, 0)
	col.add_theme_constant_override("separation", 2)
	var avatar := Medal.new(letter, true, false, color)
	avatar.letter = true
	col.add_child(avatar)
	var n := GameStyle.make_label(name, 24, true)
	n.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(n)
	var s := GameStyle.make_label(sub, 20, true, GameStyle.ACCENT)
	s.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	col.add_child(s)
	return col


## Prévia da fase do duelo: os primeiros frascos lado a lado.
static func _mini_bottles(tubes: Array) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for t: Array in tubes.slice(0, 6):
		var b := BottleView.new()
		b.set_bottle_width(46.0)
		var hidden: Array = []
		hidden.resize(t.size())
		hidden.fill(false)
		b.segments = BottleView.segments_from(t, hidden)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(b)
	return row


# ---------- desenhos ----------

## Três estrelas (cheias até `count`), lado a lado.
class StarsView extends Control:
	var count: int = 0
	var total: int = 3
	var radius: float = 24.0

	func _init(filled: int = 0, of: int = 3, r: float = 24.0) -> void:
		count = filled
		total = of
		radius = r
		custom_minimum_size = Vector2(total * r * 2.2, r * 2.2)
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var step := size.x / total
		for i in total:
			GameStyle.draw_star(self, Vector2(step * (i + 0.5), size.y * 0.5), radius, i < count)


## Medalha redonda com um emoji (ou uma letra, `letter`): colorida quando ganha, cinza quando não; borda dourada
## quando é o selo escolhido.
class Medal extends Control:
	const PALETTE := [Color("ffc72e"), Color("7fb2ff"), Color("ff8fd0"), Color("ff9a2e"), Color("8be08a"), Color("b99bff")]
	var icon: String
	var on: bool
	var chosen: bool
	var color: Color
	var letter: bool = false

	func _init(text: String, unlocked: bool, is_chosen: bool = false, fill: Color = Color(0, 0, 0, 0)) -> void:
		icon = text
		on = unlocked
		chosen = is_chosen
		color = fill
		custom_minimum_size = Vector2(0, 112)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, 56)
		var fill := color
		if fill.a == 0:
			fill = PALETTE[absi(icon.hash()) % PALETTE.size()] if on else Color("dcd6cc")
		draw_circle(c, 53, GameStyle.GOLD if chosen else GameStyle.INK)
		draw_circle(c, 45 if chosen else 48, fill)
		draw_circle(c + Vector2(-14, -16), 14, Color(1, 1, 1, 0.3 if on else 0.15))
		var font := GameStyle.title_font() if letter else GameStyle.body_font()
		var fs := 50 if letter else 44
		var w := font.get_string_size(icon, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, c + Vector2(-w * 0.5, fs * 0.36), icon, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color.WHITE if on else Color(1, 1, 1, 0.45))


## Barrinha de progresso roxa.
class ProgressLine extends Control:
	var value: float

	func _init(v: float) -> void:
		value = clampf(v, 0.0, 1.0)
		custom_minimum_size = Vector2(0, 14)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := minf(size.x, 120.0)
		var x := (size.x - w) * 0.5
		draw_rect(Rect2(x, 0, w, size.y), Color("e4dcf5"))
		if value > 0:
			draw_rect(Rect2(x, 0, maxf(size.y, w * value), size.y), GameStyle.PURPLE)


## Chamazinha da sequência de dias.
class FlameIcon extends Control:
	var lit: bool = true

	func _init(r: float = 22.0) -> void:
		custom_minimum_size = Vector2(r * 2, r * 2.4)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var outer := _flame(Vector2(w * 0.5, h), w * 0.48, h * 0.95)
		var inner := _flame(Vector2(w * 0.5, h * 0.98), w * 0.26, h * 0.55)
		draw_colored_polygon(outer, Color("ff6a1f") if lit else Color("8d8aa6"))
		draw_colored_polygon(inner, Color("ffd23f") if lit else Color("c9c6dc"))
		var ring := outer.duplicate()
		ring.append(outer[0])
		draw_polyline(ring, GameStyle.INK, 3.0, true)

	## Gota de fogo: meia-lua redonda embaixo e ponta em cima.
	static func _flame(base: Vector2, half: float, height: float) -> PackedVector2Array:
		var c := Vector2(base.x, base.y - half)
		var p := PackedVector2Array([Vector2(base.x + half * 0.15, base.y - height)])
		for i in 17:
			var a := -PI / 6.0 + (PI + PI / 3.0) * i / 16.0
			p.append(c + Vector2(cos(a), sin(a)) * half)
		return p
