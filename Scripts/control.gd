extends Control

# نربط الأزرار والخلفيات حقهم
@export_category("Menu Animation")
@export var start_button: Button
@export var start_button_bg: Node2D
@export var exit_button: Button
@export var exit_button_bg: Node2D

# نربط طبقة الانتقال
@export var transition_rect: ColorRect
@export_file("*.tscn") var game_scene_path: String

func _ready() -> void:
	# 1. إخفاء العناصر قبل الحركة
	_set_node_opacity([start_button, start_button_bg, exit_button, exit_button_bg], 0)

	# 2. تجهيز نقطة الدوران للأزرار عشان الـ scale يطلع من النص
	_center_pivot(start_button)
	_center_pivot(exit_button)

	# 3. حركة التلاشي للظهور (Fade-in من أسود إلى شفاف)
	if transition_rect:
		transition_rect.modulate.a = 1.0
		transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		var tween_in = create_tween()
		tween_in.tween_property(transition_rect, "modulate:a", 0.0, 1.0)
		tween_in.tween_callback(func():
			transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		)

	# 4. حركة الانبثاق للأزرار
	_animate_buttons_popup()

	# 5. ربط الأزرار
	if start_button: start_button.pressed.connect(_on_start_pressed)
	if exit_button: exit_button.pressed.connect(_on_exit_pressed)


func _center_pivot(control: Control) -> void:
	if control:
		control.pivot_offset = control.size / 2


func _set_node_opacity(nodes: Array, alpha: float) -> void:
	for node in nodes:
		if node:
			node.modulate.a = alpha


func _animate_buttons_popup() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	for n in [start_button, start_button_bg, exit_button, exit_button_bg]:
		if n:
			tween.tween_property(n, "modulate:a", 1.0, 0.8)
			tween.tween_property(n, "scale", Vector2(1, 1), 0.8).from(Vector2(0.8, 0.8))


func _on_start_pressed() -> void:
	if start_button: start_button.disabled = true
	if exit_button: exit_button.disabled = true

	if transition_rect:
		transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		var tween = create_tween()
		tween.tween_property(transition_rect, "modulate:a", 1.0, 0.8)
		await tween.finished

	get_tree().change_scene_to_file(game_scene_path)


func _on_exit_pressed() -> void:
	if start_button: start_button.disabled = true
	if exit_button: exit_button.disabled = true

	if transition_rect:
		transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		var tween = create_tween()
		tween.tween_property(transition_rect, "modulate:a", 1.0, 0.8)
		await tween.finished

	get_tree().quit()
