extends Node2D

enum State { MENU, PLAYING, GAME_OVER }

const RESTART_DELAY := 0.5
const ITEM_REACH := 46.0
const PANEL_BOTTOM_MENU := 626.0
const PANEL_BOTTOM_GAME_OVER := 556.0
const UI_FONT := preload("res://assets/fonts/LilitaOne-Regular.ttf")
# Letras que a fonte principal nao tem: cirilico, coreano e chines.
const FALLBACK_FONTS: Array[Font] = [
	preload("res://assets/fonts/RussoOne-Regular.ttf"),
	preload("res://assets/fonts/Jua-Regular.ttf"),
	preload("res://assets/fonts/ZCOOLKuaiLe-Regular.ttf"),
]
# Cada idioma aparece escrito na propria lingua.
const LANGUAGES := [
	["pt_BR", "Português"],
	["en", "English"],
	["es", "Español"],
	["fr", "Français"],
	["ru", "Русский"],
	["ko", "한국어"],
	["zh_CN", "中文"],
	["de", "Deutsch"],
	["it", "Italiano"],
]
const ITEM_CHANCES := {
	Platform.Item.JETPACK: Cfg.JETPACK_CHANCE,
	Platform.Item.SHIELD: Cfg.SHIELD_CHANCE,
	Platform.Item.HEART: Cfg.HEART_CHANCE,
	Platform.Item.BOMB: Cfg.BOMB_CHANCE,
	Platform.Item.TRIPLE: Cfg.TRIPLE_CHANCE,
}

var save_path := "user://save.cfg"
var state := State.MENU
var score := 0
var best := 0
var highest_y := Cfg.PLAYER_START_Y
var next_platform_y := Cfg.START_Y
var last_monster_y := Cfg.START_Y
var restart_wait := 0.0
var language := 0
var touch_ui := false

@onready var sky := $Background/Sky
@onready var platforms: Node2D = $Platforms
@onready var monsters: Node2D = $Monsters
@onready var bullets: Node2D = $Bullets
@onready var effects: Node2D = $Effects
@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var sfx: Sfx = $Sfx
@onready var score_label: Label = $HUD/Score
@onready var best_label: Label = $HUD/Best
@onready var power_bar: PowerBar = $HUD/PowerBar
@onready var flash: ColorRect = $HUD/Flash
@onready var panel: Panel = $HUD/Panel
@onready var title: Label = $HUD/Panel/Title
@onready var message: Label = $HUD/Panel/Message
@onready var prompt: Label = $HUD/Panel/Prompt
@onready var language_row: HBoxContainer = $HUD/Panel/LanguageRow
@onready var language_label: Label = $HUD/Panel/LanguageRow/Language
@onready var language_previous: Button = $HUD/Panel/LanguageRow/Previous
@onready var language_next: Button = $HUD/Panel/LanguageRow/Next
@onready var ranking: Ranking = $Ranking
@onready var ranking_button: Button = $HUD/RankingButton
@onready var ranking_panel: RankingPanel = $HUD/RankingPanel
@onready var touch_controls: TouchControls = $HUD/TouchControls


func _ready() -> void:
	var font: Font = UI_FONT
	font.fallbacks = FALLBACK_FONTS
	font.allow_system_fallback = false
	language_previous.pressed.connect(change_language.bind(-1))
	language_next.pressed.connect(change_language.bind(1))
	ranking_button.pressed.connect(open_ranking)
	ranking.changed.connect(_save_game)
	touch_ui = DisplayServer.is_touchscreen_available()
	_load_save()
	_apply_language()
	_reset_world()
	_show_menu()


func open_ranking() -> void:
	ranking_panel.open(ranking, best)


func change_language(step: int) -> void:
	language = wrapi(language + step, 0, LANGUAGES.size())
	_apply_language()
	_update_best_label()
	_show_menu()
	_save_game()


func _apply_language() -> void:
	TranslationServer.set_locale(LANGUAGES[language][0])
	language_label.text = LANGUAGES[language][1]
	ranking_button.text = tr("RANKING")


func _show_menu() -> void:
	var help := [tr("HELP_MOVE"), tr("HELP_SHOOT"), tr("HELP_BOMB")]
	if touch_ui:
		help = [tr("HELP_TOUCH")]
	help.append(tr("HELP_RELOAD"))
	_show_message(
		"CHICKEN\nJUMP",
		"\n".join(help),
		tr("PROMPT_TOUCH_START" if touch_ui else "PROMPT_START")
	)
	language_row.show()
	panel.offset_bottom = PANEL_BOTTOM_MENU


