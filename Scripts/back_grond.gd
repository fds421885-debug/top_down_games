extends Control

@export var result_title: Label
@export var result_details: Label
@export var play_again_btn: Button
@export var menu_btn: Button

@export_file("*.tscn") var matchmaking_scene: String = "res://Scenes/matchmaking_screen.tscn"
@export_file("*.tscn") var menu_scene: String = "res://Scenes/main_menu.tscn"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # عشان تشتغل واللعبة واقفة
	hide()
	
	if play_again_btn:
		play_again_btn.pressed.connect(_on_play_again)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu)

func show_result(is_winner: bool, points: int) -> void:
	show()
	
	if is_winner:
		result_title.text = "لقد فـزت!"
		result_title.modulate = Color.GREEN
		result_details.text = "ربحت " + str(points) + " نقطة تمت إضافتها لرصيدك!"
	else:
		result_title.text = "لقد خسـرت!"
		result_title.modulate = Color.RED
		result_details.text = "تم خصم 5 نقاط من رصيدك الأساسي."
		
	# حركة انبثاق خفيفة
	scale = Vector2(0.5, 0.5)
	pivot_offset = size / 2
	var tween = create_tween().set_ignore_time_scale(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.5)

func _on_play_again() -> void:
	get_tree().paused = false
	if matchmaking_scene != "":
		get_tree().change_scene_to_file(matchmaking_scene)

func _on_menu() -> void:
	get_tree().paused = false
	if menu_scene != "":
		get_tree().change_scene_to_file(menu_scene)
