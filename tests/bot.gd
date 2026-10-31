extends SceneTree
## Robo que joga sozinho para testar o jogo.
## Sem janela: godot --headless --fixed-fps 60 --path . --script res://tests/bot.gd
## Com capturas: godot --fixed-fps 60 --path . --script res://tests/bot.gd -- --shots=PASTA

const MAX_FRAMES := 400000
const STALL_LIMIT := 3600

var main: Node2D
var player: Player
var frame := 0
var shots_dir := ""
var runs := 0
var deaths_by_monster := 0
var deaths_by_fall := 0
var peak_score := 0
var scores: Array[int] = []
var springs := 0
var jetpacks := 0
var breaks := 0
var kills := 0
var was_alive := true
var was_jetpack := false
var last_vy := 0.0
var last_monsters := 0
var revives := 0
var shields_used := 0
var bombs_used := 0
var triples := 0
var last_lives := 0
var last_shield := false
var last_bombs := 0
var last_triple := 0.0
var stall_score := 0
var stall_frame := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.trim_prefix("--shots=")
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://bot_test.cfg"
	root.add_child(main)
	await process_frame
	player = main.player
	if shots_dir.is_empty():
		main.start_game()
	else:
		_capture_all()


func _capture_all() -> void:
	await _wait_frames(10)
	await _shot("menu")
	await _tap_space()
	print("espaco no menu -> estado ", main.state, " (esperado 1)")
	await _wait_frames(120)
	await _shot("jogo")
	main.start_game()
	_build_gallery()
	main._add_puff(Vector2(390.0, 250.0), Color(1.0, 0.75, 0.4), 16)
	main.shoot()
	await _wait_frames(8)
	print("efeitos ativos: ", main.effects.get_child_count(), " (esperado >= 1)")
	await _shot("galeria")
	for stage: Array in [[-9500.0, "tarde"], [-21000.0, "noite"], [-36000.0, "espaco"]]:
		_teleport(stage[0])
		await _wait_frames(4)
		await _shot(stage[1])
	_teleport(-36000.0)
	player.jetpack_left = 1.0
	await _wait_frames(10)
	await _shot("jetpack")
	player.jetpack_left = 0.0
	player.lives = 0
	player.kill()
	while main.state != 2:
		await process_frame
	await _wait_frames(5)
	await _shot("fim")
	await _tap_space()
	print("espaco cedo demais -> estado ", main.state, " (esperado 2)")
	await _wait_frames(45)
	await _tap_space()
	print("espaco depois da espera -> estado ", main.state, " (esperado 1)")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://bot_test.cfg"))
	quit()


## Coloca um exemplar de cada elemento em posicoes fixas da tela.
func _build_gallery() -> void:
	var rows := [
		[Platform.Kind.NORMAL, 110.0, 130.0],
		[Platform.Kind.MOVING, 250.0, 130.0],
		[Platform.Kind.NORMAL, 390.0, 130.0],
		[Platform.Kind.BREAKABLE, 110.0, 250.0],
		[Platform.Kind.VANISHING, 250.0, 250.0],
	]
	var made: Array[Platform] = []
	for row: Array in rows:
		var platform: Platform = main._add_platform(row[0], row[2], 0.0)
		platform.position.x = row[1]
		made.append(platform)
	made[0].add_spring()
	made[2].add_item(Platform.Item.JETPACK)
	var items := [Platform.Item.SHIELD, Platform.Item.HEART, Platform.Item.BOMB, Platform.Item.TRIPLE]
	for i in items.size():
		var platform: Platform = main._add_platform(Platform.Kind.NORMAL, 490.0, 0.0)
		platform.position.x = 60.0 + 120.0 * i
		platform.add_item(items[i])
	player.ammo = 2
	player.jumps_since_reload = 2
	player.shield = true
	player.lives = 2
	player.bombs = 3
	player.triple_left = 8.0
	for variant in [Monster.Variant.SPIKY, Monster.Variant.BAT]:
		var chosen := Monster.new()
		chosen.position = Vector2(130.0 + 220.0 * variant, 370.0)
		chosen.setup(0.0, variant)
		main.monsters.add_child(chosen)


func _teleport(y: float) -> void:
	player.position = Vector2(240.0, y)
	player.velocity = Vector2(0.0, -300.0)


func _tap_space() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	var release := InputEventKey.new()
	release.physical_keycode = KEY_SPACE
	Input.parse_input_event(release)
	await process_frame