func _process(_delta: float) -> void:
	if panel.visible:
		prompt.modulate.a = 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.005)


func start_game() -> void:
	_reset_world()
	state = State.PLAYING
	panel.hide()
	ranking_button.hide()
	touch_controls.show()


func shoot() -> void:
	if not player.alive or player.has_jetpack() or player.shoot_cooldown > 0.0:
		return
	player.shoot_cooldown = Cfg.SHOOT_COOLDOWN
	if player.ammo == 0:
		_add_toast(tr("TOAST_NO_AMMO"))
		sfx.play("empty")
		return
	player.ammo -= 1
	_add_bullet(0.0)
	if player.triple_left > 0.0:
		_add_bullet(-Cfg.TRIPLE_SPREAD)
		_add_bullet(Cfg.TRIPLE_SPREAD)
	sfx.play("shoot")


func _add_bullet(drift: float) -> void:
	var bullet := Bullet.new()
	bullet.position = player.position + Vector2(0.0, -Player.RADIUS)
	bullet.drift = drift
	bullets.add_child(bullet)


## Destroi os monstros visiveis. Sem alvos na tela, a bomba nao e gasta.
func use_bomb() -> void:
	if state != State.PLAYING or not player.alive or player.bombs == 0:
		return
	var half_height := Cfg.VIEW_H * 0.5
	var targets: Array[Monster] = []
	for monster in _living_monsters():
		if absf(monster.position.y - camera.position.y) < half_height:
			targets.append(monster)
	if targets.is_empty():
		_add_toast(tr("TOAST_NO_MONSTERS"))
		return
	player.bombs -= 1
	for monster in targets:
		_destroy_monster(monster)
	flash.modulate.a = 0.85
	create_tween().tween_property(flash, "modulate:a", 0.0, 0.4)
	sfx.play("bomb")


func _unhandled_input(event: InputEvent) -> void:
	if ranking_panel.visible:
		return
	# No toque o sistema tambem gera um clique; durante a partida quem atira e o botao de tiro.
	if state == State.PLAYING and event is InputEventMouseButton:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
	if state == State.MENU:
		if event.is_action_pressed("move_left"):
			change_language(-1)
			return
		if event.is_action_pressed("move_right"):
			change_language(1)
			return
	if event.is_action_pressed("bomb"):
		use_bomb()
		return
	if not (event.is_action_pressed("shoot") or event.is_action_pressed("ui_accept")):
		return
	match state:
		State.MENU:
			start_game()
		State.PLAYING:
			shoot()
		State.GAME_OVER:
			if restart_wait <= 0.0:
				start_game()


func _physics_process(delta: float) -> void:
	if state == State.GAME_OVER:
		restart_wait -= delta
	if state != State.PLAYING:
		return
	var previous_feet := player.feet_y()
	player.step(delta, Input.get_axis("move_left", "move_right"))
	if player.alive and not player.has_jetpack():
		_check_landing(previous_feet)
	if player.alive:
		_check_item_pickup()
		_check_monsters()
	_check_bullets()
	_update_camera()
	_spawn_ahead()
	_cull_below()
	_update_score()
	_update_power_bar()
	var bottom := camera.position.y + Cfg.VIEW_H * 0.5
	if player.position.y > bottom + 60.0:
		if player.lives > 0:
			_revive(Vector2(player.position.x, bottom))
		else:
			_end_game()


func _check_landing(previous_feet: float) -> void:
	if player.velocity.y <= 0.0:
		return
	var feet := player.feet_y()
	var reach := Platform.WIDTH * 0.5 + Player.RADIUS * 0.6
	var target: Platform = null
	var target_top := INF
	for platform: Platform in platforms.get_children():
		if not platform.solid or absf(player.position.x - platform.position.x) > reach:
			continue
		var top := platform.top_y()
		if platform.hits_spring(player.position.x):
			top -= Platform.SPRING_HEIGHT
		if previous_feet <= top and feet >= top and top < target_top:
			target = platform
			target_top = top
	if target != null:
		_land_on(target)


