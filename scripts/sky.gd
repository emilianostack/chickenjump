extends Node2D
## Ceu que escurece com a altura (dia, por do sol, noite, espaco), com nuvens
## em paralaxe e estrelas. Fica em um CanvasLayer, fora da camera.

const CLOUD_TEXTURES: Array[Texture2D] = [
	preload("res://assets/background/cloud_a.svg"),
	preload("res://assets/background/cloud_b.svg"),
]
const STAR_TEXTURE := preload("res://assets/items/puff.svg")
const SPACE_HEIGHT := 34000.0
const CLOUD_COUNT := 7
const STAR_COUNT := 80
const CLOUD_MARGIN := 240.0

var camera_top := 0.0:
	set(value):
		camera_top = value
		queue_redraw()

var top_colors := Gradient.new()
var bottom_colors := Gradient.new()
var cloud_tints := Gradient.new()
var clouds: Array[Dictionary] = []
var stars: Array[Dictionary] = []


func _ready() -> void:
	var offsets := PackedFloat32Array([0.0, 0.3, 0.6, 1.0])
	top_colors.offsets = offsets
	top_colors.colors = PackedColorArray([
		Color("3fb4ef"), Color("6a5cc7"), Color("161a54"), Color("04051a"),
	])
	bottom_colors.offsets = offsets
	bottom_colors.colors = PackedColorArray([
		Color("c6f1fb"), Color("ffb27d"), Color("4a3a8f"), Color("12163f"),
	])
	cloud_tints.offsets = PackedFloat32Array([0.0, 0.3, 0.6, 0.85])
	cloud_tints.colors = PackedColorArray([
		Color(1, 1, 1, 0.85), Color(1, 0.8, 0.75, 0.8), Color(0.45, 0.42, 0.7, 0.45), Color(0.3, 0.3, 0.6, 0.0),
	])
	for i in CLOUD_COUNT:
		var parallax := randf_range(0.12, 0.35)
		clouds.append({
			"texture": CLOUD_TEXTURES[i % CLOUD_TEXTURES.size()],
			"x": randf() * (Cfg.VIEW_W + CLOUD_MARGIN),
			"y": randf() * (Cfg.VIEW_H + CLOUD_MARGIN),
			"drift": randf_range(4.0, 14.0),
			"parallax": parallax,
			# Nuvens mais distantes andam menos e parecem menores.
			"size": 0.35 + parallax,
		})
	for i in STAR_COUNT:
		stars.append({
			"position": Vector2(randf() * Cfg.VIEW_W, randf() * Cfg.VIEW_H),
			"radius": randf_range(0.8, 2.2),
			"phase": randf() * TAU,
		})


func _process(delta: float) -> void:
	for cloud in clouds:
		cloud.x += cloud.drift * delta
	queue_redraw()


func _draw() -> void:
	var t := clampf(-camera_top / SPACE_HEIGHT, 0.0, 1.0)
	var top := top_colors.sample(t)
	var bottom := bottom_colors.sample(t)
	draw_polygon(
		PackedVector2Array([
			Vector2.ZERO,
			Vector2(Cfg.VIEW_W, 0),
			Vector2(Cfg.VIEW_W, Cfg.VIEW_H),
			Vector2(0, Cfg.VIEW_H),
		]),
		PackedColorArray([top, top, bottom, bottom])
	)
	_draw_stars(smoothstep(0.4, 0.75, t))
	_draw_clouds(cloud_tints.sample(t))


func _draw_stars(alpha: float) -> void:
	if alpha <= 0.0:
		return
	var time := Time.get_ticks_msec() * 0.002
	for star in stars:
		var y := fposmod(star.position.y - camera_top * 0.03, Cfg.VIEW_H)
		var twinkle := 0.7 + 0.3 * sin(time + star.phase)
		# Textura em vez de draw_circle: 80 circulos por frame derrubavam o FPS.
		var size: Vector2 = Vector2.ONE * star.radius * 2.5
		var rect := Rect2(Vector2(star.position.x, y) - size * 0.5, size)
		draw_texture_rect(STAR_TEXTURE, rect, false, Color(1, 1, 1, alpha * twinkle))


func _draw_clouds(tint: Color) -> void:
	if tint.a <= 0.0:
		return
	for cloud in clouds:
		var texture: Texture2D = cloud.texture
		var size: Vector2 = texture.get_size() * cloud.size
		var x := fposmod(cloud.x, Cfg.VIEW_W + CLOUD_MARGIN) - CLOUD_MARGIN
		var y := fposmod(cloud.y - camera_top * cloud.parallax, Cfg.VIEW_H + CLOUD_MARGIN) - CLOUD_MARGIN
		draw_texture_rect(texture, Rect2(Vector2(x, y), size), false, tint)
