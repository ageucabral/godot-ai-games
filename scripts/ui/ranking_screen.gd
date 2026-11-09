class_name RankingScreen
extends Control
## Ranking Global do Na Lata: soma os pontos de todos os jogos do mês e é o que vale prêmios.
## É o único ranking (Ageu, 9/11/2026): o botão de ranking de cada jogo também abre este.
## A página inteira rola: cabeçalho, cartão "Você", prêmios do mês, a lista dos jogadores e as regras.
## Jogando pelo servidor mostra a posição e a lista do mês; sem servidor, só os pontos deste aparelho.

signal back_requested
signal invite_requested
signal claim_requested(payout_id: String)
signal prizes_requested

const MEDALS := [Color("ffc72e"), Color("c9d3e0"), Color("e3955a")]
const ME_COLOR := Color("7d43e8")
const ROW_ALT := Color("f6ead6")

var title_label: Label
var subtitle_label: Label
var position_label: Label
var points_label: Label
var detail_label: Label
var prize_card: PanelContainer
var prize_list: GridContainer
var top_card: PanelContainer
var top_list: VBoxContainer
var info_label: Label
var claim_button: GlossButton
var invite_button: GlossButton
var prizes_button: GlossButton
## Do GET /ranking: linhas [posição, apelido, pontos, sou_eu], faixas de prêmio e regra do jogador.
var rows: Array = []
var prizes: Array = []
var me: Dictionary = {}


