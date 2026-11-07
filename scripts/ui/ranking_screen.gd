extends Control
## Ranking do mês. Por enquanto mostra só os pontos deste aparelho;
## a lista com todos os jogadores chega na etapa de contas e servidor.

signal back_requested

var title_label: Label
var subtitle_label: Label
var points_label: Label
var detail_label: Label


func _ready() -> void:
	theme = GameStyle.build_theme()
	GameStyle.add_background(self, "night")
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 36
	box.offset_right = -36
	box.offset_top = 60
	box.offset_bottom = -50
	box.add_theme_constant_override("separation", 22)
	add_child(box)

	var back := GameStyle.make_button("Voltar", false, 28)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void: back_requested.emit())
	box.add_child(back)
	title_label = GameStyle.make_title("", 60, GameStyle.GOLD)
	box.add_child(title_label)
	subtitle_label = GameStyle.make_title("", 26)
	box.add_child(subtitle_label)

	var me := PanelContainer.new()
	var me_box := StyleBoxFlat.new()
	me_box.bg_color = GameStyle.PURPLE
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
	points_label = GameStyle.make_label("", 72, true, Color.WHITE)
	me_inner.add_child(points_label)
	detail_label = GameStyle.make_label("", 26, false, Color.WHITE)
	me_inner.add_child(detail_label)

	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", GameStyle.card_box())
	box.add_child(info)
	var info_text := GameStyle.make_label(
		"O ranking com todos os jogadores aparece quando ligarmos as contas e o servidor (próxima etapa).\n\n" +
		"Por enquanto, aqui ficam os seus pontos guardados neste aparelho.\n\n" +
		"Empate: fica na frente quem usou menos jogadas.\nPrêmios e posições premiadas: definidos pelo administrador.", 26)
	info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(info_text)

	GameState.progress_changed.connect(refresh)
	refresh()


func refresh() -> void:
	var now := GameState.now_unix()
	var month := Rules.month_for(now)
	var total := GameState.month_total(month)
	title_label.text = tr("Ranking de %s") % Rules.month_name(month)
	subtitle_label.text = tr("Termina em %d dias · zera no dia 1") % Rules.days_left_in_month(now)
	points_label.text = tr("%d pts") % total.points
	detail_label.text = tr("%d desafios e %d níveis · %d jogadas") % [total.completed, total.levels, total.moves]