func _land_on(platform: Platform) -> void:
	var feet := Vector2(player.position.x, player.feet_y())
	if platform.kind == Platform.Kind.BREAKABLE:
		platform.break_apart()
		_add_puff(feet, Color(0.72, 0.5, 0.3), 10)
		sfx.play("break")
	elif platform.hits_spring(player.position.x):
		platform.use_spring()
		player.bounce(Cfg.SPRING_VELOCITY)
		_count_jump()
		_add_puff(feet, Color(1.0, 0.9, 0.5), 10)
		sfx.play("spring")
	else:
		player.bounce(Cfg.JUMP_VELOCITY)
		_count_jump()
		_add_puff(feet, Color(1.0, 1.0, 1.0, 0.8), 5)
		sfx.play("jump")
		if platform.kind == Platform.Kind.VANISHING:
			platform.vanish()
			_add_puff(platform.position, Color.WHITE, 12)


func _count_jump() -> void:
	if player.add_jump():
		sfx.play("reload")


func _add_puff(at: Vector2, tint: Color, count: int) -> void:
	var puff := Puff.new(tint, count)
	puff.position = at
	effects.add_child(puff)


## Monstros destruidos so saem da arvore no fim do frame; ate la, ja nao contam.
func _living_monsters() -> Array[Monster]:
	var living: Array[Monster] = []
	for monster: Monster in monsters.get_children():
		if not monster.is_queued_for_deletion():
			living.append(monster)
	return living


func _destroy_monster(monster: Monster) -> void:
	_add_puff(monster.position, Color(1.0, 0.75, 0.4), 16)
	monster.queue_free()


func _add_toast(content: String) -> void:
	effects.add_child(Toast.new(player.position + Vector2(0.0, -70.0), content))


func _check_item_pickup() -> void:
	for platform: Platform in platforms.get_children():
		if platform.item == Platform.Item.NONE:
			continue
		# Quem ja tem escudo nao ve nem pega outro.
		var available := platform.item != Platform.Item.SHIELD or not player.shield
		platform.item_sprite.visible = available
		if available and player.position.distance_to(platform.item_position()) < ITEM_REACH:
			var item := platform.item
			platform.take_item()
			_apply_item(item)
			return


func _apply_item(item: Platform.Item) -> void:
	sfx.play("item")
	match item:
		Platform.Item.JETPACK:
			player.jetpack_left = Cfg.JETPACK_TIME
			sfx.play("jetpack")
		Platform.Item.SHIELD:
			player.shield = true
			_add_toast(tr("TOAST_SHIELD"))
		Platform.Item.HEART:
			player.lives = mini(player.lives + 1, Cfg.MAX_LIVES)
			_add_toast(tr("TOAST_HEART"))
		Platform.Item.BOMB:
			player.bombs = mini(player.bombs + 1, Cfg.MAX_BOMBS)
			_add_toast(tr("TOAST_BOMB_TOUCH" if touch_ui else "TOAST_BOMB"))
		Platform.Item.TRIPLE:
			player.triple_left = Cfg.TRIPLE_TIME
			_add_toast(tr("TOAST_TRIPLE"))


func _revive(at: Vector2) -> void:
	player.lives -= 1
	player.revive(at)
	_add_puff(at, Color(1.0, 0.6, 0.7), 16)
	_add_toast(tr("TOAST_REVIVED"))
	sfx.play("revive")


func _take_hit(monster: Monster) -> void:
	if player.shield:
		player.shield = false
		player.protected_left = Cfg.SHIELD_PROTECTION
		_destroy_monster(monster)
		sfx.play("shield")
	elif player.lives > 0:
		_destroy_monster(monster)
		_revive(player.position)
	else:
		player.kill()
		sfx.play("lose")


func _check_monsters() -> void:
	if player.is_protected():
		return
	for monster in _living_monsters():
		if player.position.distance_to(monster.position) > Player.RADIUS + Monster.RADIUS:
			continue
		if player.velocity.y > 0.0 and player.position.y < monster.position.y:
			_destroy_monster(monster)
			player.bounce(Cfg.JUMP_VELOCITY)
			_count_jump()
			sfx.play("stomp")
		else:
			_take_hit(monster)
		return


