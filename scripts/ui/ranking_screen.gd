extends Control
## Os dois rankings do mês:
## - "game": o ranking de um jogo só (ex.: Poção de Cores), para o jogador ver como está naquele jogo;
## - "global": o Ranking Global do Na Lata, que soma todos os jogos e é o que vale os prêmios.
## Jogando pelo servidor, mostra a posição e a lista com os primeiros jogadores do mês; sem servidor,
## só os pontos deste aparelho.

signal back_requested

const GLOBAL := "global"
const GAME := "game"
## Lista de jogos do hub: daqui sai o nome mostrado de cada jogo.
const HubScreen := preload("res://scripts/ui/hub_screen.gd")

var mode: String = GAME
var game_id: String = "potion"

var title_label: Label
var subtitle_label: Label
var prize_banner: PanelContainer
var prize_label: Label
var me_box: StyleBoxFlat
var points_label: Label
var detail_label: Label
var games_card: PanelContainer
var games_list: VBoxContainer
var info_label: Label
var top_card: PanelContainer
var top_list: VBoxContainer
## Linhas vindas do servidor para cada ranking ("global" / "game"): [posição, apelido, pontos, sou_eu].
var server_rows: Dictionary = {}


func _ready() -> void:
	theme = GameStyle.build_theme()
	GameStyle.add_background(self, "night")
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 50)
	scroll.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	margin.add_child(box)

	var back := GameStyle.make_button("Voltar", false, 28)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void: back_requested.emit())
	box.add_child(back)
	title_label = GameStyle.make_title("", 50, GameStyle.GOLD)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title_label)
	subtitle_label = GameStyle.make_title("", 26)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(subtitle_label)

	# faixa dourada dos prêmios (só no ranking global)
	prize_banner = PanelContainer.new()
	var prize_box := StyleBoxFlat.new()
	prize_box.bg_color = GameStyle.GOLD
	prize_box.border_color = GameStyle.INK
	prize_box.set_border_width_all(4)
	prize_box.border_width_bottom = 10
	prize_box.set_corner_radius_all(22)
	prize_box.set_content_margin_all(16)
	prize_banner.add_theme_stylebox_override("panel", prize_box)
	box.add_child(prize_banner)
	prize_label = GameStyle.make_label("", 30, true, GameStyle.INK)
	prize_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prize_banner.add_child(prize_label)

	# cartão "Você"
	var me := PanelContainer.new()
	me_box = StyleBoxFlat.new()
	me_box.border_color = GameStyle.INK
	me_box.set_border_width_all(4)
	me_box.border_width_bottom = 10
	me_box.set_corner_radius_all(22)
	me_box.set_content_margin_all(22)
	me.add_theme_stylebox_override("panel", me_box)
	box.add_child(me)
	var me_inner := VBoxContainer.new()
	me.add_child(me_inner)
	me_inner.add_child(GameStyle.make_label("Você", 30, false, Color.WHITE))
	points_label = GameStyle.make_title("", 72)
	me_inner.add_child(points_label)
	detail_label = GameStyle.make_label("", 26, false, Color.WHITE)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	me_inner.add_child(detail_label)

	# os primeiros do mês (só com o servidor)
	top_card = PanelContainer.new()
	top_card.add_theme_stylebox_override("panel", GameStyle.card_box())
	box.add_child(top_card)
	top_list = VBoxContainer.new()
	top_list.add_theme_constant_override("separation", 8)
	top_card.add_child(top_list)

	# pontos de cada jogo (só no ranking global)
	games_card = PanelContainer.new()
	games_card.add_theme_stylebox_override("panel", GameStyle.card_box())
	box.add_child(games_card)
	var games_box := VBoxContainer.new()
	games_box.add_theme_constant_override("separation", 10)
	games_card.add_child(games_box)
	games_box.add_child(GameStyle.make_label("Pontos por jogo", 30, true, GameStyle.ACCENT))
	games_list = VBoxContainer.new()
	games_box.add_child(games_list)

	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", GameStyle.card_box())
	box.add_child(info)
	info_label = GameStyle.make_label("", 26)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(info_label)

	GameState.progress_changed.connect(refresh)
	refresh()


