extends Control

@onready var leaderboard_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var loading_label: Label = $MarginContainer/VBoxContainer/LoadingLabel

var cloud_manager: Node
var is_loaded := false

func _ready() -> void:
	cloud_manager = get_node_or_null("/root/CloudManager")
	
	if not cloud_manager:
		loading_label.text = "خطأ: مدير السحابة غير موجود"
		back_button.disabled = true
		return
	
	# تحميل البيانات
	await load_leaderboard()
	is_loaded = true

func load_leaderboard() -> void:
	loading_label.visible = true
	leaderboard_list.visible = false
	
	# تنظيف القائمة الحالية
	for child in leaderboard_list.get_children():
		child.queue_free()
	
	# جلب البيانات من Supabase
	var result = await cloud_manager.get_leaderboard()
	
	loading_label.visible = false
	leaderboard_list.visible = true
	
	if result.is_ok():
		var data = result.ok()
		if data.size() == 0:
			var no_data_label = Label.new()
			no_data_label.text = "لا توجد نتائج بعد"
			no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			leaderboard_list.add_child(no_data_label)
		else:
			var rank = 1
			for entry in data:
				var row = HBoxContainer.new()
				row.add_theme_constant_override("separation", 20)
				
				# الترتيب
				var rank_label = Label.new()
				rank_label.text = str(rank) + "."
				rank_label.custom_minimum_size = Vector2(40, 0)
				rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				row.add_child(rank_label)
				
				# اسم اللاعب
				var name_label = Label.new()
				name_label.text = entry.get("player_name", "لاعب")
				name_label.custom_minimum_size = Vector2(150, 0)
				row.add_child(name_label)
				
				# النقاط/القتلى
				var score_label = Label.new()
				var score = entry.get("score", 0)
				score_label.text = "النقاط: " + str(score)
				row.add_child(score_label)
				
				leaderboard_list.add_child(row)
				rank += 1
	else:
		var error_label = Label.new()
		error_label.text = "فشل تحميل اللوحة: " + str(result.err())
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		leaderboard_list.add_child(error_label)

func _on_back_button_pressed() -> void:
	queue_free()
