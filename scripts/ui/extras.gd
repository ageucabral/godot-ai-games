class_name Extras
extends RefCounted
## As ideias novas do Poção de Cores (Ageu, 9/11/2026): sequência de dias, estrelas, conquistas, frascos e fundos,
## duelo com amigo e eventos. Janelas e desenhos pequenos usados pelo menu, pela partida e pela engrenagem.
## Os números vêm do servidor (`GameState.extras`); sem servidor só a sequência e as estrelas funcionam.

## Conquistas (ids do servidor): [nome, como ganhar].
const ACHIEVEMENTS := {
	"first_win": ["Primeira poção", "Resolva sua primeira fase."],
	"exact_10": ["Mão certeira", "Resolva 10 fases no número exato de jogadas."],
	"exact_50": ["Alquimista perfeito", "Resolva 50 fases no número exato de jogadas."],
	"level_25": ["Aprendiz", "Chegue ao nível 25."],
	"level_50": ["Mestre das poções", "Chegue ao nível 50."],
	"level_100": ["Lenda do laboratório", "Chegue ao nível 100."],
	"streak_7": ["Uma semana seguida", "Jogue 7 dias seguidos."],
	"streak_30": ["Um mês seguido", "Jogue 30 dias seguidos."],
	"daily_all": ["Dia completo", "Resolva os 20 desafios de um dia."],
	"daily_100": ["Cem desafios", "Resolva 100 desafios do dia."],
	"invite_3": ["Turma reunida", "Convide 3 amigos que joguem."],
	"top_100": ["Entre os 100", "Fique entre os 100 primeiros do Ranking Global."],
	"duel_1": ["Primeiro duelo", "Vença um duelo com um amigo."],
	"duel_5": ["Duelista", "Vença 5 duelos."],
	"league_up": ["Subiu de liga", "Suba de liga na Liga da semana."],
	"event_1": ["Festeiro", "Complete um evento."],
}
## Frascos: nome e a conquista que libera ("" = sempre).
const SKINS := {"classic": ["Clássico", ""], "tube": ["Tubo de ensaio", "exact_10"], "cauldron": ["Balão redondo", "level_25"],
	"heart": ["Coração", "streak_30"], "golden": ["Dourado", "top_100"], "crystal": ["Cristal", "league_up"]}
## Fundos da partida: [nome, como liberar, fundo da tela (SceneBackground)].
const BACKGROUNDS := {"night": ["Noite estrelada", "", "night"], "sunset": ["Pôr do sol", "streak_7", "sky"],
	"sky": ["Céu de dia", "daily_all", "day"], "event:halloween": ["Halloween", "event", "halloween"],
	"event:natal": ["Natal", "event", "natal"], "event:carnaval": ["Carnaval", "event", "carnaval"]}
## Nome de cada liga (0 = a primeira).
const LEAGUES: Array[String] = ["Liga Bronze", "Liga Prata", "Liga Ouro", "Liga Safira", "Liga Diamante"]
## Cor de cada tema de evento (botão do menu).
const EVENT_COLORS := {"halloween": Color("ff7a1f"), "natal": Color("e0303f"), "carnaval": Color("e04fd0")}
## Endereço do link do duelo (a página abre o app ou a Play).
const DUEL_URL := "https://nalatagame.tech/duelo/%s"


## Fundo da partida (SceneBackground) do visual escolhido.
static func background_kind(bg: String) -> String:
	return BACKGROUNDS[bg][2] if BACKGROUNDS.has(bg) else "night"


## Liga pelo número (o servidor manda de 0 a 4).
static func league_name(tier: int) -> String:
	return LEAGUES[clampi(tier, 0, LEAGUES.size() - 1)]


## Nome da conquista no idioma do jogo.
static func achievement_name(id: String) -> String:
	return I18n.t(ACHIEVEMENTS[id][0]) if ACHIEVEMENTS.has(id) else id


## Código do duelo num link (nalata://duelo/ABC123, https://nalatagame.tech/duelo/ABC123) ou no texto do
## referrer da Play ("duel=ABC123"). "" se não tiver.
static func duel_code_from(text: String) -> String:
	var t := text.strip_edges()
	var at := t.find("duelo/")
	if at >= 0:
		return _clean_code(t.substr(at + 6))
	for part in t.uri_decode().split("&"):
		var kv := part.split("=", true, 1)
		if kv.size() == 2 and kv[0].strip_edges() == "duel":
			return _clean_code(kv[1])
	return ""


static func _clean_code(raw: String) -> String:
	var out := ""
	for c in raw.strip_edges().to_upper():
		if (c >= "A" and c <= "Z") or (c >= "0" and c <= "9"):
			out += c
		else:
			break
	return out if out.length() >= 4 else ""


