extends Area2D

@export_category("إعدادات الضرر")
@export var damage: int = 15
@export var damage_radius: float = 30.0 # قطر المنطقة التي تتأثر بالضرر عند السقوط

@export_category("إعدادات حركة الطيران")
@export var arc_height: float = 120.0 # مدى ارتفاع القوس في الجو
@export var flight_duration: float = 0.9 # وقت وصول السهم بالثواني
@export var rotation_smoothing: float = 18.0 # كل ما زادت القيمة، دوران رأس السهم أنعم وأسرع استجابة

@onready var sprite: Sprite2D = $Sprite2D

var start_pos: Vector2
var target_pos: Vector2
var elapsed_time: float = 0.0
var is_flying: bool = false

# دالة الاستدعاء والإطلاق من العدو
func launch(from_pos: Vector2, to_pos: Vector2) -> void:
	start_pos = from_pos
	target_pos = to_pos
	global_position = start_pos
	elapsed_time = 0.0
	is_flying = true
	# نضبط زاوية البداية صح من أول فريم بدل ما يبدأ بزاوية غلط لحظة الإطلاق
	rotation = _get_velocity_direction(0.0).angle()

func _physics_process(delta: float) -> void:
	if not is_flying:
		return

	elapsed_time += delta
	# t تتغير من 0.0 (لحظة الإطلاق) إلى 1.0 (لحظة السقوط)
	var t: float = clamp(elapsed_time / flight_duration, 0.0, 1.0)

	# 1. الحركة الأفقية المستقيمة بين نقطة البداية ونقطة الهدف
	var ground_pos: Vector2 = start_pos.lerp(target_pos, t)

	# 2. الارتفاع القوسي بمعادلة القذيفة (نفس معادلتك الأصلية، وهي فيزيائياً صحيحة)
	var height: float = 4.0 * arc_height * t * (1.0 - t)

	global_position = ground_pos + Vector2(0, -height)

	# 3. الدوران: بدل ما نحسب فريم تالي تقريبي (كان بيسبب اهتزاز)،
	# بنحسب اتجاه السرعة اللحظية رياضياً (مشتقة مسار الحركة) فبيطلع سلس ومستقل عن الفريم ريت
	var target_angle: float = _get_velocity_direction(t).angle()
	rotation = lerp_angle(rotation, target_angle, rotation_smoothing * delta)

	# 4. السقوط والوصول للهدف
	if t >= 1.0:
		on_impact()

# ترجع اتجاه حركة السهم اللحظي عند أي نقطة t، عن طريق مشتقة معادلة المسار
# (بدل تقدير الفريم القادم يدوياً زي الكود القديم)
func _get_velocity_direction(t: float) -> Vector2:
	var horizontal_dir: Vector2 = target_pos - start_pos
	var vertical_speed: float = 4.0 * arc_height * (1.0 - 2.0 * t) # مشتقة الارتفاع بالنسبة لـ t
	var dir: Vector2 = horizontal_dir + Vector2(0, -vertical_speed)

	if dir.length() < 0.01:
		return horizontal_dir.normalized() if horizontal_dir.length() > 0.0 else Vector2.RIGHT
	return dir

func on_impact() -> void:
	is_flying = false

	# إلحاق الضرر باللاعب إذا كان متواجداً في منطقة السقوط لحظة وصول السهم
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if is_instance_valid(player) and global_position.distance_to(player.global_position) <= damage_radius:
			if player.has_method("take_damage"):
				player.take_damage(damage)

	queue_free()