func _check_bullets() -> void:
	var top := camera.position.y - Cfg.VIEW_H * 0.5 - 40.0
	var bottom := camera.position.y + Cfg.VIEW_H * 0.5 + 40.0
	for bullet: Bullet in bullets.get_children():
		# A camera pode subir mais rapido que o tiro, deixando-o para tras.
		if bullet.position.y < top or bullet.position.y > bottom:
			bullet.queue_free()
			continue
		for monster in _living_monsters():
			if bullet.position.distance_to(monster.position) < Monster.RADIUS + Bullet.RADIUS:
				_destroy_monster(monster)
				bullet.queue_free()
				sfx.play("stomp")
				break


func _update_camera() -> void:
	# O jogador nunca passa de 40% da altura da tela; a camera so sobe.
	camera.position.y = minf(camera.position.y, player.position.y + Cfg.VIEW_H * 0.1)
	sky.camera_top = camera.position.y - Cfg.VIEW_H * 0.5


func _spawn_ahead() -> void:
	while next_platform_y > camera.position.y - Cfg.VIEW_H:
		_spawn_next()


func _spawn_next() -> void:
	var height := Cfg.START_Y - next_platform_y
	var d := clampf(height / Cfg.HARD_HEIGHT, 0.0, 1.0)
	var gap := randf_range(
		lerpf(Cfg.GAP_MIN_EASY, Cfg.GAP_MIN_HARD, d), lerpf(Cfg.GAP_MAX_EASY, Cfg.GAP_MAX_HARD, d)
	)
	next_platform_y -= gap

	# O caminho garantido so usa plataformas permanentes: se uma delas pudesse
	# sumir, quem caisse depois de usa-la ficaria sem como subir de novo.
	var kind := Platform.Kind.NORMAL
	if randf() < lerpf(Cfg.MOVING_EASY, Cfg.MOVING_HARD, d):
		kind = Platform.Kind.MOVING
	var platform := _add_platform(kind, next_platform_y, d)
	if kind == Platform.Kind.NORMAL:
		_roll_item(platform)

	if gap >= 60.0 and randf() < lerpf(Cfg.EXTRA_EASY, Cfg.EXTRA_HARD, d):
		var vanishing := randf() < lerpf(Cfg.VANISHING_SHARE_EASY, Cfg.VANISHING_SHARE_HARD, d)
		var extra := Platform.Kind.VANISHING if vanishing else Platform.Kind.BREAKABLE
		_add_platform(extra, next_platform_y + gap * 0.5, d)

	var far_enough := last_monster_y - next_platform_y > Cfg.MONSTER_MIN_SPACING
	if height > Cfg.MONSTER_MIN_HEIGHT and far_enough:
		if randf() < lerpf(Cfg.MONSTER_CHANCE_EASY, Cfg.MONSTER_CHANCE_HARD, d):
			_add_monster(next_platform_y - 60.0, d)


func _roll_item(platform: Platform) -> void:
	var roll := randf()
	for item: Platform.Item in ITEM_CHANCES:
		roll -= ITEM_CHANCES[item]
		if roll < 0.0:
			platform.add_item(item)
			return
	if roll < Cfg.SPRING_CHANCE:
		platform.add_spring()


func _add_platform(kind: Platform.Kind, y: float, d: float) -> Platform:
	var platform := Platform.new()
	var margin := Platform.WIDTH * 0.5
	platform.position = Vector2(randf_range(margin, Cfg.VIEW_W - margin), y)
	platform.setup(kind, d)
	platforms.add_child(platform)
	return platform


func _add_monster(y: float, d: float) -> void:
	var monster := Monster.new()
	monster.position = Vector2(randf_range(40.0, Cfg.VIEW_W - 40.0), y)
	monster.setup(d, Monster.Variant.BAT if randf() < 0.5 else Monster.Variant.SPIKY)
	monsters.add_child(monster)
	last_monster_y = y


func _cull_below() -> void:
	var bottom := camera.position.y + Cfg.VIEW_H * 0.5 + 80.0
	for layer: Node2D in [platforms, monsters]:
		for node: Node2D in layer.get_children():
			if node.position.y > bottom:
				node.queue_free()


func _update_score() -> void:
	highest_y = minf(highest_y, player.position.y)
	score = int((Cfg.PLAYER_START_Y - highest_y) / 5.0)
	score_label.text = str(score)


