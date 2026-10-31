extends SceneTree
## Reproduz bugs suspeitos em cenas controladas.
## Uso: godot --headless --fixed-fps 60 --path . --script res://tests/bugs.gd

const SAVE := "user://bugs_test.cfg"

var main: Node2D
var player: Player
var failures := 0
var checks := 0


func _initialize() -> void:
	_remove_save()
	main = _make_main()
	root.add_child(main)
	await process_frame
	await process_frame
	player = main.player
	await _test_score_starts_at_zero()
	await _test_click_over_hud_shoots()
	await _test_dead_monster_does_not_hurt()
	await _test_two_bullets_one_monster()
	await _test_bomb_ignores_dying_monster()
	await _test_jump_height_beats_max_gap()
	await _test_sounds()
	await _test_bad_saves()
	_remove_save()
	print("verificacoes: %d falhas: %d" % [checks, failures])
	quit(1 if failures > 0 or checks == 0 else 0)


func _make_main() -> Node2D:
	var scene: Node2D = load("res://main.tscn").instantiate()
	scene.save_path = SAVE
	return scene


func _remove_save() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _fresh() -> void:
	main.start_game()
	for layer: Node2D in [main.platforms, main.monsters]:
		for node in layer.get_children():
			node.free()
	main.next_platform_y = -INF
	player.position = Vector2(240.0, 400.0)
	player.velocity = Vector2(0.0, -200.0)


func _monster_at(at: Vector2) -> Monster:
	var monster := Monster.new()
	monster.position = at
	monster.setup(0.0, Monster.Variant.SPIKY)
	main.monsters.add_child(monster)
	return monster


func _test_score_starts_at_zero() -> void:
	main.start_game()
	await _frames(3)
	_check("pontos comecam em zero (veio %d)" % main.score, main.score == 0)


func _test_click_over_hud_shoots() -> void:
	_fresh()
	await _frames(2)
	for key in ["ammo"]:
		var slot: Control = main.power_bar.slots[key].root
		var center: Vector2 = root.get_final_transform() * slot.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = center
		motion.global_position = center
		Input.parse_input_event(motion)
		await process_frame
		var before: int = main.bullets.get_child_count()
		player.shoot_cooldown = 0.0
		for pressed in [true, false]:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = pressed
			click.position = center
			click.global_position = center
			Input.parse_input_event(click)
			await process_frame
		await process_frame
		_check("clique sobre o HUD (%s) atira" % key, main.bullets.get_child_count() == before + 1)


func _test_dead_monster_does_not_hurt() -> void:
	_fresh()
	var monster := _monster_at(player.position + Vector2(40.0, 0.0))
	monster.queue_free()
	main._check_monsters()
	_check("monstro ja destruido nao mata", player.alive)
	await _frames(2)


func _test_two_bullets_one_monster() -> void:
	_fresh()
	var monster := _monster_at(Vector2(100.0, 200.0))
	for i in 2:
		var bullet := Bullet.new()
		bullet.position = monster.position
		main.bullets.add_child(bullet)
	await _frames(2)
	_check("dois tiros: um segue voando", main.bullets.get_child_count() == 1)


func _test_bomb_ignores_dying_monster() -> void:
	_fresh()
	player.bombs = 1
	_monster_at(Vector2(100.0, 200.0)).queue_free()
	main.use_bomb()
	_check("bomba nao gasta com monstro ja destruido", player.bombs == 1)
	await _frames(2)


func _test_jump_height_beats_max_gap() -> void:
	_fresh()
	player.position.y = 400.0
	player.bounce(Cfg.JUMP_VELOCITY)
	var start := player.position.y
	var top := start
	for i in 90:
		await physics_frame
		top = minf(top, player.position.y)
	_check("pulo real (%d px) passa do maior vao (%d px)" % [start - top, Cfg.GAP_MAX_HARD], start - top > Cfg.GAP_MAX_HARD)


func _test_sounds() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var regex := RegEx.create_from_string("sfx\\.play\\(\"(\\w+)\"\\)")
	var names := {}
	for found in regex.search_all(source):
		names[found.get_string(1)] = true
	_check("ha sons chamados no codigo", names.size() > 5)
	for sound: String in names:
		_check("som '%s' existe" % sound, main.sfx.players.has(sound))
	for sound: String in main.sfx.players:
		var stream: AudioStreamWAV = main.sfx.players[sound].stream
		var data := stream.data
		var peak := 0
		for i in range(0, data.size(), 2):
			peak = maxi(peak, absi(data.decode_s16(i)))
		_check("som '%s' tem audio (pico %d)" % [sound, peak], peak > 2000 and peak < 32768)


func _test_bad_saves() -> void:
	var cases := {
		"texto no recorde": "[score]\nbest=\"abc\"\n",
		"idioma numerico": "[score]\nbest=10\n[settings]\nlanguage=5\n",
		"idioma desconhecido": "[settings]\nlanguage=\"xx\"\n",
		"recorde negativo": "[score]\nbest=-50\n",
		"arquivo quebrado": "isto nao e um save {{{",
		"vazio": "",
	}
	for label: String in cases:
		var file := FileAccess.open(SAVE, FileAccess.WRITE)
		file.store_string(cases[label])
		file.close()
		var scene := _make_main()
		root.add_child(scene)
		await process_frame
		var valid_language: bool = scene.language >= 0 and scene.language < scene.LANGUAGES.size()
		var valid_best: bool = typeof(scene.best) == TYPE_INT and scene.best >= 0
		_check("save com %s: abre normal" % label, valid_language and valid_best and scene.panel.visible)
		scene.free()
	var kept := FileAccess.open(SAVE, FileAccess.WRITE)
	kept.store_string("[score]\nbest=1949\n")
	kept.close()
	var old_save := _make_main()
	root.add_child(old_save)
	await process_frame
	_check("save valido antigo preserva o recorde", old_save.best == 1949)
	old_save.free()


func _check(label: String, passed: bool) -> void:
	checks += 1
	if not passed:
		failures += 1
	print(("ok    " if passed else "FALHA ") + label)