## Escolhe qual ranking mostrar: open_mode(GLOBAL) ou open_mode(GAME, "potion").
func open_mode(new_mode: String, new_game: String = "potion") -> void:
	mode = new_mode
	game_id = new_game
	refresh()
	if Server.online():
		_fetch_rows(new_mode)


## Busca no servidor a lista do ranking (Global: GET /ranking; do jogo: GET /games/<id>/ranking).
func _fetch_rows(which: String) -> void:
	var path := "/ranking" if which == GLOBAL else "/games/%s/ranking" % ApiClient.SERVER_GAME_ID
	var res: Dictionary = await Server.call_api("GET", path)
	if not res.ok or not is_inside_tree():
		return
	server_rows[which] = ApiClient.ranking_rows(res.data)
	if mode == which:
		refresh()


func refresh() -> void:
	var now := GameState.now_unix()
	var month := Rules.month_for(now)
	var month_name := Rules.month_name(month)
	subtitle_label.text = tr("%s · termina em %d dias · zera no dia 1") % [month_name, Rules.days_left_in_month(now)]
	var global := mode == GLOBAL
	_fill_top(server_rows.get(mode, []))
	prize_banner.visible = global
	# "Pontos por jogo" só aparece quando houver mais de um jogo
	games_card.visible = global and GameState.GAME_IDS.size() > 1
	if global:
		var total := GameState.global_month_total(month)
		title_label.text = tr("Ranking Global")
		prize_label.text = tr("Vale prêmios! Soma os pontos de todos os jogos do Na Lata.")
		me_box.bg_color = Color("e0662f")
		points_label.text = tr("%d pts") % total.points
		detail_label.text = tr("%d jogadas no mês") % total.moves
		if games_card.visible:
			_fill_games(total.games)
		if total.has("position"):
			detail_label.text = _position_text(total.position)
			info_label.text = tr("Empate: fica na frente quem usou menos jogadas.")
		else:
			info_label.text = tr("Empate: fica na frente quem usou menos jogadas. A lista com todos os jogadores chega com as contas.")
	else:
		var t := GameState.game_month_total(game_id, month)
		title_label.text = tr("Ranking do %s") % tr(game_name(game_id))
		me_box.bg_color = GameStyle.PURPLE
		points_label.text = tr("%d pts") % t.points
		detail_label.text = tr("%d desafios e %d níveis · %d jogadas") % [t.completed, t.levels, t.moves]
		if t.has("position"):
			detail_label.text = _position_text(t.position)
		info_label.text = tr("Os prêmios saem do Ranking Global, no menu do Na Lata.")


func _position_text(position: Variant) -> String:
	if position == null:
		return tr("Jogue para entrar no ranking")
	return tr("%dº lugar") % int(position)


## Lista dos primeiros: posição, apelido e pontos; a linha do jogador fica destacada.
func _fill_top(rows: Array) -> void:
	for c in top_list.get_children():
		c.queue_free()
	top_card.visible = not rows.is_empty()
	for r in rows:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var color: Color = GameStyle.ACCENT if r[3] else GameStyle.INK
		var pos := GameStyle.make_label("%dº" % r[0], 28, true, color)
		pos.custom_minimum_size = Vector2(70, 0)
		pos.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		row.add_child(pos)
		var nick := GameStyle.make_label(tr("Você") if r[3] else str(r[1]), 28, r[3], color)
		nick.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		nick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nick.clip_text = true
		if not r[3]:
			nick.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		row.add_child(nick)
		var pts := GameStyle.make_label(tr("%d pts") % r[2], 28, true, color)
		pts.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		row.add_child(pts)
		top_list.add_child(row)


func _fill_games(points_by_game: Dictionary) -> void:
	for c in games_list.get_children():
		c.queue_free()
	for id in points_by_game:
		var row := HBoxContainer.new()
		var name_label := GameStyle.make_label(game_name(id), 28)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var pts := GameStyle.make_label(tr("%d pts") % points_by_game[id], 28, true, GameStyle.ACCENT)
		pts.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		row.add_child(pts)
		games_list.add_child(row)


## Nome do jogo como aparece no hub (o próprio id se não estiver na lista).
static func game_name(id: String) -> String:
	for g in HubScreen.GAMES:
		if g[0] == id:
			return g[1]
	return id
