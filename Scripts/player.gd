extends CharacterBody2D

@export_category("إعدادات الحركة")
@export var max_speed: float = 420.0
@export var acceleration: float = 3500.0
@export var friction: float = 3000.0

@export_category("إعدادات الـ Dash")
@export var dash_speed: float = 1100.0
@export var dash_duration: float = 0.12
@export var dash_cooldown: float = 0.7
@export var max_drag_distance: float = 80.0

@export_category("إعدادات الأنميشن")
@export var animated_sprite: AnimatedSprite2D
@export var anim_idle: String = "idle"
@export var anim_run: String = "run"
@export var anim_attack: String = "attack"

@export_category("القتال والصحة")
@export var attack_area: Area2D
@export var max_health: int = 100
@export var health_bar: ProgressBar
@export var attack_hit_frame: int = 2

var current_health: int = 100
var is_dashing: bool = false
var is_attacking: bool = false
var is_dead: bool = false
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var current_dash_dir: Vector2 = Vector2.RIGHT

var enemies_in_range: Array = []
var has_dealt_damage: bool = false

var is_mobile_device: bool = false

var joystick_touch_index: int = -1
var joystick_origin: Vector2 = Vector2.ZERO
var joystick_vector: Vector2 = Vector2.ZERO

var right_touch_index: int = -1
var right_touch_start_y: float = 0.0

var last_tap_time: int = 0
var double_tap_threshold: int = 300

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	update_health_bar()

	is_mobile_device = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")

	if attack_area:
		if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
			attack_area.body_entered.connect(_on_attack_area_body_entered)
		if not attack_area.body_exited.is_connected(_on_attack_area_body_exited):
			attack_area.body_exited.connect(_on_attack_area_body_exited)

	if animated_sprite:
		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)

func _input(event: InputEvent) -> void:
	if is_dead:
		return

	if not is_mobile_device:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				trigger_attack()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				trigger_dash()

		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_SHIFT:
				trigger_dash()
		return

	if is_mobile_device:
		var screen_width = get_viewport().get_visible_rect().size.x

		if event is InputEventScreenTouch:
			if event.pressed:
				if event.position.x < screen_width / 2:
					if joystick_touch_index == -1:
						joystick_touch_index = event.index
						joystick_origin = event.position
						joystick_vector = Vector2.ZERO
				else:
					var current_time = Time.get_ticks_msec()
					if current_time - last_tap_time < double_tap_threshold:
						trigger_dash()
						last_tap_time = 0
					else:
						last_tap_time = current_time
					
					if right_touch_index == -1:
						right_touch_index = event.index
						right_touch_start_y = event.position.y
			else:
				if event.index == joystick_touch_index:
					joystick_touch_index = -1
					joystick_vector = Vector2.ZERO
				elif event.index == right_touch_index:
					right_touch_index = -1

		elif event is InputEventScreenDrag:
			if event.index == joystick_touch_index:
				var diff = event.position - joystick_origin
				if diff.length() > max_drag_distance:
					diff = diff.normalized() * max_drag_distance

				if diff.length() > 5.0:
					joystick_vector = diff / max_drag_distance
				else:
					joystick_vector = Vector2.ZERO

			elif event.index == right_touch_index:
				var swipe_diff = event.position.y - right_touch_start_y
				if abs(swipe_diff) > 20 and not is_attacking:
					trigger_attack()
					right_touch_index = -1

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	if dash_cooldown_left > 0:
		dash_cooldown_left -= delta

	if is_dashing:
		dash_time_left -= delta
		velocity = current_dash_dir * dash_speed
		move_and_slide()
		if dash_time_left <= 0:
			is_dashing = false
		return

	if is_attacking:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		
		if not is_mobile_device:
			var mouse_dir = (get_global_mouse_position() - global_position).normalized()
			rotation = lerp_angle(rotation, mouse_dir.angle(), 25.0 * delta)

		if animated_sprite and animated_sprite.animation == anim_attack:
			if animated_sprite.frame == attack_hit_frame and not has_dealt_damage:
				has_dealt_damage = true
				execute_attack_damage()
		return

	var direction = Vector2.ZERO
	if is_mobile_device:
		direction = joystick_vector
	else:
		var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if input_vector != Vector2.ZERO:
			direction = input_vector.normalized()
		else:
			var pc_x = 0.0
			var pc_y = 0.0
			if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): pc_x += 1.0
			if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): pc_x -= 1.0
			if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): pc_y += 1.0
			if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): pc_y -= 1.0
			direction = Vector2(pc_x, pc_y).normalized()

	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
		current_dash_dir = direction
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	if is_mobile_device:
		if joystick_vector != Vector2.ZERO:
			rotation = lerp_angle(rotation, joystick_vector.angle(), 18.0 * delta)
	else:
		var mouse_pos = get_global_mouse_position()
		rotation = lerp_angle(rotation, (mouse_pos - global_position).angle(), 25.0 * delta)

	move_and_slide()
	update_animations()

func update_animations() -> void:
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
		
		if is_mobile_device and joystick_vector != Vector2.ZERO:
			current_dash_dir = joystick_vector.normalized()
		else:
			current_dash_dir = (get_global_mouse_position() - global_position).normalized()

func trigger_attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	has_dealt_damage = false

	if animated_sprite:
		animated_sprite.play(anim_attack)

func execute_attack_damage() -> void:
	for enemy in enemies_in_range:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(35)

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and not enemies_in_range.has(body):
		enemies_in_range.append(body)

func _on_attack_area_body_exited(body: Node2D) -> void:
	if enemies_in_range.has(body):
		enemies_in_range.erase(body)

func _on_animation_finished() -> void:
	if animated_sprite and animated_sprite.animation == anim_attack:
		is_attacking = false

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health -= amount
	if current_health < 0:
		current_health = 0
		
	update_health_bar()
	
	if current_health <= 0:
		die()

func update_health_bar() -> void:
	if health_bar:
		health_bar.value = current_health
		if current_health <= 25:
			health_bar.modulate = Color.RED
		else:
			health_bar.modulate = Color.WHITE

func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	if CloudManager.is_multiplayer_match:
		velocity = Vector2.ZERO
		get_tree().call_group("multiplayer_manager", "player_died")
	else:
		get_tree().reload_current_scene()
