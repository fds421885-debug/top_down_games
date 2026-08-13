extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	# أول ما يشتغل أي مشهد جديد، نسوي تلاشي دخول (Fade-in) تلقائياً من أسود إلى شفاف
	if color_rect:
		color_rect.modulate.a = 3.0
		var tween = create_tween()
		tween.tween_property(color_rect, "modulate:a", 0.0, 0.8)

# دالة عامة تستدعيها من أي مكان لتغيير المشهد مع تفعيل التلاشي بسلاسة
func change_scene(target_path: String) -> void:
	if not color_rect:
		get_tree().change_scene_to_file(target_path)
		return
		
	# 1. تلاشي للخروج (Fade-out): الشاشة تغمق وتصير سوداء (من 0 إلى 1)
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.8)
	await tween.finished
	
	# 2. تغيير المشهد الفعلي في الخلفية وهو أسود بالكامل
	var err = get_tree().change_scene_to_file(target_path)
	if err != OK:
		print("خطأ: لم يتم العثور على المشهد المطلوب في المسار: ", target_path)
		
	# 3. تلاشي للداخل (Fade-in): الشاشة تفتح وتوضح اللعبة الجديدة (من 1 إلى 0)
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "modulate:a", 0.0, 0.8)