func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [shots_dir, shot_name])
	print("captura: ", shot_name)


func _physics_process(_delta: float) -> bool:
	if player == null or main.state == 0:
		return false
	frame += 1
	_collect_stats()
	if main.state == 2:
		_finish_run()
	else:
		_drive()
	if main.score > stall_score:
		stall_score = main.score
		stall_frame = frame
	if main.state == 1 and frame - stall_frame > STALL_LIMIT:
		_report_stall()
		return true
	if shots_dir.is_empty() and frame >= MAX_FRAMES:
		_report()
		return true
	return false


func _drive() -> void:
	var rise := player.velocity.y * player.velocity.y / (2.0 * Cfg.GRAVITY) if player.velocity.y < 0.0 else 0.0
	var ceiling := player.feet_y() - rise + 5.0
	var target: Platform = null
	for platform: Platform in main.platforms.get_children():
		if not platform.solid or platform.kind == Platform.Kind.BREAKABLE:
			continue
		var top := platform.top_y()
		if top >= ceiling and (target == null or top < target.top_y()):
			target = platform
	var dx := 0.0
	if target != null:
		dx = wrapf(target.position.x - player.position.x, -Cfg.VIEW_W * 0.5, Cfg.VIEW_W * 0.5)
	_press("move_right", dx > 8.0)
	_press("move_left", dx < -8.0)
	for monster: Monster in main.monsters.get_children():
		if monster.position.y < player.position.y and absf(monster.position.x - player.position.x) < 40.0:
			main.shoot()
			break
		if player.position.distance_to(monster.position) < 150.0:
			main.use_bomb()
			break


func _report_stall() -> void:
	print("TRAVOU frame=%d pontos=%d jogador=%s vel=%s camera_y=%d next_y=%d" % [
		frame, main.score, player.position, player.velocity, main.camera.position.y, main.next_platform_y
	])
	for platform: Platform in main.platforms.get_children():
		print("  plataforma tipo=%d solida=%s pos=%s topo=%d" % [
			platform.kind, platform.solid, platform.position, platform.top_y()
		])
	_report()


func _press(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _collect_stats() -> void:
	if player.velocity.y < -1400.0 and last_vy >= -1400.0 and not player.has_jetpack():
		springs += 1
	if player.has_jetpack() and not was_jetpack:
		jetpacks += 1
	if was_alive and not player.alive:
		deaths_by_monster += 1
	if player.lives < last_lives:
		revives += 1
	if last_shield and not player.shield:
		shields_used += 1
	if player.bombs < last_bombs:
		bombs_used += 1
	if player.triple_left > last_triple:
		triples += 1
	last_lives = player.lives
	last_shield = player.shield
	last_bombs = player.bombs
	last_triple = player.triple_left
	var monster_count: int = main.monsters.get_child_count()
	if monster_count < last_monsters:
		kills += last_monsters - monster_count
	last_monsters = monster_count
	was_alive = player.alive
	was_jetpack = player.has_jetpack()
	last_vy = player.velocity.y


func _finish_run() -> void:
	runs += 1
	scores.append(main.score)
	peak_score = maxi(peak_score, main.score)
	if player.alive:
		deaths_by_fall += 1
		print("queda: pontos=%d altura=%d" % [main.score, Cfg.START_Y - player.position.y])
	if shots_dir.is_empty():
		main.start_game()
		last_monsters = 0
		was_alive = true
		stall_score = 0
		stall_frame = frame


func _report() -> void:
	scores.sort()
	print("frames=%d partidas=%d recorde=%d mediana=%d" % [
		frame, runs, peak_score, scores[scores.size() / 2] if runs > 0 else main.score
	])
	print("mortes: monstro=%d queda=%d | molas=%d jetpacks=%d monstros_removidos=%d" % [
		deaths_by_monster, deaths_by_fall, springs, jetpacks, kills
	])
	print("buffs usados: revives=%d escudos=%d bombas=%d triplos=%d" % [
		revives, shields_used, bombs_used, triples
	])
	print("placar atual=%d nos: plataformas=%d monstros=%d tiros=%d efeitos=%d" % [
		main.score, main.platforms.get_child_count(), main.monsters.get_child_count(),
		main.bullets.get_child_count(), main.effects.get_child_count()
	])
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://bot_test.cfg"))
