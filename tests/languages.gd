extends SceneTree
## Verifica traducoes, fontes, layout e selecao de idioma.
## Sem janela: godot --headless --fixed-fps 60 --path . --script res://tests/languages.gd
## Com capturas: godot --fixed-fps 60 --path . --script res://tests/languages.gd -- --shots=PASTA

const KEYS := [
	"HELP_MOVE", "HELP_SHOOT", "HELP_BOMB", "HELP_RELOAD", "PROMPT_START", "PROMPT_RESTART",
	"GAME_OVER", "NEW_RECORD", "SCORE_LINE", "BEST_LINE", "BEST_HUD", "TOAST_SHIELD",
	"TOAST_HEART", "TOAST_BOMB", "TOAST_TRIPLE", "TOAST_REVIVED", "TOAST_NO_MONSTERS",
	"TOAST_NO_AMMO", "HELP_TOUCH",
	"PROMPT_TOUCH_START", "PROMPT_TOUCH_RESTART", "TOAST_BOMB_TOUCH",
]
const SAVE := "user://languages_test.cfg"
# Medidas do painel em main.tscn. Ficam fixas aqui porque o Label cresce com o texto,
# e medir o proprio Label esconderia o estouro.
const DESIGN_HEIGHTS := {&"Title": 130.0, &"Message": 180.0}
const DESIGN_WIDTHS := {&"Prompt": 356.0, &"Language": 190.0}
const SHEET_COLUMNS := 3

var main: Node2D
var failures := 0
var shots_dir := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.trim_prefix("--shots=")
	_remove_save()
	main = _make_main()
	root.add_child(main)
	await process_frame
	await process_frame
	if shots_dir.is_empty():
		await _run_all()
	else:
		await _capture_sheets()
	_remove_save()
	print("falhas: ", failures)
	quit(1 if failures > 0 else 0)


func _make_main() -> Node2D:
	var scene: Node2D = load("res://main.tscn").instantiate()
	scene.save_path = SAVE
	return scene


func _remove_save() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _run_all() -> void:
	_test_texts_and_glyphs()
	await _test_layouts()
	await _test_selector()
	await _test_detection()
	await _test_persistence()


func _test_texts_and_glyphs() -> void:
	var fonts: Array[Font] = [main.UI_FONT]
	fonts.append_array(main.FALLBACK_FONTS)
	_check("fonte: fallbacks ativos", main.UI_FONT.fallbacks.size() == 3)
	_check("fonte: sem depender do sistema", not main.UI_FONT.allow_system_fallback)
	for entry: Array in main.LANGUAGES:
		TranslationServer.set_locale(entry[0])
		var missing: Array[String] = []
		var glyphs: Array[String] = []
		var names: Array[String] = [entry[1]]
		for key: String in KEYS:
			var text := TranslationServer.translate(key)
			if text == key or text.is_empty():
				missing.append(key)
			names.append(text)
		for text in names:
			for i in text.length():
				var code := text.unicode_at(i)
				if code > 32 and not _any_has_char(fonts, code) and not glyphs.has(text[i]):
					glyphs.append(text[i])
		_check("%s: todas as chaves traduzidas %s" % [entry[0], missing], missing.is_empty())
		_check("%s: todas as letras na fonte %s" % [entry[0], glyphs], glyphs.is_empty())


func _any_has_char(fonts: Array[Font], code: int) -> bool:
	for font in fonts:
		if font.has_char(code):
			return true
	return false


func _test_layouts() -> void:
	for i in main.LANGUAGES.size():
		await _select(i)
		var code: String = main.LANGUAGES[i][0]
		_check_fits(code + " menu", main.message)
		_check_fits(code + " titulo", main.title)
		_check_width(code + " prompt", main.prompt)
		_check_width(code + " nome", main.language_label)
		main.score = 123456
		main.best = 0
		main._end_game()
		await process_frame
		await process_frame
		_check_fits(code + " fim: titulo", main.title)
		_check_fits(code + " fim: corpo", main.message)
		_check_width(code + " fim: prompt", main.prompt)
		_check("%s recorde cabe no HUD" % code, main.best_label.get_minimum_size().x <= main.best_label.size.x)
		var toast := Toast.new(Vector2(240.0, 400.0), tr("TOAST_NO_AMMO"))
		main.effects.add_child(toast)
		await process_frame
		_check("%s aviso cabe" % code, toast.get_line_count() <= 2)
		toast.free()
		main.best = 0
		_remove_save()
		main.state = 0


func _select(index: int) -> void:
	main.language = index
	main.change_language(0)
	await process_frame
	await process_frame