func _ready() -> void:
	theme = GameStyle.build_theme()
	GameStyle.add_background(self, "night")
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 60)
	scroll.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_theme_constant_override("separation", 20)
	margin.add_child(box)

	# cabeçalho: voltar, título e o mês
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(head)
	var back := GameStyle.make_button("Voltar", false, 26)
	back.pressed.connect(func() -> void: back_requested.emit())
	head.add_child(back)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	head.add_child(spacer)
	title_label = GameStyle.make_title("Ranking Global", 48, GameStyle.GOLD)
	box.add_child(title_label)
	subtitle_label = GameStyle.make_label("", 24, false, Color(1, 1, 1, 0.85))
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(subtitle_label)

	# cartão "Você": posição grande à esquerda, pontos e o que falta à direita
	var me_card := _card(Color("e0662f"))
	box.add_child(me_card)
	var me_row := HBoxContainer.new()
	me_row.mouse_filter = Control.MOUSE_FILTER_PASS
	me_row.add_theme_constant_override("separation", 20)
	me_card.add_child(me_row)
	position_label = GameStyle.make_title("", 60)
	position_label.custom_minimum_size = Vector2(150, 0)
	position_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	me_row.add_child(position_label)
	var me_text := VBoxContainer.new()
	me_text.mouse_filter = Control.MOUSE_FILTER_PASS
	me_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	me_text.alignment = BoxContainer.ALIGNMENT_CENTER
	me_row.add_child(me_text)
	points_label = GameStyle.make_title("", 44)
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	me_text.add_child(points_label)
	detail_label = GameStyle.make_label("", 24, false, Color.WHITE)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	me_text.add_child(detail_label)

	# resgatar (só com um prêmio esperando os dados)
	claim_button = GameStyle.make_button("Resgatar prêmio", true, 32, GameStyle.GOLD)
	claim_button.pulse = true
	claim_button.pressed.connect(func() -> void:
		var pending := Prizes.pending_payouts()
		if not pending.is_empty():
			claim_requested.emit(str(pending[0].get("id", ""))))
	box.add_child(claim_button)

	# prêmios do mês: pílulas lado a lado (posição em cima, valor embaixo)
	prize_card = _card(GameStyle.GOLD)
	(prize_card.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(12)
	box.add_child(prize_card)
	var prize_box := VBoxContainer.new()
	prize_box.mouse_filter = Control.MOUSE_FILTER_PASS
	prize_box.add_theme_constant_override("separation", 8)
	prize_card.add_child(prize_box)
	prize_box.add_child(GameStyle.make_label("Prêmios do mês", 24, true, GameStyle.INK))
	prize_list = GridContainer.new()
	prize_list.columns = 4
	prize_list.mouse_filter = Control.MOUSE_FILTER_PASS
	prize_list.add_theme_constant_override("h_separation", 8)
	prize_list.add_theme_constant_override("v_separation", 8)
	prize_box.add_child(prize_list)

	# a lista do mês (rola junto com a página)
	top_card = _card(GameStyle.PAPER)
	box.add_child(top_card)
	top_list = VBoxContainer.new()
	top_list.mouse_filter = Control.MOUSE_FILTER_PASS
	top_list.add_theme_constant_override("separation", 4)
	top_card.add_child(top_list)

	# como concorrer: regra, desempate e os botões
	var info := _card(GameStyle.PAPER)
	box.add_child(info)
	var info_box := VBoxContainer.new()
	info_box.mouse_filter = Control.MOUSE_FILTER_PASS
	info_box.add_theme_constant_override("separation", 14)
	info.add_child(info_box)
	info_box.add_child(GameStyle.make_label("Como ganhar", 28, true, GameStyle.ACCENT))
	info_label = GameStyle.make_label("", 24)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_box.add_child(info_label)
	invite_button = GameStyle.make_button("Convidar amigos", false, 28)
	invite_button.pressed.connect(func() -> void: invite_requested.emit())
	info_box.add_child(invite_button)
	prizes_button = GameStyle.make_button("Meus prêmios", false, 28, Color("e0662f"))
	prizes_button.pressed.connect(func() -> void: prizes_requested.emit())
	info_box.add_child(prizes_button)

	GameState.progress_changed.connect(refresh)
	refresh()


## Cartão arredondado de uma cor; deixa o arrasto passar para a página rolar.
func _card(color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var b := GameStyle.card_box()
	b.bg_color = color
	b.set_content_margin_all(20)
	card.add_theme_stylebox_override("panel", b)
	return card


## Abre o ranking e busca a lista do mês no servidor.
func open() -> void:
	refresh()
	if Server.online():
		_fetch()


func _fetch() -> void:
	var res: Dictionary = await Server.call_api("GET", "/ranking")
	if not res.ok or not is_inside_tree():
		return
	rows = ApiClient.ranking_rows(res.data)
	prizes = res.data.get("prizes") if res.data.get("prizes") is Array else []
	me = res.data.get("me") if res.data.get("me") is Dictionary else {}
	refresh()


func refresh() -> void:
	var now := GameState.now_unix()
	var month := Rules.month_for(now)
	subtitle_label.text = tr("%s · termina em %d dias · zera no dia 1") % [Rules.month_name(month), Rules.days_left_in_month(now)]
	var total := GameState.global_month_total(month)
	points_label.text = tr("%d pts") % total.points
	var position: Variant = total.get("position")
	if position != null:
		position_label.text = "%dº" % int(position)
		detail_label.text = gap_text(rows, position)
	else:
		position_label.text = "–"
		if total.points > 0:
			detail_label.text = tr("%d jogadas no mês") % total.moves  # sem servidor (Web): sem posição
		else:
			detail_label.text = tr("Jogue para entrar no ranking")
	var online := Server.online()
	claim_button.visible = online and not Prizes.pending_payouts().is_empty()
	invite_button.visible = online
	prizes_button.visible = online and not Server.is_guest()
	_fill_prizes()
	_fill_top()
	var lines: Array[String] = []
	var rule := ApiClient.rule_text(me, Server.config.get("rules", {}))
	if not rule.is_empty():
		lines.append(rule)
	lines.append(tr("Empate: fica na frente quem usou menos jogadas."))
	if not Server.enabled:
		lines.append(tr("A lista com todos os jogadores está no app da Play Store."))
	info_label.text = "\n\n".join(lines)


## Quanto falta para subir uma posição ("Faltam 3 pts para o 9º"); no 1º lugar, um parabéns.
static func gap_text(list: Array, position: Variant) -> String:
	var pos := int(position)
	if pos == 1:
		return TranslationServer.translate("Você está na frente!")
	var mine := -1
	var above := -1
	for r in list:
		if int(r[0]) == pos - 1:
			above = int(r[2])
		if r[3]:
			mine = int(r[2])
	if above < 0 or mine < 0:
		return TranslationServer.translate("Jogue mais para subir")
	return TranslationServer.translate("Faltam %d pts para o %dº") % [maxi(1, above - mine + 1), pos - 1]


func _fill_prizes() -> void:
	for c in prize_list.get_children():
		c.queue_free()
	var chips := ApiClient.prize_chips(prizes)
	prize_card.visible = not chips.is_empty()
	prize_list.columns = clampi(chips.size(), 1, 4)
	for c in chips:
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var b := StyleBoxFlat.new()
		b.bg_color = GameStyle.CREAM
		b.set_corner_radius_all(16)
		b.set_content_margin_all(6)
		chip.add_theme_stylebox_override("panel", b)
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_PASS
		v.add_theme_constant_override("separation", -4)
		chip.add_child(v)
		for part in [[c[0], 20, GameStyle.ACCENT], [c[1], 26, GameStyle.INK]]:
			var l := GameStyle.make_label(part[0], part[1], true, part[2])
			l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			v.add_child(l)
		prize_list.add_child(chip)


## Até onde vai o prêmio (a última posição premiada); 0 sem prêmios.
func _last_prize_position() -> int:
	var last := 0
	for p in prizes:
		if p is Dictionary:
			last = maxi(last, int(p.get("posTo", p.get("posFrom", 0))))
	return last


## Uma linha por jogador: medalha nos 3 primeiros, a linha do jogador em roxo e um traço onde acaba o prêmio.
func _fill_top() -> void:
	for c in top_list.get_children():
		c.queue_free()
	top_card.visible = not rows.is_empty()
	var last_prize := _last_prize_position()
	for i in rows.size():
		var r: Array = rows[i]
		top_list.add_child(_row(r, i))
		if last_prize > 0 and int(r[0]) == last_prize and i < rows.size() - 1:
			var cut := GameStyle.make_label("— " + tr("até aqui ganha prêmio") + " —", 20, false, Color(GameStyle.INK, 0.55))
			top_list.add_child(cut)


func _row(r: Array, index: int) -> PanelContainer:
	var mine: bool = r[3]
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var bg := StyleBoxFlat.new()
	if mine:
		bg.bg_color = ME_COLOR
	elif index % 2 == 0:
		bg.bg_color = ROW_ALT
	else:
		bg.bg_color = Color(0, 0, 0, 0)
	bg.set_corner_radius_all(16)
	bg.content_margin_left = 12
	bg.content_margin_right = 16
	bg.content_margin_top = 8
	bg.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", bg)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var color: Color = Color.WHITE if mine else GameStyle.INK
	var pos := int(r[0])
	var badge := RankBadge.new()
	badge.position_number = pos
	badge.medal = MEDALS[pos - 1] if pos >= 1 and pos <= 3 else Color(0, 0, 0, 0)
	badge.text_color = color
	row.add_child(badge)
	var nick := GameStyle.make_label(tr("Você") if mine else str(r[1]), 26, mine, color)
	nick.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	nick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nick.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if not mine:
		nick.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	row.add_child(nick)
	var move := DeltaMark.new()
	move.delta = r[4] if r.size() > 4 else null
	move.on_dark = mine
	row.add_child(move)
	var pts := GameStyle.make_label(tr("%d pts") % r[2], 26, true, color)
	pts.custom_minimum_size = Vector2(140, 0)  # coluna fixa: as setas ficam alinhadas
	pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pts.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	row.add_child(pts)
	return panel


## Círculo com a posição (dourado, prata e bronze nos 3 primeiros).
class RankBadge extends Control:
	var position_number: int = 0
	var medal: Color = Color(0, 0, 0, 0)
	var text_color: Color = GameStyle.INK

	func _init() -> void:
		custom_minimum_size = Vector2(64, 48)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		if medal.a > 0.0:
			draw_circle(c, 23, GameStyle.INK)
			draw_circle(c, 20, medal)
		var font := GameStyle.title_font()
		var s := "%dº" % position_number
		var col := GameStyle.INK if medal.a > 0.0 else text_color
		var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_string(font, Vector2(c.x - w * 0.5, c.y + 9), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, col)


## Quanto o jogador subiu (seta verde) ou caiu (seta vermelha) desde ontem; um traço se ficou igual.
## Sem retrato de ontem (entrou hoje) não mostra nada.
class DeltaMark extends Control:
	const UP := Color("2fa84f")
	const DOWN := Color("e0303f")
	var delta: Variant = null
	var on_dark: bool = false

	func _init() -> void:
		custom_minimum_size = Vector2(64, 40)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if delta == null:
			return
		var d := int(delta)
		var font := GameStyle.title_font()
		var c := Vector2(14, size.y * 0.5)
		if d == 0:
			draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), Color(Color.WHITE if on_dark else GameStyle.INK, 0.5), 4.0)
			return
		var col := UP if d > 0 else DOWN
		if on_dark:
			col = col.lightened(0.35)
		var s := 9.0 if d > 0 else -9.0
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(9, s * 0.8), c + Vector2(-9, s * 0.8)]), col)
		draw_string(font, Vector2(28, size.y * 0.5 + 8), str(absi(d)), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col)