# ---------- sequência de dias ----------

static func open_streak(dialog: DialogBox) -> void:
	var s := GameState.streak()
	var text := I18n.t("Resolva pelo menos uma fase por dia para manter a sequência.") + "\n\n"
	text += I18n.t("Dia 3 e dia 5: uma ajuda grátis (sem propaganda).\nDia 7: o fundo Pôr do sol.\nDia 30: o frasco Coração.")
	if int(s.free_boosts) > 0:
		text += "\n\n" + I18n.t("Ajudas grátis guardadas: %d") % int(s.free_boosts)
	if int(s.best) > int(s.count):
		text += "\n" + I18n.t("Seu recorde: %d dias") % int(s.best)
	dialog.open(I18n.t("%d dias seguidos") % int(s.count), text, [["Fechar", func() -> void: pass, true]])


# ---------- conquistas, frascos e fundos ----------

## Conquistas: lista com o progresso de cada uma (as feitas em cima).
static func open_achievements(dialog: DialogBox) -> void:
	var list: Array = GameState.extras.get("achievements", [])
	var done := 0
	for a in list:
		if bool(a.get("unlocked", false)):
			done += 1
	dialog.open("Conquistas", I18n.t("%d de %d") % [done, ACHIEVEMENTS.size()] if not list.is_empty() else I18n.t("As conquistas aparecem jogando pelo app da Play Store."), [
		["Meus frascos", func() -> void: open_looks(dialog)],
		["Fechar", func() -> void: pass, true],
	])
	if list.is_empty():
		return
	var sorted := list.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return bool(a.get("unlocked")) and not bool(b.get("unlocked")))
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	for a: Dictionary in sorted:
		rows.add_child(_achievement_row(a))
	dialog.add_content(_scroll(rows, 620))


static func _achievement_row(a: Dictionary) -> Control:
	var id := str(a.get("id", ""))
	var unlocked := bool(a.get("unlocked", false))
	var panel := PanelContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("f3e6ff") if unlocked else Color("efe9df")
	bg.set_corner_radius_all(16)
	bg.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", bg)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var medal := StarsView.new(1 if unlocked else 0, 1, 26.0)
	row.add_child(medal)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", -2)
	row.add_child(text)
	var info: Array = ACHIEVEMENTS.get(id, [id, ""])
	var name := GameStyle.make_label(info[0], 26, true, GameStyle.INK if unlocked else Color(GameStyle.INK, 0.6))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text.add_child(name)
	var how := GameStyle.make_label(info[1], 20, false, Color(GameStyle.INK, 0.7))
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(how)
	var goal := int(a.get("goal", 1))
	if not unlocked and goal > 1:
		var prog := GameStyle.make_label("%d/%d" % [int(a.get("value", 0)), goal], 22, true, GameStyle.ACCENT)
		prog.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		row.add_child(prog)
	return panel


## Meus frascos: escolhe o frasco e o fundo da partida entre os liberados.
static func open_looks(dialog: DialogBox, error: String = "") -> void:
	var looks := GameState.looks()
	dialog.open("Meus frascos", error if not error.is_empty() else I18n.t("Toque para usar. Os outros saem com conquistas e eventos."), [
		["Conquistas", func() -> void: open_achievements(dialog)],
		["Fechar", func() -> void: pass, true],
	])
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.add_child(GameStyle.make_label("Frasco", 26, true, GameStyle.ACCENT))
	var skins := GridContainer.new()
	skins.columns = 3
	skins.add_theme_constant_override("h_separation", 10)
	skins.add_theme_constant_override("v_separation", 10)
	box.add_child(skins)
	for id: String in SKINS:
		var have: bool = (looks.get("skins", []) as Array).has(id)
		skins.add_child(_look_tile(SKINS[id][0], _skin_preview(id), have, str(looks.get("skin", "")) == id,
			func() -> void: _set_look(dialog, {"skin": id, "bg": str(looks.get("bg", "night"))})))
	box.add_child(GameStyle.make_label("Fundo da partida", 26, true, GameStyle.ACCENT))
	var bgs := GridContainer.new()
	bgs.columns = 3
	bgs.add_theme_constant_override("h_separation", 10)
	bgs.add_theme_constant_override("v_separation", 10)
	box.add_child(bgs)
	for id: String in BACKGROUNDS:
		var have: bool = (looks.get("backgrounds", []) as Array).has(id)
		if id.begins_with("event:") and not have:
			continue  # fundos de evento só aparecem depois de ganhos
		bgs.add_child(_look_tile(BACKGROUNDS[id][0], _bg_preview(BACKGROUNDS[id][2]), have, str(looks.get("bg", "")) == id,
			func() -> void: _set_look(dialog, {"skin": str(looks.get("skin", "classic")), "bg": id})))
	dialog.add_content(_scroll(box, 640))


