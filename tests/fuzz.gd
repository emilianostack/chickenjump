extends SceneTree
## Teste de estresse: entradas aleatorias reais e regras conferidas a cada frame.
## Uso: godot --headless --fixed-fps 60 --path . --script res://tests/fuzz.gd -- --frames=150000 --seed=1

const MENU := 0
const PLAYING := 1
const GAME_OVER := 2
const DEATH_FRAME_LIMIT := 900
const LASTING_FRAMES := 3
const KEYS: Array[Key] = [KEY_SPACE, KEY_ENTER, KEY_E, KEY_W, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D]

var main: Node2D
var player: Player
var frame := 0
var max_frames := 150000
var violations := {}
var streaks := {}
var runs := 0
var last_state := MENU
var steering := false
var last_score := 0
var last_camera := 0.0
var last_chain_y := INF
var dead_frames := 0
var peak := {"score": 0, "plataformas": 0, "monstros": 0, "tiros": 0, "efeitos": 0}
var seen := {}


func _initialize() -> void:
	var run_seed := 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--frames="):
			max_frames = int(arg.trim_prefix("--frames="))
		if arg.begins_with("--seed="):
			run_seed = int(arg.trim_prefix("--seed="))
	seed(run_seed)
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://fuzz_test.cfg"
	root.add_child(main)
	await process_frame
	player = main.player


func _physics_process(_delta: float) -> bool:
	if player == null:
		return false
	frame += 1
	_note_run_changes()
	_act()
	_verify()
	if frame >= max_frames:
		_report()
		return true
	return false


func _note_run_changes() -> void:
	var state: int = main.state
	if state == PLAYING and last_state != PLAYING:
		runs += 1
		steering = randf() < 0.4
		last_score = 0
		last_camera = main.camera.position.y
		dead_frames = 0
	last_state = state


func _act() -> void:
	if randf() < 0.02:
		_tap_key(KEYS.pick_random())
	if randf() < 0.01:
		_click(Vector2(randf() * 432.0, randf() * 720.0), [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT].pick_random())
	if main.state == PLAYING:
		if randf() < 0.0003:
			main._apply_item(randi_range(Platform.Item.JETPACK, Platform.Item.TRIPLE))
		if steering:
			_steer()
		else:
			if randf() < 0.05:
				_set_axis(randi_range(-1, 1))
	elif main.state == MENU or main.state == GAME_OVER:
		_set_axis(0)
		if randf() < 0.03:
			_tap_key(KEY_SPACE)


func _steer() -> void:
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
	_set_axis(1 if dx > 8.0 else (-1 if dx < -8.0 else 0))


func _set_axis(axis: int) -> void:
	if axis > 0:
		Input.action_press("move_right")
	else:
		Input.action_release("move_right")
	if axis < 0:
		Input.action_press("move_left")
	else:
		Input.action_release("move_left")


func _tap_key(key_code: Key) -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.physical_keycode = key_code
		key.pressed = pressed
		Input.parse_input_event(key)


func _click(at: Vector2, button: MouseButton) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = button
		event.pressed = pressed
		event.position = at
		event.global_position = at
		Input.parse_input_event(event)


func _verify() -> void:
	_rule("municao fora do limite", player.ammo >= 0 and player.ammo <= Cfg.MAX_AMMO)
	_rule("contador de recarga fora do limite", player.jumps_since_reload >= 0 and player.jumps_since_reload < Cfg.JUMPS_PER_SHOT)
	_rule("municao cheia com recarga em andamento", player.ammo < Cfg.MAX_AMMO or player.jumps_since_reload == 0)
	_rule("vidas fora do limite", player.lives >= 0 and player.lives <= Cfg.MAX_LIVES)
	_rule("bombas fora do limite", player.bombs >= 0 and player.bombs <= Cfg.MAX_BOMBS)
	_rule("jogador fora da largura", player.position.x >= 0.0 and player.position.x < Cfg.VIEW_W)
	_rule("posicao invalida", player.position.is_finite() and player.velocity.is_finite())
	_rule("idioma invalido", main.language >= 0 and main.language < main.LANGUAGES.size())
	_rule("painel errado para o estado", main.panel.visible == (main.state != PLAYING))
	_rule("seletor de idioma fora do menu", main.language_row.visible == (main.state == MENU) or main.state == PLAYING)
	_lasting_rule("camera sem acompanhar", main.sky.camera_top == main.camera.position.y - Cfg.VIEW_H * 0.5)
	_lasting_rule("HUD de pontos errado", main.state == MENU or main.score_label.text == str(main.score))
	_lasting_rule("HUD de municao errado", main.power_bar.slots.ammo.label.text == "%d/%d" % [player.ammo, Cfg.MAX_AMMO])
	_lasting_rule("bolha sem escudo", player.bubble.visible == player.shield)
	_rule("morto com escudo", player.alive or not player.shield)
	_rule("morto com vidas", player.alive or player.lives == 0)
	_rule("recorde menor que pontos no fim", main.state != GAME_OVER or main.best >= main.score)
	if main.state != PLAYING:
		return
	_rule("pontos diminuiram", main.score >= last_score)
	last_score = main.score
	_rule("camera desceu", main.camera.position.y <= last_camera)
	last_camera = main.camera.position.y
	var bottom: float = main.camera.position.y + Cfg.VIEW_H * 0.5
	_rule("jogador abaixo da tela sem fim de jogo", player.position.y <= bottom + 120.0)
	_verify_nodes(bottom)
	if player.alive:
		dead_frames = 0
	else:
		dead_frames += 1
		_rule("morto sem chegar ao fim de jogo", dead_frames < DEATH_FRAME_LIMIT)


