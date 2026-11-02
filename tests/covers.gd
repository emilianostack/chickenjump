extends SceneTree
## Gera as capas dos portais (paisagem, retrato e quadrada) a partir da arte vetorial.
## Uso: godot --path . --resolution 480x270 --script res://tests/covers.gd -- --out=PASTA

const INK := Color(0.12, 0.16, 0.27)
const FONT := "res://assets/fonts/LilitaOne-Regular.ttf"
const LAYOUTS := {
	"landscape": {
		"size": Vector2i(1920, 1080), "title": Vector2(80, 70), "font": 230, "jump": Vector2(130, 320),
		"chicken": Vector2(1370, 610), "height": 700, "floor": 930,
		"bat": Vector2(1790, 150), "spiky": Vector2(840, 640),
	},
	"portrait": {
		"size": Vector2i(800, 1200), "title": Vector2(0, 60), "font": 170, "jump": Vector2(0, 240),
		"chicken": Vector2(410, 790), "height": 520, "floor": 1090,
		"bat": Vector2(696, 634), "spiky": Vector2(104, 768),
	},
	"square": {
		"size": Vector2i(800, 800), "title": Vector2(0, 30), "font": 150, "jump": Vector2(0, 190),
		"chicken": Vector2(560, 540), "height": 400, "floor": 730,
		"bat": Vector2(110, 400), "spiky": Vector2(290, 540),
	},
}

var out_dir := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
	for layout: String in LAYOUTS:
		await _card(layout, LAYOUTS[layout])
	quit()


func _card(layout: String, spec: Dictionary) -> void:
	var size: Vector2i = spec.size
	var view := SubViewport.new()
	view.size = size
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.disable_3d = true
	root.add_child(view)
	_sky(view, size)
	_art(view, "background/cloud_a", Vector2(size.x * 0.82, size.y * 0.16), size.y * 0.16)
	_art(view, "background/cloud_b", Vector2(size.x * 0.14, size.y * 0.62), size.y * 0.13)
	_art(view, "background/hills", Vector2(size.x * 0.5, size.y * 0.97), size.y * 0.5, size.x)
	var ground: float = spec.floor
	var unit: float = spec.height
	var feet := Vector2(spec.chicken.x, ground)
	_art(view, "platforms/grass", feet, unit * 0.2)
	_art(view, "items/spring_up", feet - Vector2(0, unit * 0.17), unit * 0.22)
	_art(view, "player/rising", spec.chicken, unit)
	_art(view, "platforms/moving", Vector2(size.x * 0.2, ground - unit * 0.06), unit * 0.13)
	_art(view, "items/heart", Vector2(size.x * 0.2, ground - unit * 0.24), unit * 0.2)
	_art(view, "monsters/spiky", spec.spiky, unit * 0.25)
	_art(view, "monsters/bat_up", spec.bat, unit * 0.25)
	_title(view, "CHICKEN", spec.title, spec.font, Color.WHITE, size.x if layout != "landscape" else 0)
	_title(view, "JUMP", spec.jump, spec.font, Color(1.0, 0.8, 0.2), size.x if layout != "landscape" else 0)
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := view.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	image.save_png("%s/cover_%s.png" % [out_dir, layout])
	print("capa ", layout, " ", image.get_size())
	view.queue_free()


func _sky(view: SubViewport, size: Vector2i) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.13, 0.55, 0.9))
	gradient.set_color(1, Color(0.72, 0.9, 0.95))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 8
	texture.height = 256
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.size = Vector2(size)
	view.add_child(rect)


## Rasteriza o SVG na altura pedida, para a arte sair nitida em qualquer tamanho.
func _art(view: SubViewport, path: String, center: Vector2, height: float, width := 0.0) -> void:
	var source := FileAccess.get_file_as_string("res://assets/%s.svg" % path)
	var probe := Image.new()
	probe.load_svg_from_string(source, 1.0)
	var scale := height / float(probe.get_height())
	if width > 0.0:
		scale = maxf(scale, width / float(probe.get_width()))
	var image := Image.new()
	image.load_svg_from_string(source, scale)
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.position = center
	view.add_child(sprite)


func _title(view: SubViewport, text: String, at: Vector2, font_size: int, color: Color, center_width: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_override("font", load(FONT))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", font_size / 5)
	label.add_theme_color_override("font_shadow_color", Color(INK, 0.45))
	label.add_theme_constant_override("shadow_offset_y", font_size / 16)
	label.add_theme_constant_override("shadow_offset_x", 0)
	if center_width > 0:
		label.size.x = center_width
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	view.add_child(label)
