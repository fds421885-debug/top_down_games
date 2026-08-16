extends Control

@export var popup_panel: Control 
@export var open_button: BaseButton 
@export var close_button: BaseButton 

@export_category("إعدادات الظهور")
@export var show_always_on_startup: bool = false # لو true تظهر كل مرة، لو false أول مرة فقط

const CONTROLS_SAVE_PATH = "user://controls_shown.json"

func _ready() -> void:
	if popup_panel:
		popup_panel.visible = false
		popup_panel.modulate = Color(1, 1, 1, 0)
		popup_panel.scale = Vector2(0.8, 0.8)
		popup_panel.pivot_offset = popup_panel.size / 2

	if open_button:
		open_button.pressed.connect(open_popup)
		
	if close_button:
		close_button.pressed.connect(close_popup)

	if show_always_on_startup:
		await get_tree().create_timer(0.3).timeout
		open_popup()
	else:
		if not has_shown_controls_before():
			await get_tree().create_timer(0.3).timeout
			open_popup()
			mark_controls_as_shown()

func open_popup() -> void:
	if not popup_panel: return
	
	popup_panel.visible = true
	popup_panel.modulate = Color(1, 1, 1, 0)
	popup_panel.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(popup_panel, "scale", Vector2(1.0, 1.0), 0.3)

func close_popup() -> void:
	if not popup_panel: return
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(popup_panel, "modulate:a", 0.0, 0.25)
	tween.tween_property(popup_panel, "scale", Vector2(0.8, 0.8), 0.25)
	
	await tween.finished
	popup_panel.visible = false

func has_shown_controls_before() -> bool:
	if FileAccess.file_exists(CONTROLS_SAVE_PATH):
		var file = FileAccess.open(CONTROLS_SAVE_PATH, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			return data.get("shown", false)
	return false

func mark_controls_as_shown() -> void:
	var save_dict = { "shown": true }
	var file = FileAccess.open(CONTROLS_SAVE_PATH, FileAccess.WRITE) # تم تصحيح الخطأ هنا
	if file:
		file.store_string(JSON.stringify(save_dict))
