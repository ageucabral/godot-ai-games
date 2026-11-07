extends Control
## Os dois rankings do mês:
## - "game": o ranking de um jogo só (ex.: Poção de Cores), para o jogador ver como está naquele jogo;
## - "global": o Ranking Global do Na Lata, que soma todos os jogos e é o que vale os prêmios.
## Por enquanto mostra só os pontos deste aparelho; a lista com todos os jogadores chega com o servidor.

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


func refresh() -> void:
	var now := GameState.now_unix()
	var month := Rules.month_for(now)
	var month_name := Rules.month_name(month)
	subtitle_label.text = tr("%s · termina em %d dias · zera no dia 1") % [month_name, Rules.days_left_in_month(now)]
	var global := mode == GLOBAL
	prize_banner.visible = global
	games_card.visible = global
	if global:
		var total := GameState.global_month_total(month)
		title_label.text = tr("Ranking Global")
		prize_label.text = tr("Vale prêmios! Soma os pontos de todos os jogos do Na Lata.")
		me_box.bg_color = Color("e0662f")
		points_label.text = tr("%d pts") % total.points
		detail_label.text = tr("%d jogadas no mês") % total.moves
		_fill_games(total.games)
		info_label.text = tr("O Ranking Global junta todos os jogos do Na Lata e é ele que define os prêmios do mês.\n\nEmpate: fica na frente quem usou menos jogadas.\nPrêmios e posições premiadas: definidos pelo administrador.\n\nA lista com todos os jogadores aparece quando ligarmos as contas e o servidor (próxima etapa).")
	else:
		var t := GameState.game_month_total(game_id, month)
		title_label.text = tr("Ranking do %s") % tr(game_name(game_id))
		me_box.bg_color = GameStyle.PURPLE
		points_label.text = tr("%d pts") % t.points
		detail_label.text = tr("%d desafios e %d níveis · %d jogadas") % [t.completed, t.levels, t.moves]
		info_label.text = tr("Este ranking mostra como você está só neste jogo.\nOs prêmios saem do Ranking Global, no menu do Na Lata.\n\nA lista com todos os jogadores aparece quando ligarmos as contas e o servidor (próxima etapa).")


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
