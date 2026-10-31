class_name Player
extends Node2D

const RADIUS := 24.0
const FEET_OFFSET := 30.0
const TEXTURE_RISING := preload("res://assets/player/rising.svg")
const TEXTURE_FALLING := preload("res://assets/player/falling.svg")
const TEXTURE_DEAD := preload("res://assets/player/dead.svg")
const TEXTURE_JETPACK := preload("res://assets/items/jetpack.svg")
const TEXTURE_FLAME := preload("res://assets/items/flame.svg")
const TEXTURE_BUBBLE := preload("res://assets/items/bubble.svg")

var velocity := Vector2.ZERO
var alive := true
var facing := 1.0
var jetpack_left := 0.0
var shoot_cooldown := 0.0
var squash := 0.0
var ammo := Cfg.MAX_AMMO
var jumps_since_reload := 0
var shield := false
var lives := 0
var bombs := 0
var triple_left := 0.0
var protected_left := 0.0

var body := Sprite2D.new()
var jetpack := Sprite2D.new()
var flame := Sprite2D.new()
var bubble := Sprite2D.new()


func _ready() -> void:
	jetpack.texture = TEXTURE_JETPACK
	jetpack.scale = Cfg.ART_SCALE * 0.85
	flame.texture = TEXTURE_FLAME
	flame.position = Vector2(0.0, 60.0)
	jetpack.add_child(flame)
	add_child(jetpack)
	body.texture = TEXTURE_FALLING
	body.scale = Cfg.ART_SCALE
	add_child(body)
	bubble.texture = TEXTURE_BUBBLE
	bubble.scale = Cfg.ART_SCALE * 0.95
	bubble.position.y = 3.0
	add_child(bubble)
	_update_art()


func reset(start: Vector2) -> void:
	position = start
	rotation = 0.0
	velocity = Vector2.ZERO
	alive = true
	facing = 1.0
	jetpack_left = 0.0
	shoot_cooldown = 0.0
	squash = 0.0
	ammo = Cfg.MAX_AMMO
	jumps_since_reload = 0
	shield = false
	lives = 0
	bombs = 0
	triple_left = 0.0
	protected_left = 0.0
	_update_art()


func feet_y() -> float:
	return position.y + FEET_OFFSET


func has_jetpack() -> bool:
	return jetpack_left > 0.0


## Conta um pulo para a recarga. Retorna true quando devolve um tiro.
func add_jump() -> bool:
	if ammo >= Cfg.MAX_AMMO:
		return false
	jumps_since_reload += 1
	if jumps_since_reload < Cfg.JUMPS_PER_SHOT:
		return false
	jumps_since_reload = 0
	ammo += 1
	return true


func is_protected() -> bool:
	return protected_left > 0.0 or has_jetpack()


func step(delta: float, axis: float) -> void:
	if not alive:
		axis = 0.0
		rotation += 6.0 * delta
	if has_jetpack():
		jetpack_left -= delta
		velocity.y = Cfg.JETPACK_VELOCITY
	else:
		velocity.y += Cfg.GRAVITY * delta
	velocity.x = move_toward(velocity.x, axis * Cfg.MOVE_SPEED, Cfg.MOVE_ACCEL * delta)
	position += velocity * delta
	position.x = wrapf(position.x, 0.0, Cfg.VIEW_W)
	if axis != 0.0:
		facing = signf(axis)
	shoot_cooldown = maxf(shoot_cooldown - delta, 0.0)
	squash = maxf(squash - delta * 5.0, 0.0)
	triple_left = maxf(triple_left - delta, 0.0)
	protected_left = maxf(protected_left - delta, 0.0)
	_update_art()


func bounce(jump_velocity: float) -> void:
	velocity.y = jump_velocity
	squash = 1.0


func kill() -> void:
	alive = false
	jetpack_left = 0.0
	velocity = Vector2(0.0, 200.0)
	_update_art()


## Lanca o jogador para cima, protegido por alguns segundos.
func revive(from: Vector2) -> void:
	position = from
	alive = true
	jetpack_left = 0.0
	protected_left = Cfg.REVIVE_PROTECTION
	bounce(Cfg.SPRING_VELOCITY)
	_update_art()


func _update_art() -> void:
	# A galinha sobe de asas fechadas e cai de asas abertas.
	if not alive:
		body.texture = TEXTURE_DEAD
	elif velocity.y < 0.0:
		body.texture = TEXTURE_RISING
	else:
		body.texture = TEXTURE_FALLING
	body.flip_h = facing < 0.0

	# Achata ao tocar a plataforma e estica nas subidas rapidas.
	var stretch := clampf(-velocity.y / 12000.0, 0.0, 0.07) if squash == 0.0 else 0.0
	var scale_x := 1.0 + squash * 0.22 - stretch
	var scale_y := 1.0 - squash * 0.22 + stretch
	body.scale = Cfg.ART_SCALE * Vector2(scale_x, scale_y)
	body.position.y = (1.0 - scale_y) * FEET_OFFSET

	# Pisca enquanto a protecao temporaria estiver ativa.
	var blink := protected_left > 0.0 and fmod(protected_left, 0.2) < 0.1
	body.modulate.a = 0.45 if blink else 1.0
	bubble.visible = shield
	jetpack.visible = has_jetpack()
	jetpack.position = Vector2(-facing * 33.0, 4.0)
	flame.scale = Vector2.ONE * (1.0 + 0.2 * sin(Time.get_ticks_msec() * 0.05))
