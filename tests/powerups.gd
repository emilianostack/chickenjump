extends SceneTree
## Verifica cada buff em cena controlada.
## Uso: godot --headless --fixed-fps 60 --path . --script res://tests/powerups.gd

var main: Node2D
var player: Player
var failures := 0


func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	main.save_path = "user://powerups_test.cfg"
	root.add_child(main)
	await process_frame
	player = main.player
	await _run_all()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://powerups_test.cfg"))
	print("falhas: ", failures)
	quit(1 if failures > 0 else 0)


func _run_all() -> void:
	# Clique sobre o painel precisa iniciar a partida.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(240.0, 400.0)
	Input.parse_input_event(click)
	await process_frame
	await process_frame
	_check("clique no painel inicia", main.state == 1)

	await _test_stomp()
	await _test_shield()
	await _test_heart_on_hit()
	await _test_heart_on_fall()
	await _test_death_without_buffs()
	await _test_bomb()
	await _test_bomb_key()
	await _test_triple()
	await _test_pickups()
	await _test_caps_and_reset()
	await _test_wing_poses()
	await _test_ammo()
	await _test_shield_items_hidden()


func _fresh() -> void:
	main.start_game()
	# Sem plataformas ou monstros gerados, so resta o que cada teste criar.
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


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _alive_monsters() -> int:
	var count := 0
	for monster in main.monsters.get_children():
		if not monster.is_queued_for_deletion():
			count += 1
	return count


func _test_stomp() -> void:
	_fresh()
	player.velocity = Vector2(0.0, 300.0)
	_monster_at(player.position + Vector2(0.0, 40.0))
	await _frames(2)
	_check("pisar destroi monstro", _alive_monsters() == 0 and player.alive)
	_check("pisar da impulso", player.velocity.y < 0.0)


func _test_shield() -> void:
	_fresh()
	player.shield = true
	_monster_at(player.position + Vector2(40.0, 0.0))
	await _frames(2)
	_check("escudo: sobrevive", player.alive)
	_check("escudo: e consumido", not player.shield)
	_check("escudo: destroi o monstro", _alive_monsters() == 0)
	_check("escudo: protege em seguida", player.is_protected())
	_monster_at(player.position + Vector2(40.0, 0.0))
	await _frames(2)
	_check("escudo: segundo monstro nao mata na protecao", player.alive)
	player.protected_left = 0.0
	player.velocity.y = -200.0
	_monster_at(player.position + Vector2(40.0, 0.0))
	await _frames(2)
	_check("escudo: sem protecao o monstro volta a matar", not player.alive)


func _test_heart_on_hit() -> void:
	_fresh()
	player.lives = 2
	_monster_at(player.position + Vector2(40.0, 0.0))
	await _frames(2)
	_check("vida: sobrevive ao golpe", player.alive)
	_check("vida: gasta uma", player.lives == 1)
	_check("vida: fica protegido", player.protected_left > 0.0)
	_check("vida: sobe", player.velocity.y < 0.0)


func _test_heart_on_fall() -> void:
	_fresh()
	player.lives = 1
	player.position.y = main.camera.position.y + Cfg.VIEW_H * 0.5 + 100.0
	player.velocity = Vector2(0.0, 600.0)
	await _frames(2)
	_check("queda: partida continua", main.state == 1)
	_check("queda: gasta a vida", player.lives == 0)
	_check("queda: volta para a tela", player.position.y < main.camera.position.y + Cfg.VIEW_H * 0.5 + 60.0)
	_check("queda: e lancado para cima", player.velocity.y < 0.0)


func _test_death_without_buffs() -> void:
	_fresh()
	_monster_at(player.position + Vector2(40.0, 0.0))
	await _frames(2)
	_check("sem buffs: monstro mata", not player.alive)
	await _frames(240)
	_check("sem buffs: fim de jogo", main.state == 2)


