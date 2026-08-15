extends Control

@export_category("UI References")
@export var list_container: VBoxContainer     # اسحب هنا الـ VBoxContainer اللي جوة الـ ScrollContainer
@export var search_input: LineEdit           # اسحب خانة البحث هنا
@export var search_button: Button            # اسحب زر البحث هنا
@export var search_result_label: Label       # اسحب لبل عرض النتائج هنا
@export var back_button: Button              # اسحب زر الرجوع هنا

@export_category("Scene Navigation")
@export_file("*.tscn") var main_menu_scene: String = "res://Scenes/main_menu.tscn"

func _ready() -> void:
	if back_button: 
		back_button.pressed.connect(_on_back_pressed)
	if search_button: 
		search_button.pressed.connect(_on_search_pressed)
	
	# أول ما تفتح القائمة، نحمل التوب تن كاملين
	load_players_list()

func load_players_list(players_data: Array = []) -> void:
	if not list_container: return
	
	# تنظيف العناصر القديمة
	for child in list_container.get_children():
		child.queue_free()
		
	# لو ما انمررت بيانات، نجيب التوب تن الأساسيين من السحابة
	var data_to_show = players_data
	if data_to_show.is_empty():
		data_to_show = await CloudManager.fetch_leaderboard()
		
	if data_to_show.is_empty():
		var lbl = Label.new()
		lbl.text = "لا توجد بيانات متاحة حالياً..."
		list_container.add_child(lbl)
		return
		
	var rank = 1
	for player in data_to_show:
		var row_lbl = Label.new()
		var p_name = player.get("player_name", "مجهول")
		var p_wave = player.get("wave", 1)
		var p_kills = player.get("kills", 0)
		
		row_lbl.text = "#" + str(rank) + " | اللاعب: " + p_name + " -- الويف: " + str(p_wave) + " | القتلات: " + str(p_kills)
		
		if p_name == CloudManager.current_player_name:
			row_lbl.modulate = Color.GOLD
			row_lbl.text += " (أنت!)"
			
		list_container.add_child(row_lbl)
		rank += 1

func _on_search_pressed() -> void:
	if not search_input or not search_result_label: return
	
	var query = search_input.text.strip_edges()
	if query == "":
		search_result_label.text = "تمت إزالة البحث، جاري عرض القائمة العامة."
		load_players_list()
		return
		
	search_result_label.text = "جاري البحث عن: " + query + " ..."
	
	var results = await CloudManager.search_players_by_query(query)
	
	if results.is_empty():
		search_result_label.text = "ما فيه أي لاعب مطابق لهذا البحث."
		for child in list_container.get_children():
			child.queue_free()
	else:
		search_result_label.text = "تم العثور على (" + str(results.size()) + ") نتيجة."
		load_players_list(results)

func _on_back_pressed() -> void:
	if main_menu_scene != "":
		get_tree().change_scene_to_file(main_menu_scene)