func _verify_nodes(bottom: float) -> void:
	var permanent: Array[float] = []
	for platform: Platform in main.platforms.get_children():
		if platform.is_queued_for_deletion():
			continue
		if platform.position.x < 0.0 or platform.position.x > Cfg.VIEW_W:
			_rule("plataforma fora da largura", false)
		if platform.position.y > bottom + 2000.0 and platform.solid:
			_rule("plataforma velha nao removida", false)
		if platform.kind <= Platform.Kind.MOVING:
			permanent.append(platform.position.y)
		if platform.item == Platform.Item.SHIELD and player.shield and player.alive and platform.item_sprite.visible:
			seen["shield_frames"] = seen.get("shield_frames", 0) + 1
			if seen.shield_frames > LASTING_FRAMES * main.platforms.get_child_count():
				_rule("icone de escudo visivel com escudo", false)
		if platform.has_spring:
			seen["mola"] = true
		if platform.kind == Platform.Kind.VANISHING:
			seen["nuvem"] = true
	if not player.shield:
		seen["shield_frames"] = 0
	permanent.sort()
	for i in range(1, permanent.size()):
		_rule("vao maior que o pulo no caminho garantido", permanent[i] - permanent[i - 1] <= Cfg.GAP_MAX_HARD + 1.0)
	peak.score = maxi(peak.score, main.score)
	peak.plataformas = maxi(peak.plataformas, main.platforms.get_child_count())
	peak.monstros = maxi(peak.monstros, main.monsters.get_child_count())
	peak.tiros = maxi(peak.tiros, main.bullets.get_child_count())
	peak.efeitos = maxi(peak.efeitos, main.effects.get_child_count())
	_rule("plataformas demais", main.platforms.get_child_count() < 80)
	_rule("monstros demais", main.monsters.get_child_count() < 12)
	_rule("tiros demais", main.bullets.get_child_count() < 60)
	_rule("efeitos demais", main.effects.get_child_count() < 150)
	for bullet: Bullet in main.bullets.get_children():
		if bullet.position.y > bottom + 100.0:
			_rule("tiro abaixo da tela", false)


## O teste roda antes do jogo no mesmo frame, entao telas podem estar um frame atrasadas.
## So conta como erro o que continuar errado por alguns frames.
func _lasting_rule(label: String, passed: bool) -> void:
	var streak: int = 0 if passed else streaks.get(label, 0) + 1
	streaks[label] = streak
	_rule(label, streak < LASTING_FRAMES)


func _rule(label: String, passed: bool) -> void:
	if passed:
		return
	if not violations.has(label):
		violations[label] = {"count": 0, "frame": frame, "score": main.score, "state": main.state}
	violations[label].count += 1


func _report() -> void:
	_set_axis(0)
	print("frames=%d partidas=%d maximos=%s" % [frame, runs, peak])
	print("viu: ", seen.keys())
	for label: String in violations:
		var entry: Dictionary = violations[label]
		print("VIOLACAO %s: %d vezes, primeira no frame %d (pontos=%d estado=%d)" % [
			label, entry.count, entry.frame, entry.score, entry.state
		])
	print("violacoes: ", violations.size())
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://fuzz_test.cfg"))
