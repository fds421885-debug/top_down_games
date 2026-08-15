extends Control

@export_category("UI Elements")
@export var pause_button: TextureButton      # زر الإيقاف اللي بالزاوية فوق
@export var background_overlay: Control # الخلفية المظللة
@export var panel_box: Control          # اللوحة اللي بالنص (فيها أزرار الاستمرار والمنيو)

@export_category("Menu Buttons")
@export var resume_button: Button       # زر استمرار
@export var main_menu_button: Button   # زر القائمة الرئيسية

@export_category("Navigation")
@export_file("*.tscn") var main_menu_scene: String = "res://Scenes/main_menu.tscn"

var is_paused: bool = false

func _ready() -> void:
	# ضمان عمل القائمة حتى واللعبة متوقفة
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# إخفاء عناصر المنيو في البداية وتجهيز خلفية الظل
	if background_overlay:
		background_overlay.hide()
	if panel_box:
		panel_box.hide()
		
	# ربط الأزرار برمجياً
	if pause_button:
		pause_button.pressed.connect(toggle_pause)
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	# زر Escape بالكيبورد
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	
	if is_paused:
		open_pause_menu()
	else:
		close_pause_menu()

func open_pause_menu() -> void:
	if background_overlay:
		background_overlay.show()
		
	if panel_box:
		panel_box.show()
		# إعداد نقطة الانطلاق لتكون من منتصف اللوحة تماماً
		panel_box.pivot_offset = panel_box.size / 2
		panel_box.scale = Vector2(0.1, 0.1)
		
		# أنيميشن الانبثاق الناعم (Pop-up Animation)
		var tween = create_tween().set_ignore_time_scale(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(panel_box, "scale", Vector2(1, 1), 0.35)

func close_pause_menu() -> void:
	if panel_box:
		# أنيميشن الاختفاء اللطيف عند استئناف اللعب
		var tween = create_tween().set_ignore_time_scale(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(panel_box, "scale", Vector2(0.1, 0.1), 0.15)
		await tween.finished
		panel_box.hide()
		
	if background_overlay:
		background_overlay.hide()
		
	get_tree().paused = false

func _on_resume_pressed() -> void:
	is_paused = false
	close_pause_menu()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	if main_menu_scene != "":
		get_tree().change_scene_to_file(main_menu_scene)
