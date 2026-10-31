class_name RankingPanel
extends Panel
## Tela do ranking: lista dos melhores, posicao do jogador e escolha do nome.

const INK := Color(0.12, 0.16, 0.27)
const HIGHLIGHT := Color(0.93, 0.33, 0.2)
const ROW_COUNT := Ranking.TOP_SIZE + 1
const FONT_SIZE := 22

var ranking: Ranking
var best := 0
var request := 0
var rows: Array[Dictionary] = []

var title := Label.new()
var status := Label.new()
var list := VBoxContainer.new()
var name_row := HBoxContainer.new()
var name_input := LineEdit.new()
var save_button := Button.new()
var close_button := Button.new()


func _ready() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	title.add_theme_color_override("font_outline_color", INK)
	title.add_theme_constant_override("outline_size", 10)
	box.add_child(title)

	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", FONT_SIZE)
	status.add_theme_color_override("font_color", INK)
	box.add_child(status)

	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(list)
	for i in ROW_COUNT:
		_add_row()

	name_input.max_length = Ranking.MAX_NAME
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_input.add_theme_font_size_override("font_size", FONT_SIZE)
	name_input.add_theme_color_override("font_color", INK)
	name_input.add_theme_color_override("caret_color", INK)
	name_input.add_theme_color_override("font_placeholder_color", Color(INK, 0.5))
	var field := _box_style(Color.WHITE)
	name_input.add_theme_stylebox_override("normal", field)
	name_input.add_theme_stylebox_override("focus", field)
	name_input.text_submitted.connect(_on_name_submitted)
	name_row.add_child(name_input)
	_style_button(save_button)
	save_button.pressed.connect(func() -> void: _on_name_submitted(name_input.text))
	name_row.add_child(save_button)
	box.add_child(name_row)

	_style_button(close_button)
	close_button.pressed.connect(close)
	box.add_child(close_button)
	hide()


func _style_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 50.0
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, INK)
	button.add_theme_stylebox_override("normal", _box_style(Color(1.0, 0.8, 0.2)))
	button.add_theme_stylebox_override("hover", _box_style(Color(1.0, 0.9, 0.5)))
	button.add_theme_stylebox_override("pressed", _box_style(Color(1.0, 0.9, 0.5)))


func _box_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = INK
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(8.0)
	return style


func open(source: Ranking, best_score: int) -> void:
	ranking = source
	best = best_score
	title.text = tr("RANKING")
	name_input.placeholder_text = tr("RANKING_NAME_HINT")
	save_button.text = tr("RANKING_SAVE")
	close_button.text = tr("RANKING_CLOSE")
	show()
	await _refresh()


func close() -> void:
	# Respostas que chegarem depois de fechar sao ignoradas.
	request += 1
	name_input.release_focus()
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_name_submitted(text: String) -> void:
	if ranking.set_player_name(text):
		name_input.release_focus()
		await _refresh()


func _refresh() -> void:
	request += 1
	var current := request
	name_row.visible = ranking.player_name.is_empty()
	status.text = tr("RANKING_LOADING")
	show_rows([])
	await ranking.sync(best)
	var result: Variant = await ranking.fetch()
	if current != request:
		return
	if result == null:
		status.text = tr("RANKING_OFFLINE")
	elif result.is_empty():
		status.text = tr("RANKING_EMPTY")
	elif ranking.player_name.is_empty():
		status.text = tr("RANKING_NEED_NAME")
	else:
		status.text = ""
	if result != null:
		show_rows(result)


func show_rows(entries: Array) -> void:
	var seen := {}
	var shown := 0
	for entry: Dictionary in entries:
		if seen.has(entry.position) or shown >= ROW_COUNT:
			continue
		seen[entry.position] = true
		_fill_row(rows[shown], entry)
		shown += 1
	for i in range(shown, ROW_COUNT):
		rows[i].root.hide()


func _add_row() -> void:
	var root := HBoxContainer.new()
	var position_label := _row_label(52.0)
	var name_label := _row_label(0.0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	var score_label := _row_label(92.0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(position_label)
	root.add_child(name_label)
	root.add_child(score_label)
	list.add_child(root)
	root.hide()
	rows.append({"root": root, "position": position_label, "name": name_label, "score": score_label})


func _row_label(width: float) -> Label:
	var label := Label.new()
	label.custom_minimum_size.x = width
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label


func _fill_row(row: Dictionary, entry: Dictionary) -> void:
	row.position.text = "%d." % entry.position
	row.name.text = entry.name
	row.score.text = str(entry.score)
	var color := HIGHLIGHT if entry.mine else INK
	for key in ["position", "name", "score"]:
		row[key].add_theme_color_override("font_color", color)
	row.root.show()
