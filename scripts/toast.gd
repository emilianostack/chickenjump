class_name Toast
extends Label
## Texto curto que sobe e desaparece, usado ao pegar um buff.

const WIDTH := 380.0


func _init(at: Vector2, content: String) -> void:
	text = content
	custom_minimum_size.x = WIDTH
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	position = Vector2(clampf(at.x, WIDTH * 0.5, Cfg.VIEW_W - WIDTH * 0.5) - WIDTH * 0.5, at.y)
	z_index = 10
	add_theme_font_size_override("font_size", 26)
	add_theme_color_override("font_color", Color(1.0, 0.9, 0.35))
	add_theme_color_override("font_outline_color", Color(0.12, 0.16, 0.27))
	add_theme_constant_override("outline_size", 8)


func _ready() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - 80.0, 1.0)
	tween.tween_property(self, "modulate:a", 0.0, 1.0).set_delay(0.4)
	tween.chain().tween_callback(queue_free)
