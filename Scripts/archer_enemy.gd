extends CharacterBody2D

@export_category("إعدادات الخصائص والدم")
@export var max_health: int = 50
@export var speed: float = 130.0
@export var attack_range: float = 300.0 # المسافة التي يتوقف عندها ويرمي
@export var attack_cooldown: float = 2.0

@export_category("المراجع والروابط")
@export var arrow_scene: PackedScene # اسحب مشهد Arrow.tscn هنا من المحرر
@export var attack_hit_frame: int = 2 # رقم الفريم الذي يخرج فيه السهم بالأنيميشن

@export_category("نقطة انطلاق السهم")
@export var arrow_spawn_point: Marker2D # ضع Marker2D عند يد/قوس العدو في المشهد واسحبه هنا. لو تركته فاضي هينطلق من مركز العدو

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var attack_timer: Timer
var current_health: int = 50
var target_node: Node2D = null

var can_attack: bool = true
var is_attacking: bool = false
var is_dead: bool = false

func _ready() -> void:
	add_to_group("enemy")
	current_health = max_health

	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)

	if animated_sprite:
		animated_sprite.frame_changed.connect(_on_frame_changed)
		animated_sprite.animation_finished.connect(_on_animation_finished)

	if nav_agent:
		nav_agent.path_desired_distance = 10.0
		nav_agent.target_desired_distance = 10.0

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	find_target()

	if not is_instance_valid(target_node):
		velocity = Vector2.ZERO
		return

	var distance_to_target = global_position.distance_to(target_node.global_position)

	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if distance_to_target > attack_range:
		if nav_agent:
			nav_agent.target_position = target_node.global_position
			var next_path_pos = nav_agent.get_next_path_position()
			var dir = (next_path_pos - global_position).normalized()

			velocity = dir * speed
			rotation = lerp_angle(rotation, dir.angle(), 10.0 * delta)
		else:
			var dir = (target_node.global_position - global_position).normalized()
			velocity = dir * speed
			rotation = lerp_angle(rotation, dir.angle(), 10.0 * delta)

		if animated_sprite and animated_sprite.animation != "run":
			animated_sprite.play("run")

	else:
		velocity = Vector2.ZERO
		var dir = (target_node.global_position - global_position).normalized()
		rotation = lerp_angle(rotation, dir.angle(), 10.0 * delta)

		if can_attack:
			start_attack()

	move_and_slide()

func find_target() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_node = players[0]

func start_attack() -> void:
	can_attack = false
	is_attacking = true
	if animated_sprite:
		animated_sprite.play("attack")

func _on_frame_changed() -> void:
	if is_dead:
		return
	if is_attacking and animated_sprite and animated_sprite.animation == "attack" and animated_sprite.frame == attack_hit_frame:
		shoot_arrow()

func shoot_arrow() -> void:
	if not arrow_scene or not is_instance_valid(target_node):
		return

	# لقطة لحظية (Snapshot) لموقع اللاعب في هذه اللحظة بالذات
	var snapshotted_position: Vector2 = target_node.global_position

	# نقطة الانطلاق: لو فيه Marker2D محدد نستخدم موقعه (بيتحرك أوتوماتيك مع دوران وموقع العدو)
	# ولو مفيش، نرجع لموقع العدو نفسه زي الأول
	var spawn_position: Vector2 = arrow_spawn_point.global_position if arrow_spawn_point else global_position

	var arrow_instance = arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow_instance)
	arrow_instance.launch(spawn_position, snapshotted_position)

func _on_animation_finished() -> void:
	if is_dead:
		if animated_sprite and animated_sprite.animation == "die":
			queue_free()
		return

	if animated_sprite and animated_sprite.animation == "attack":
		is_attacking = false
		if attack_timer:
			attack_timer.start()

func _on_attack_timer_timeout() -> void:
	can_attack = true

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health -= amount
	print("العدو الرامي اتضرب! الدم المتبقي: ", current_health)

	if current_health <= 0:
		die()

func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	velocity = Vector2.ZERO

	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	if typeof(CloudManager) != TYPE_NIL:
		CloudManager.current_kills += 1
		CloudManager.update_progress(CloudManager.current_wave, CloudManager.current_kills)
		print("تم زيادة قتلة! إجمالي القتلات الحالية: ", CloudManager.current_kills)

	if animated_sprite:
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("die"):
			animated_sprite.play("die")
		else:
			queue_free()
