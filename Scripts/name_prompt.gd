extends Control

@export var name_input: LineEdit
@export var save_button: Button
@export_file("*.tscn") var game_scene_path: String

func _ready() -> void:
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
		
	# لو عنده اسم قديم محفوظ، نتخطى هذي الشاشة ونروح للمشهد المحدد مباشرة
	SaveManager.load_game()
	if SaveManager.player_data["player_name"] != "":
		if game_scene_path != "":
			get_tree().change_scene_to_file(game_scene_path)
		else:
			print("خطأ: لم تقم بتحديد مسار المشهد في الإنبيكتور!")

func _on_save_pressed() -> void:
	var entered_name = name_input.text.strip_edges()
	if entered_name == "":
		print("يا غالي، اكتب اسم صحيح لا تتركه فاضي!")
		return
		
	# نحفظ الاسم في الـ SaveManager
	SaveManager.player_data["player_name"] = entered_name
	SaveManager.save_game()
	
	# ننتقل للمشهد المحدد من الإنبيكتور مباشرة
	if game_scene_path != "":
		get_tree().change_scene_to_file(game_scene_path)
	else:
		print("خطأ: لم تقم بتحديد مسار المشهد في الإنبيكتور!")
