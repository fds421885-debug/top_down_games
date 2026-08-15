extends Control

@export var play_again_button: Button
@export var menu_button: Button
@export var panel_box: Control

@export_file("*.tscn") var game_scene_path: String = "res://Scenes/game.tscn"
@export_file("*.tscn") var main_menu_path: String = "res://Scenes/main_menu.tscn"

func _ready() -> void:
	# مهم جداً: نخلي هذي النافذة تشتغل حتى واللعبة متوقفة (Paused)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	if play_again_button:
		play_again_button.pressed.connect(_on_play_again_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
		
	# تأثير الانبثاق
	if panel_box:
		panel_box.scale = Vector2(0.1, 0.1)
		panel_box.pivot_offset = panel_box.size / 2
		var tween = create_tween().set_ignore_time_scale(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(panel_box, "scale", Vector2(1, 1), 0.5)

func _on_play_again_pressed() -> void:
	# نرجع نفعل الوقت قبل ما نغير المشهد
	get_tree().paused = false
	if game_scene_path != "":
		get_tree().change_scene_to_file(game_scene_path)

func _on_menu_pressed() -> void:
	# نرجع نفعل الوقت قبل ما نغير المشهد
	get_tree().paused = false
	if main_menu_path != "":
		get_tree().change_scene_to_file(main_menu_path)
