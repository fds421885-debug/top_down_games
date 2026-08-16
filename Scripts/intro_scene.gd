extends Control

@export var animation_player: AnimationPlayer
@export var skip_button: Button

@export_category("إعدادات الظهور")
@export var show_only_once: bool = true # هل تظهر مرة واحدة فقط؟
@export var allow_skip_on_first_time: bool = false # هل تسمح له بالتخطي في المرة الأولى؟

@export_file("*.tscn") var main_menu_scene: String = "res://Scenes/main_menu.tscn"

const SAVE_PATH = "user://intro_watched.json"

func _ready() -> void:
	# 1. لو كانت الإعدادات تمنع التكرار، وهو شافها من قبل -> انتقل للمشهد التالي فوراً
	if show_only_once and has_watched_intro():
		_go_to_next_scene()
		return
		
	# 2. إذا كانت أول مرة، نسجل بالذاكرة إنه شافها
	mark_intro_as_watched()
	
	# 3. نشغل الأอนيميشن المخصص
	if animation_player:
		# نتأكد من ربط إشارة الانتهاء بشكل صحيح
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)
		
		# شغّل اسم الأอนيميشن حقك هنا (تأكد إنه نفس اسم الأอนيميشن اللي بالـ AnimationPlayer)
		animation_player.play("new_animation")
		
	# 4. تفعيل زر التسكيب
	if skip_button:
		if not skip_button.pressed.is_connected(_on_skip_pressed):
			skip_button.pressed.connect(_on_skip_pressed)
			
		# لو مو مسموح له يسوي سكيب أول مرة، نخفي الزر
		if not allow_skip_on_first_time and not has_watched_intro():
			skip_button.hide()

func _on_skip_pressed() -> void:
	# يسمح بالتخطي لو مو أول مرة، أو لو سمحت له من الإنبيكتور
	if allow_skip_on_first_time or has_watched_intro():
		_go_to_next_scene()

func _on_animation_finished(_anim_name: String) -> void:
	# أول ما ينتهي الأอนيميشن تماماً، انتقل للمشهد التالي مباشرة
	_go_to_next_scene()

func _go_to_next_scene() -> void:
	# حماية عشان ما يحاول ينتقل مرتين بنفس اللحظة
	set_process(false)
	set_physics_process(false)
	
	if main_menu_scene != "":
		get_tree().change_scene_to_file(main_menu_scene)
	else:
		print("خطأ: لم تقم بتحديد مسار المشهد التالي في الإنبيكتور!")

func has_watched_intro() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			return data.get("watched", false)
	return false

func mark_intro_as_watched() -> void:
	var save_dict = { "watched": true }
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict))
