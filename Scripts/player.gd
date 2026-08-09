extends CharacterBody2D

@export_category("Movement Settings")
@export var max_speed: float = 400.0
@export var acceleration: float = 3000.0
@export var friction: float = 2500.0

@export_category("Dash Settings")
@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.12
@export var dash_cooldown: float = 0.8
@export var max_drag_distance: float = 80.0

@export_category("Animation Settings")
@export var animated_sprite: AnimatedSprite2D
@export var anim_idle: String = "idle"
@export var anim_run: String = "run"
@export var anim_attack: String = "attack"

@export_category("Combat Settings")
@export var attack_area: Area2D               # اسحب عقدة الـ Area2D هنا من الـ Inspector

var is_dashing: bool = false
var is_attacking: bool = false
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var current_dash_dir: Vector2 = Vector2.RIGHT

# متغيرات الجويستك الوهمي (اليسار)
var joystick_touch_index: int = -1
var joystick_origin: Vector2 = Vector2.ZERO
var joystick_vector: Vector2 = Vector2.ZERO

# متغيرات السحب للهجوم (اليمين)
var right_touch_index: int = -1
var right_touch_start_y: float = 0.0

var last_tap_time: int = 0
var double_tap_threshold: int = 300

func _ready() -> void:
	add_to_group("player")
	
	# إيقاف عمل منطقة الهجوم في البداية
	if attack_area:
		attack_area.monitoring = false
		
	# ربط إشارة انتهاء الأنميشن عشان نعرف متى يخلص الهجوم
	if animated_sprite:
		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)

func _input(event: InputEvent) -> void:
	var screen_width = get_viewport().get_visible_rect().size.x

	if event is InputEventScreenTouch:
		if event.pressed:
			# 1. نظام الضغط مرتين (Double Tap) للداش في أي مكان
			var current_time = Time.get_ticks_msec()
			if current_time - last_tap_time < double_tap_threshold:
				trigger_dash()
				last_tap_time = 0
			else:
				last_tap_time = current_time

			# 2. تقسيم الشاشة: اليسار للجويستك، اليمين للهجوم
			if event.position.x < screen_width / 2:
				if joystick_touch_index == -1:
					joystick_touch_index = event.index
					joystick_origin = event.position
					joystick_vector = Vector2.ZERO
			else:
				if right_touch_index == -1:
					right_touch_index = event.index
					right_touch_start_y = event.position.y
		else:
			# رفع الإصبع
			if event.index == joystick_touch_index:
				joystick_touch_index = -1
				joystick_vector = Vector2.ZERO
			elif event.index == right_touch_index:
				right_touch_index = -1

	elif event is InputEventScreenDrag:
		# حركة السحب للجويستك (اليسار)
		if event.index == joystick_touch_index:
			var diff = event.position - joystick_origin
			if diff.length() > max_drag_distance:
				diff = diff.normalized() * max_drag_distance
			
			if diff.length() > 5.0:
				joystick_vector = diff / max_drag_distance
			else:
				joystick_vector = Vector2.ZERO
				
		# حركة السحب للهجوم (اليمين - سحب للأعلى)
		elif event.index == right_touch_index:
			var swipe_diff = event.position.y - right_touch_start_y
			if swipe_diff < -30 and not is_attacking: # لو سحب إصبعه لفوق بأكثر من 30 بكسل
				trigger_attack()
				right_touch_index = -1 # إعادة تعيين عشان ما يكرر الهجوم بنفس السحبة

func _physics_process(delta: float) -> void:
	if dash_cooldown_left > 0:
		dash_cooldown_left -= delta

	if is_dashing:
		dash_time_left -= delta
		velocity = current_dash_dir * dash_speed
		move_and_slide()
		if dash_time_left <= 0:
			is_dashing = false
		return

	# لو اللاعب قاعد يهاجم، نقدر نوقف الحركة مؤقتاً أو نخليها بطيئة
	if is_attacking:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		return

	var direction = joystick_vector
	if direction == Vector2.ZERO:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
		
		# تدوير اللاعب بالكامل (وهذا يخلي أريا الهجوم تدور معه تلقائياً!)
		var target_angle = direction.angle()
		rotation = lerp_angle(rotation, target_angle, 15.0 * delta)
		
		current_dash_dir = direction
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	update_animations(direction)

func update_animations(dir: Vector2) -> void:
	if not animated_sprite or is_attacking:
		return

	if velocity.length() > 10.0:
		if animated_sprite.animation != anim_run:
			animated_sprite.play(anim_run)
	else:
		if animated_sprite.animation != anim_idle:
			animated_sprite.play(anim_idle)

func trigger_dash() -> void:
	if dash_cooldown_left <= 0 and not is_dashing and not is_attacking:
		is_dashing = true
		dash_time_left = dash_duration
		dash_cooldown_left = dash_cooldown
		current_dash_dir = Vector2.RIGHT.rotated(rotation)

func trigger_attack() -> void:
	if is_attacking:
		return
		
	is_attacking = true
	
	if animated_sprite:
		animated_sprite.play(anim_attack)
		
	# تفعيل الـ Area2D عشان تصيد الأعداء وتضربهم
	if attack_area:
		attack_area.monitoring = true
		# فحص الأعداء المتواجدين داخل منطقة الهجوم لحظة الضربة
		var overlapping_bodies = attack_area.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body.is_in_group("enemy") and body.has_method("take_damage"):
				body.take_damage(20) # مقدار الضرر

func _on_animation_finished() -> void:
	# لما ينتهي أنميشن الهجوم، نرجع الحالة للطبيعي ونطفي الـ Area2D
	if animated_sprite and animated_sprite.animation == anim_attack:
		is_attacking = false
		if attack_area:
			attack_area.monitoring = false
