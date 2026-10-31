extends SceneTree
## Captura a tela de ranking com dados falsos e os botoes de toque.
## Uso: godot --path . --script res://tests/ranking_shots.gd -- --shots=PASTA


class FakeBackend:
	var rows: Array = []

	func is_configured() -> bool:
		return true

	func identify(_player_id: String) -> bool:
		return true

	func submit(_score: int, _player_name: String) -> bool:
		return true

	func fetch_top(_limit: int) -> Variant:
		return rows


var main: Node2D
var shots_dir := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.trim_prefix("--shots=")
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://ranking_shots_test.cfg"
	root.add_child(main)
	await process_frame
	await process_frame
	var fake := FakeBackend.new()
	var names := ["Ana", "Mário", "Лена", "지민", "小明", "Ana Beatriz Souza", "Chloé", "Jonas", "Giulia", "Rafa"]
	for i in names.size():
		fake.rows.append({"position": i + 1, "name": names[i], "score": 98765 - i * 7321, "mine": false})
	fake.rows.append({"position": 57, "name": "Chicken", "score": 1949, "mine": true})
	main.ranking.backend = fake
	main.ranking.player_name = "Chicken"
	main.best = 1949
	main._show_menu()
	await _wait(5)
	await _shot("menu_botao")
	main.open_ranking()
	await _wait(5)
	await _shot("ranking")
	main.ranking_panel.close()
	main.ranking.player_name = ""
	fake.rows.clear()
	main.open_ranking()
	await _wait(5)
	await _shot("ranking_nome")
	main.ranking_panel.close()
	main.touch_ui = true
	main.start_game()
	for button: TouchScreenButton in main.touch_controls.get_children():
		button.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	await _wait(60)
	await _shot("toque")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ranking_shots_test.cfg"))
	quit()


func _wait(count: int) -> void:
	for i in count:
		await process_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [shots_dir, shot_name])
	print("captura: ", shot_name)