static func _set_look(dialog: DialogBox, choice: Dictionary) -> void:
	var res: Dictionary = await Server.call_api("PUT", "/pocao/looks", choice)
	if not res.ok:
		open_looks(dialog, I18n.t(ApiClient.error_text(res)))
		return
	var l: Variant = GameState.extras.get("looks")
	if l is Dictionary:
		l["skin"] = choice.skin
		l["bg"] = choice.bg
	GameState.progress_changed.emit()
	open_looks(dialog)


## Quadradinho de um frasco ou fundo: prévia, nome e um cadeado se ainda não foi liberado.
static func _look_tile(title: String, preview: Control, have: bool, chosen: bool, pick: Callable) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(160, 200)
	b.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "disabled"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color("f3e6ff") if chosen else Color("efe9df")
		st.border_color = GameStyle.ACCENT if chosen else Color(GameStyle.INK, 0.25)
		st.set_border_width_all(4 if chosen else 2)
		st.set_corner_radius_all(18)
		b.add_theme_stylebox_override(state, st)
	b.disabled = not have
	if have and not chosen:
		b.pressed.connect(pick)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 8
	v.offset_bottom = -8
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate = Color.WHITE if have else Color(1, 1, 1, 0.35)
	v.add_child(preview)
	var name := GameStyle.make_label(title, 18, true, GameStyle.INK if have else Color(GameStyle.INK, 0.5))
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name)
	return b


static func _skin_preview(id: String) -> Control:
	var center := CenterContainer.new()
	var bottle := BottleView.new()
	bottle.set_bottle_width(56.0)
	bottle.skin = id
	bottle.segments = BottleView.segments_from([0, 1, 4], [false, false, false])
	bottle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(bottle)
	return center


static func _bg_preview(kind: String) -> Control:
	var tex := TextureRect.new()
	tex.texture = load(SceneBackground.ART.get(kind, SceneBackground.ART.night))
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex.custom_minimum_size = Vector2(0, 130)
	return tex


static func _scroll(content: Control, height: float) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, height)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	return scroll


# ---------- vitória ----------

## Linhas extras da vitória (sequência, ajuda grátis, conquistas novas, duelo). `extras` = PocaoResult.extras.
static func win_lines(extras: Variant) -> Array[String]:
	var out: Array[String] = []
	if not extras is Dictionary:
		return out
	var e: Dictionary = extras
	var duel: Variant = e.get("duel")
	if duel is Dictionary:
		out.append(I18n.t("Você venceu o duelo!") if bool(duel.get("won", false)) else
			I18n.t("Seu amigo fez em %d jogadas. Não foi desta vez!") % int(duel.get("rivalMoves", 0)))
	if int(e.get("freeBoostsGained", 0)) > 0:
		out.append(I18n.t("%d dias seguidos: ganhou uma ajuda grátis!") % int(e.get("streak", 0)))
	for id in e.get("achievements", []):
		out.append(I18n.t("Conquista nova: %s") % achievement_name(str(id)))
	return out


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
	var plugin := Server.native_with("install_referrer")
	if plugin != null:
		plugin.share(text)
		back.call()
		return
	DisplayServer.clipboard_set(text)
	dialog.open("Duelo copiado", I18n.t("O link foi copiado. Cole numa conversa para desafiar um amigo."), [["Ok", back, true]])


## Duelo recebido por link: mostra quem desafiou e o número a bater. `play` = Callable(code) que abre a fase.
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
	var text := I18n.t("%s fez esta fase em %d jogadas. Consegue fazer em menos?\nO duelo não vale pontos no ranking.") % [
		str(d.get("creator", "")), int(d.get("creatorMoves", 0))]
	var played: Variant = d.get("played")
	if played is Dictionary:
		text += "\n\n" + (I18n.t("Você já venceu este duelo.") if bool(played.get("won", false)) else I18n.t("Você já tentou. Pode jogar de novo."))
	dialog.open("Desafio de amigo", text, [
		["Aceitar o duelo", func() -> void: play.call(code), true],
		["Agora não", func() -> void: pass],
	])


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
			var c := Vector2(step * (i + 0.5), size.y * 0.5)
			var pts := GameStyle.star_points(c, radius, radius * 0.48, 5)
			var ring := pts.duplicate()
			ring.append(pts[0])
			draw_colored_polygon(pts, GameStyle.GOLD if i < count else Color(0, 0, 0, 0.18))
			draw_polyline(ring, GameStyle.INK, maxf(2.0, radius * 0.14), true)


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