func _test_bomb() -> void:
	_fresh()
	player.bombs = 2
	main.use_bomb()
	_check("bomba: sem alvos nao gasta", player.bombs == 2)
	_monster_at(Vector2(100.0, 200.0))
	_monster_at(Vector2(380.0, 300.0))
	var far := _monster_at(Vector2(240.0, -900.0))
	main.use_bomb()
	await _frames(1)
	_check("bomba: gasta uma", player.bombs == 1)
	_check("bomba: poupa monstro fora da tela", _alive_monsters() == 1 and is_instance_valid(far))


func _test_bomb_key() -> void:
	_fresh()
	player.bombs = 1
	_monster_at(Vector2(100.0, 200.0))
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	await process_frame
	var release := InputEventKey.new()
	release.physical_keycode = KEY_E
	Input.parse_input_event(release)
	await process_frame
	_check("bomba: tecla E funciona", player.bombs == 0 and _alive_monsters() == 0)


func _test_triple() -> void:
	_fresh()
	main.shoot()
	_check("tiro normal: 1 projetil", main.bullets.get_child_count() == 1)
	for bullet in main.bullets.get_children():
		bullet.free()
	player.shoot_cooldown = 0.0
	player.triple_left = 5.0
	main.shoot()
	_check("tiro triplo: 3 projeteis", main.bullets.get_child_count() == 3)
	await _frames(10)
	var spread := 0.0
	for bullet: Bullet in main.bullets.get_children():
		spread = maxf(spread, absf(bullet.position.x - player.position.x))
	_check("tiro triplo: abre em leque", spread > 15.0)
	player.triple_left = 0.02
	await _frames(3)
	_check("tiro triplo: expira", player.triple_left == 0.0)


func _test_pickups() -> void:
	var cases := [
		[Platform.Item.SHIELD, func() -> bool: return player.shield],
		[Platform.Item.HEART, func() -> bool: return player.lives == 1],
		[Platform.Item.BOMB, func() -> bool: return player.bombs == 1],
		[Platform.Item.TRIPLE, func() -> bool: return player.triple_left > 0.0],
		[Platform.Item.JETPACK, func() -> bool: return player.has_jetpack()],
	]
	for entry: Array in cases:
		_fresh()
		var platform: Platform = main._add_platform(Platform.Kind.NORMAL, player.position.y + 32.0, 0.0)
		platform.position.x = player.position.x
		platform.add_item(entry[0])
		await _frames(2)
		_check("pegar item %d" % entry[0], entry[1].call() and platform.item == Platform.Item.NONE)


func _test_caps_and_reset() -> void:
	_fresh()
	player.lives = Cfg.MAX_LIVES
	player.bombs = Cfg.MAX_BOMBS
	main._apply_item(Platform.Item.HEART)
	main._apply_item(Platform.Item.BOMB)
	_check("limite de vidas e bombas", player.lives == Cfg.MAX_LIVES and player.bombs == Cfg.MAX_BOMBS)
	player.shield = true
	player.triple_left = 5.0
	main.start_game()
	_check("nova partida zera buffs", player.lives == 0 and player.bombs == 0 and not player.shield and player.triple_left == 0.0)


func _test_wing_poses() -> void:
	_fresh()
	player.velocity = Vector2(0.0, -400.0)
	await _frames(1)
	_check("galinha: sobe de asas fechadas", player.body.texture == Player.TEXTURE_RISING)
	player.velocity = Vector2(0.0, 200.0)
	await _frames(1)
	_check("galinha: cai de asas abertas", player.body.texture == Player.TEXTURE_FALLING)
	player.velocity.x = -300.0
	player.facing = -1.0
	await _frames(1)
	_check("galinha: vira para a esquerda", player.body.flip_h)
	player.kill()
	await _frames(1)
	_check("galinha: pose de derrota", player.body.texture == Player.TEXTURE_DEAD)


func _fire_ready() -> void:
	player.shoot_cooldown = 0.0
	main.shoot()