func _check_fits(label: String, control: Label) -> void:
	var limit := DESIGN_HEIGHTS[control.name] as float
	var lines := control.get_line_count()
	var spacing := control.get_theme_constant("line_spacing")
	var height := lines * control.get_line_height() + (lines - 1) * spacing
	_check("%s: %d linhas, %d de %d px" % [label, control.get_line_count(), height, limit], height <= limit)


func _check_width(label: String, control: Label) -> void:
	var limit := DESIGN_WIDTHS[control.name] as float
	var width := control.get_theme_font("font").get_string_size(
		control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_font_size("font_size")
	).x
	_check("%s: %d de %d px" % [label, width, limit], width <= limit)


func _test_selector() -> void:
	await _select(0)
	_check("seletor: visivel no menu", main.language_row.is_visible_in_tree())
	_tap(KEY_RIGHT)
	await process_frame
	await process_frame
	await process_frame
	_check("seletor: seta direita avanca", main.language == 1)
	_check("seletor: texto muda na hora", main.prompt.text == "Press Space to play")
	_tap(KEY_LEFT)
	await process_frame
	await process_frame
	await process_frame
	_tap(KEY_LEFT)
	await process_frame
	await process_frame
	await process_frame
	_check("seletor: da a volta na lista", main.language == main.LANGUAGES.size() - 1)

	await _select(0)
	await _click(main.language_next)
	_check("seletor: clique na seta troca", main.language == 1)
	_check("seletor: clique nao inicia o jogo", main.state == 0)

	main.start_game()
	await process_frame
	_check("seletor: some na partida", not main.language_row.is_visible_in_tree())
	var before: int = main.language
	Input.action_press("move_right")
	_tap(KEY_RIGHT)
	await process_frame
	await process_frame
	await process_frame
	Input.action_release("move_right")
	_check("seletor: partida nao muda idioma", main.language == before)
	main.player.lives = 0
	main.player.position.y = 5000.0
	await physics_frame
	await physics_frame
	_check("seletor: nao aparece no fim de jogo", main.state == 2 and not main.language_row.is_visible_in_tree())
	main.state = 0


func _tap(key_code: Key) -> void:
	var key := InputEventKey.new()
	key.physical_keycode = key_code
	key.pressed = true
	Input.parse_input_event(key)
	var release := InputEventKey.new()
	release.physical_keycode = key_code
	Input.parse_input_event(release)


func _click(button: Button) -> void:
	var center: Vector2 = root.get_final_transform() * button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	motion.global_position = center
	Input.parse_input_event(motion)
	await process_frame
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = center
		event.global_position = center
		Input.parse_input_event(event)
		await process_frame
		await process_frame


func _test_detection() -> void:
	_check("sistema: pt_PT usa portugues", main._language_index("pt_PT") == 0)
	_check("sistema: de_AT usa alemao", main._language_index("de_AT") == 7)
	_check("sistema: zh_TW usa chines", main._language_index("zh_TW") == 6)
	_check("sistema: idioma sem traducao usa ingles", main._language_index("ja_JP") == 1)


func _test_persistence() -> void:
	await _select(4)
	main.best = 777
	main.change_language(1)
	var saved_code: String = main.LANGUAGES[main.language][0]
	var other := _make_main()
	root.add_child(other)
	await process_frame
	_check("salvar: idioma volta ao abrir", other.LANGUAGES[other.language][0] == saved_code)
	_check("salvar: recorde preservado", other.best == 777)
	other.free()

	var old_format := ConfigFile.new()
	old_format.set_value("score", "best", 1877)
	old_format.save(SAVE)
	var legacy := _make_main()
	root.add_child(legacy)
	await process_frame
	_check("salvar: arquivo antigo mantem recorde", legacy.best == 1877)
	legacy.free()
	TranslationServer.set_locale("pt_BR")


func _capture_sheets() -> void:
	await RenderingServer.frame_post_draw
	var cell: Vector2i = root.get_texture().get_image().get_size()
	var index := 0
	while index < main.LANGUAGES.size():
		var sheet := Image.create(cell.x * SHEET_COLUMNS, cell.y * 2, false, Image.FORMAT_RGBA8)
		for column in SHEET_COLUMNS:
			await _select(index)
			await _paste(sheet, Vector2i(cell.x * column, 0))
			main.score = 4321
			main.best = 0
			main._end_game()
			await process_frame
			await _paste(sheet, Vector2i(cell.x * column, cell.y))
			main.state = 0
			index += 1
		sheet.save_png("%s/idiomas_%d.png" % [shots_dir, index / SHEET_COLUMNS])
		print("folha ", index / SHEET_COLUMNS)


func _paste(sheet: Image, at: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	sheet.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), at)


func _check(label: String, passed: bool) -> void:
	if not passed:
		print("FALHA ", label)
		failures += 1
	else:
		print("ok    ", label)