func _end_game() -> void:
	state = State.GAME_OVER
	restart_wait = RESTART_DELAY
	if player.alive:
		sfx.play("lose")
	var record := score > best
	if record:
		best = score
		_save_game()
	_update_best_label()
	var lines: Array[String] = [tr("SCORE_LINE") % score, tr("BEST_LINE") % best]
	if record:
		lines.push_front(tr("NEW_RECORD"))
	_show_message(
		tr("GAME_OVER"), "\n".join(lines), tr("PROMPT_TOUCH_RESTART" if touch_ui else "PROMPT_RESTART")
	)
	language_row.hide()
	panel.offset_bottom = PANEL_BOTTOM_GAME_OVER
	touch_controls.hide()
	ranking.sync(best)


func _show_message(heading: String, body: String, call_to_action: String) -> void:
	title.text = heading
	message.text = body
	prompt.text = call_to_action
	panel.show()
	ranking_button.visible = ranking.is_available()
	touch_controls.hide()


func _update_power_bar() -> void:
	power_bar.set_slot("ammo", true, "%d/%d" % [player.ammo, Cfg.MAX_AMMO])
	power_bar.set_reload(
		player.ammo < Cfg.MAX_AMMO, float(player.jumps_since_reload) / Cfg.JUMPS_PER_SHOT
	)
	power_bar.set_slot("heart", player.lives > 0, "x%d" % player.lives)
	power_bar.set_slot("bomb", player.bombs > 0, "x%d" % player.bombs)
	power_bar.set_slot("shield", player.shield)
	power_bar.set_slot("triple", player.triple_left > 0.0, "%ds" % ceili(player.triple_left))


func _update_best_label() -> void:
	best_label.text = tr("BEST_HUD") % best


func _reset_world() -> void:
	for layer: Node2D in [platforms, monsters, bullets, effects]:
		for node: Node in layer.get_children():
			node.free()
	camera.position = Vector2(Cfg.VIEW_W * 0.5, Cfg.VIEW_H * 0.5)
	sky.camera_top = 0.0
	score = 0
	score_label.text = "0"
	_update_best_label()
	highest_y = Cfg.PLAYER_START_Y
	next_platform_y = Cfg.START_Y
	last_monster_y = Cfg.START_Y

	var first := _add_platform(Platform.Kind.NORMAL, Cfg.START_Y, 0.0)
	first.position.x = Cfg.VIEW_W * 0.5
	player.reset(Vector2(Cfg.VIEW_W * 0.5, Cfg.PLAYER_START_Y))
	_update_power_bar()
	_spawn_ahead()


func _load_save() -> void:
	var file := ConfigFile.new()
	var locale := OS.get_locale()
	if file.load(save_path) == OK:
		var saved_best: Variant = file.get_value("score", "best", 0)
		var saved_language: Variant = file.get_value("settings", "language", locale)
		# O arquivo pode ter sido editado a mao: valores invalidos sao ignorados.
		if saved_best is int:
			best = maxi(saved_best, 0)
		if saved_language is String:
			locale = saved_language
		_load_ranking(file)
	language = _language_index(locale)


func _load_ranking(file: ConfigFile) -> void:
	var saved_id: Variant = file.get_value("ranking", "id", "")
	var saved_name: Variant = file.get_value("ranking", "name", "")
	var saved_synced: Variant = file.get_value("ranking", "synced_best", 0)
	if saved_id is String:
		ranking.player_id = saved_id
	if saved_name is String:
		ranking.player_name = Ranking.clean_name(saved_name)
	if saved_synced is int:
		ranking.synced_best = maxi(saved_synced, 0)


## Busca o idioma exato, depois o mesmo idioma de outra regiao; senao, ingles.
func _language_index(locale: String) -> int:
	var base := locale.get_slice("_", 0)
	var same_base := -1
	for i in LANGUAGES.size():
		if LANGUAGES[i][0] == locale:
			return i
		if same_base == -1 and LANGUAGES[i][0].get_slice("_", 0) == base:
			same_base = i
	return same_base if same_base != -1 else 1


func _save_game() -> void:
	var file := ConfigFile.new()
	file.set_value("score", "best", best)
	file.set_value("settings", "language", LANGUAGES[language][0])
	file.set_value("ranking", "id", ranking.player_id)
	file.set_value("ranking", "name", ranking.player_name)
	file.set_value("ranking", "synced_best", ranking.synced_best)
	file.save(save_path)
