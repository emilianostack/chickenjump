extends SceneTree
## Verifica ranking e toque com um servidor falso, sem depender de internet.
## Uso: godot --headless --fixed-fps 60 --path . --script res://tests/online.gd

const SAVE := "user://online_test.cfg"


class FakeBackend:
	var configured := true
	var online := true
	var identified: Array[String] = []
	var submitted: Array = []
	var rows: Array = []

	func is_configured() -> bool:
		return configured

	func identify(player_id: String) -> bool:
		identified.append(player_id)
		return online

	func submit(score: int, player_name: String) -> bool:
		if not online:
			return false
		submitted.append([score, player_name])
		return true

	func fetch_top(_limit: int) -> Variant:
		return rows if online else null


var main: Node2D
var fake := FakeBackend.new()
var failures := 0
var checks := 0


func _initialize() -> void:
	_remove_save()
	await _test_without_key()
	await _test_ranking()
	await _test_persistence()
	await _test_touch()
	_remove_save()
	print("verificacoes: %d falhas: %d" % [checks, failures])
	quit(1 if failures > 0 or checks == 0 else 0)


func _remove_save() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _spawn(backend: Variant = null) -> Node2D:
	var scene: Node2D = load("res://main.tscn").instantiate()
	scene.save_path = SAVE
	root.add_child(scene)
	await process_frame
	await process_frame
	if backend != null:
		scene.ranking.backend = backend
		scene._show_menu()
	return scene


func _test_without_key() -> void:
	var no_key := FakeBackend.new()
	no_key.configured = false
	var scene := await _spawn(no_key)
	_check("sem chave: botao de ranking some", not scene.ranking_button.visible)
	scene.score = 500
	scene._end_game()
	await process_frame
	_check("sem chave: fim de jogo normal", scene.state == 2)
	_check("sem chave: botao segue oculto", not scene.ranking_button.visible)
	scene.free()
	_remove_save()


func _test_ranking() -> void:
	main = await _spawn(fake)
	var ranking = main.ranking
	_check("com chave: botao aparece no menu", main.ranking_button.visible)
	main.start_game()
	_check("botao some na partida", not main.ranking_button.visible)

	main.score = 900
	main._end_game()
	await process_frame
	_check("botao volta no fim de jogo", main.ranking_button.visible)
	_check("sem nome nao envia", fake.submitted.is_empty())

	_check("nome curto recusado", not ranking.set_player_name(" a "))
	_check("nome so com controles recusado", not ranking.set_player_name("\t\n"))
	_check("nome e limpo", main.ranking.clean_name("  Ana\u0007 Lu  ") == "Ana Lu")
	_check("nome e cortado", main.ranking.clean_name("x".repeat(40)).length() == main.ranking.MAX_NAME)

	fake.rows = [
		{"position": 1, "name": "Ana", "score": 5000, "mine": false},
		{"position": 2, "name": "Lu", "score": 900, "mine": true},
		{"position": 2, "name": "Lu", "score": 900, "mine": true},
	]
	await ranking_open()
	_check("painel abre", main.ranking_panel.visible)
	_check("pede nome", main.ranking_panel.name_row.visible)
	main.ranking_panel._on_name_submitted("Lu")
	await _frames(3)
	_check("envia recorde ao salvar nome", fake.submitted == [[900, "Lu"]])
	_check("campo de nome some", not main.ranking_panel.name_row.visible)
	_check("id gerado", ranking.player_id.length() == 32)
	var panel = main.ranking_panel
	_check("mostra as linhas sem repetir", panel.rows[0].root.visible and panel.rows[1].root.visible and not panel.rows[2].root.visible)
	_check("primeira linha certa", panel.rows[0].name.text == "Ana" and panel.rows[0].score.text == "5000")

	# Com o painel aberto, Espaco nao recomeca a partida.
	main.restart_wait = 0.0
	_tap(KEY_SPACE)
	await _frames(3)
	_check("Espaco nao age por tras do painel", main.state == 2)
	panel.close()
	_check("fechar funciona", not panel.visible)
	_tap(KEY_SPACE)
	await _frames(3)
	_check("Espaco volta a funcionar", main.state == 1)

	fake.submitted.clear()
	main.score = 800
	main.best = 900
	main._end_game()
	await _frames(2)
	_check("pontuacao menor nao reenvia", fake.submitted.is_empty())

	fake.online = false
	main.start_game()
	main.score = 2000
	main._end_game()
	await _frames(2)
	_check("sem internet: jogo segue", main.state == 2 and main.best == 2000)
	_check("sem internet: fica pendente", ranking.synced_best == 900)
	await ranking_open()
	_check("sem internet: avisa", panel.status.text == tr("RANKING_OFFLINE"))
	panel.close()
	fake.online = true
	await ranking_open()
	_check("volta a internet: envia o pendente", fake.submitted == [[2000, "Lu"]] and ranking.synced_best == 2000)
	panel.close()

	# Resposta lenta que chega depois de fechar nao pode reabrir nem mudar a tela.
	await ranking_open()
	panel.status.text = "x"
	panel.close()
	await _frames(2)
	_check("fechado continua fechado", not panel.visible)


