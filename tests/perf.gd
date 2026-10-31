extends SceneTree
## Mede o desempenho com janela real, sem limitar por frames fixos.
## Uso: godot --path . --script res://tests/perf.gd -- --mode=normal
## --mode=heavy adiciona tiros e particulas o tempo todo.

const WARMUP := 30
const SAMPLES := 300
const TIME_LIMIT_MS := 45000

var main: Node2D
var player: Player
var heavy := false
var height := 0.0
var restarts := 0
var started_at := 0
var frame := 0
var times: Array[float] = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--mode=heavy":
			heavy = true
		if arg.begins_with("--height="):
			height = float(arg.trim_prefix("--height="))
	started_at = Time.get_ticks_msec()
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://perf_test.cfg"
	root.add_child(main)
	await process_frame
	player = main.player
	print("carga da cena: %d ms" % (Time.get_ticks_msec() - started_at))
	_start_run()


func _start_run() -> void:
	main.start_game()
	if height != 0.0:
		player.position.y = height
		player.velocity.y = -300.0
		await physics_frame
		await physics_frame
		print("altura %d: plataformas=%d" % [height, main.platforms.get_child_count()])


func _process(delta: float) -> bool:
	if player == null:
		return false
	frame += 1
	if main.state != 1:
		restarts += 1
		_start_run()
		return false
	# Evita o fim de jogo: a medicao fica sempre em partida.
	player.lives = 3
	player.protected_left = 1.0
	if heavy and frame % 4 == 0:
		main._add_puff(player.position + Vector2(randf_range(-100.0, 100.0), -100.0), Color.WHITE, 16)
		player.shoot_cooldown = 0.0
		player.ammo = Cfg.MAX_AMMO
		player.triple_left = 1.0
		main.shoot()
	if frame > WARMUP:
		times.append(delta * 1000.0)
	if frame % 60 == 0:
		print("frame %d, %d ms" % [frame, Time.get_ticks_msec() - started_at])
	var out_of_time := Time.get_ticks_msec() - started_at > TIME_LIMIT_MS
	if times.size() < SAMPLES and not out_of_time:
		return false
	_report(out_of_time)
	return true


func _report(out_of_time: bool) -> void:
	times.sort()
	var total := 0.0
	for value in times:
		total += value
	var count := maxi(times.size(), 1)
	print("%s: quadros=%d media=%.1f ms (%.0f fps) p99=%.1f ms pior=%.1f ms estourou_tempo=%s" % [
		"pesado" if heavy else "normal", times.size(), total / count, 1000.0 / maxf(total / count, 0.001),
		times[int(count * 0.99)] if times.size() > 0 else 0.0, times[-1] if times.size() > 0 else 0.0,
		out_of_time
	])
	print("efeitos=%d tiros=%d plataformas=%d reinicios=%d y=%d" % [
		main.effects.get_child_count(), main.bullets.get_child_count(), main.platforms.get_child_count(),
		restarts, player.position.y
	])
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://perf_test.cfg"))