func _test_ammo() -> void:
	_fresh()
	_check("municao: comeca cheia", player.ammo == Cfg.MAX_AMMO)
	for i in Cfg.MAX_AMMO:
		_fire_ready()
	_check("municao: todos os tiros saem", main.bullets.get_child_count() == Cfg.MAX_AMMO)
	_check("municao: fica vazia", player.ammo == 0)
	_fire_ready()
	_check("municao: vazia nao atira", main.bullets.get_child_count() == Cfg.MAX_AMMO)
	_check("municao: nao fica negativa", player.ammo == 0)

	# Pouso real, com a fisica do jogo, numa plataforma logo abaixo.
	var platform: Platform = main._add_platform(Platform.Kind.NORMAL, player.feet_y() + 30.0, 0.0)
	platform.position.x = player.position.x
	player.velocity = Vector2(0.0, 300.0)
	await _frames(20)
	_check("recarga: pouso conta como pulo", player.jumps_since_reload == 1)
	_check("recarga: 1 pulo ainda nao devolve tiro", player.ammo == 0)

	var breakable: Platform = main._add_platform(Platform.Kind.BREAKABLE, 300.0, 0.0)
	main._land_on(breakable)
	_check("recarga: tabua quebrada nao conta", player.jumps_since_reload == 1)

	for i in Cfg.JUMPS_PER_SHOT - 1:
		main._count_jump()
	_check("recarga: devolve um tiro", player.ammo == 1 and player.jumps_since_reload == 0)
	_fire_ready()
	_check("recarga: tiro recarregado funciona", main.bullets.get_child_count() == Cfg.MAX_AMMO + 1)

	_fresh()
	player.ammo = 0
	var spring: Platform = main._add_platform(Platform.Kind.NORMAL, 300.0, 0.0)
	spring.add_spring()
	player.position.x = spring.position.x + spring.spring_x
	main._land_on(spring)
	_check("recarga: mola conta", player.jumps_since_reload == 1)
	player.position = Vector2(240.0, 400.0)
	player.velocity = Vector2(0.0, 300.0)
	_monster_at(player.position + Vector2(0.0, 40.0))
	await _frames(2)
	_check("recarga: pisar em monstro conta", player.jumps_since_reload == 2)

	_fresh()
	player.ammo = Cfg.MAX_AMMO
	for i in Cfg.JUMPS_PER_SHOT * 2:
		main._count_jump()
	_check("recarga: nao passa do maximo", player.ammo == Cfg.MAX_AMMO and player.jumps_since_reload == 0)

	_fresh()
	player.triple_left = 5.0
	_fire_ready()
	_check("tiro triplo: gasta 1 de municao", player.ammo == Cfg.MAX_AMMO - 1)
	_check("tiro triplo: lanca 3", main.bullets.get_child_count() == 3)

	player.ammo = 0
	main.start_game()
	_check("municao: nova partida recarrega", player.ammo == Cfg.MAX_AMMO)


func _item_platform(item: Platform.Item, offset_x: float) -> Platform:
	var platform: Platform = main._add_platform(Platform.Kind.NORMAL, player.position.y + 32.0, 0.0)
	platform.position.x = player.position.x + offset_x
	platform.add_item(item)
	return platform


func _test_shield_items_hidden() -> void:
	_fresh()
	player.shield = true
	var under := _item_platform(Platform.Item.SHIELD, 0.0)
	var far := _item_platform(Platform.Item.SHIELD, 150.0)
	var heart := _item_platform(Platform.Item.HEART, -150.0)
	await _frames(2)
	_check("escudo oculto: icone invisivel", not under.item_sprite.visible and not far.item_sprite.visible)
	_check("escudo oculto: nao e coletado", under.item == Platform.Item.SHIELD and player.shield)
	_check("escudo oculto: outros itens seguem visiveis", heart.item_sprite.visible)

	# Perdendo o escudo, o icone volta e pode ser pego de novo.
	player.position.x = far.position.x + 200.0
	player.shield = false
	player.velocity = Vector2(0.0, -100.0)
	await _frames(2)
	_check("escudo oculto: reaparece sem escudo", far.item_sprite.visible and under.item_sprite.visible)
	player.position = far.item_position()
	await _frames(2)
	_check("escudo oculto: volta a ser coletavel", player.shield and far.item == Platform.Item.NONE)


func _check(label: String, passed: bool) -> void:
	print(("ok    " if passed else "FALHA ") + label)
	if not passed:
		failures += 1