func ranking_open() -> void:
	main.open_ranking()
	await _frames(3)


func _test_persistence() -> void:
	var saved_id: String = main.ranking.player_id
	main.free()
	main = await _spawn(fake)
	_check("salvar: nome volta", main.ranking.player_name == "Lu")
	_check("salvar: id volta", main.ranking.player_id == saved_id)
	_check("salvar: envio lembrado", main.ranking.synced_best == 2000)
	_check("salvar: recorde volta", main.best == 2000)
	main.free()

	var bad := FileAccess.open(SAVE, FileAccess.WRITE)
	bad.store_string("[ranking]\nid=5\nname=7\nsynced_best=\"x\"\n")
	bad.close()
	main = await _spawn(fake)
	_check("save ruim: ranking zerado", main.ranking.player_id == "" and main.ranking.player_name == "" and main.ranking.synced_best == 0)
	main.free()
	_remove_save()


func _test_touch() -> void:
	main = await _spawn(fake)
	main.touch_ui = true
	main._show_menu()
	_check("toque: menu curto", main.message.text.count("\n") == 1)
	_check("toque: chamada propria", main.prompt.text == tr("PROMPT_TOUCH_START"))
	_check("toque: botoes ocultos no menu", not main.touch_controls.visible)
	for button: TouchScreenButton in main.touch_controls.get_children():
		button.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS

	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	tap.device = InputEvent.DEVICE_ID_EMULATION
	tap.position = Vector2(200.0, 300.0)
	Input.parse_input_event(tap)
	await _frames(2)
	var release := tap.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await _frames(2)
	_check("toque: tela inicia o jogo", main.state == 1)
	_check("toque: botoes aparecem", main.touch_controls.visible)

	await _touch("move_left", true)
	_check("toque: esquerda segura", Input.is_action_pressed("move_left"))
	var bullets_before: int = main.bullets.get_child_count()
	var emulated := tap.duplicate()
	Input.parse_input_event(emulated)
	await _frames(2)
	var emulated_up := release.duplicate()
	Input.parse_input_event(emulated_up)
	await _frames(1)
	_check("toque: clique emulado nao atira", main.bullets.get_child_count() == bullets_before)
	await _touch("move_left", false)
	_check("toque: esquerda solta", not Input.is_action_pressed("move_left"))

	main.player.shoot_cooldown = 0.0
	await _touch("shoot", true)
	await _touch("shoot", false)
	_check("toque: botao atira", main.bullets.get_child_count() == bullets_before + 1)

	await _touch("move_right", true)
	main.player.lives = 0
	main._end_game()
	await _frames(2)
	_check("toque: botoes somem no fim", not main.touch_controls.visible)
	_check("toque: dedo preso nao trava", not Input.is_action_pressed("move_right"))
	await _touch("move_right", false, true)
	Input.action_release("move_right")
	main.free()


func _touch(action: String, pressed: bool, ignore_missing := false) -> void:
	var button: TouchScreenButton = main.touch_controls.get_node(action)
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.pressed = pressed
	var size := button.texture_normal.get_size() * button.scale
	event.position = root.get_final_transform() * (button.global_position + size * 0.5)
	if not ignore_missing or button.is_visible_in_tree():
		Input.parse_input_event(event)
	await _frames(2)


func _tap(key_code: Key) -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.physical_keycode = key_code
		key.pressed = pressed
		Input.parse_input_event(key)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _check(label: String, passed: bool) -> void:
	checks += 1
	if not passed:
		failures += 1
	print(("ok    " if passed else "FALHA ") + label)
