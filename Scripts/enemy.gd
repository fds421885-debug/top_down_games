extends CharacterBody2D

@export_category("Movement Settings")
@export var speed: float = 180.0
@export var use_pathfinding: bool = true

@export_category("Combat Settings")
## حدد هنا كم ضربة بالسيف يحتاج العدو عشان يموت (مثلاً 1، 2، 3...)
@export var hits_to_die: int = 1
@export var damage_on_touch: int = 25

@export_category("Animation Settings")
@export var anim_run: String = "run"
@export var anim_death: String = "death" # انميشن الانفجار أو الموت

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = get_node_or_null("NavigationAgent2D")
@onready var hit_box: Area2D = get_node_or_null("HitBox")

var current_hits: int = 0
var is_dead: bool = false
var player: Node2D = null

# حماية لمنع تسجيل ضربات السيف المزدوجة في نفس الفريم
var can_take_damage: bool = true
var damage_cooldown_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")

	if nav_agent:
		nav_agent.path_desired_distance = 4.0
		nav_agent.target_desired_distance = 4.0
		nav_agent.avoidance_enabled = true

	# ربط حساس التلامس السريع مع اللاعب
	if hit_box:
		if not hit_box.body_entered.is_connected(_on_hit_box_body_entered):
			hit_box.body_entered.connect(_on_hit_box_body_entered)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	# إدارة مؤقت الحماية للضربات
	if not can_take_damage:
		damage_cooldown_timer -= delta
		if damage_cooldown_timer <= 0:
			can_take_damage = true

	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	var direction: Vector2 = Vector2.ZERO

	if use_pathfinding and nav_agent:
		nav_agent.target_position = player.global_position
		if not nav_agent.is_navigation_finished():
			var next_point: Vector2 = nav_agent.get_next_path_position()
			direction = (next_point - global_position).normalized()
	else:
		direction = (player.global_position - global_position).normalized()

	velocity = direction * speed
	move_and_slide()

	_update_animation(direction)

func _update_animation(direction: Vector2) -> void:
	if not animated_sprite:
		return

	if direction.x > 0.05:
		animated_sprite.flip_h = false
	elif direction.x < -0.05:
		animated_sprite.flip_h = true

	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_run):
		if animated_sprite.animation != anim_run:
			animated_sprite.play(anim_run)

# --- حساس التلامس السريع جداً (الانفجار الفوري عند لمس اللاعب) ---
func _on_hit_box_body_entered(body: Node2D) -> void:
	if is_dead:
		return

	if body.is_in_group("player"):
		# خصم الدم من اللاعب فوراً
		if body.has_method("take_damage"):
			body.take_damage(damage_on_touch)
		
		# تنفيذ الانفجار والموت فوراً بدون أي تأخير
		trigger_explosion_death()

# --- استقبال ضربة السيف مع الالتزام التام بالـ hits_to_die ---
func take_damage(_amount: int = 1) -> void:
	if is_dead or not can_take_damage:
		return

	# تفعيل حماية قصيرة جداً (0.2 ثانية) لمنع احتساب الضربة مرتين بالخطأ
	can_take_damage = false
	damage_cooldown_timer = 0.2

	current_hits += 1
	print("العدو انضرب بالسيف! الضربة الحالية: ", current_hits, " / المطلوبة: ", hits_to_die)

	if current_hits >= hits_to_die:
		die_by_sword()

# موت العدو بالسيف مع تشغيل انميشن الموت
func die_by_sword() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO

	if hit_box:
		hit_box.set_deferred("monitoring", false)

	notify_spawner()

	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_death):
		animated_sprite.play(anim_death)
		await animated_sprite.animation_finished
		queue_free()
	else:
		queue_free()

# تفجير العدو فوراً عند لمس اللاعب
func trigger_explosion_death() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO

	if hit_box:
		hit_box.set_deferred("monitoring", false)

	notify_spawner()

	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_death):
		animated_sprite.play(anim_death)
		await animated_sprite.animation_finished
		queue_free()
	else:
		queue_free()

# إبلاغ نظام الويفات بموت العدو
func notify_spawner() -> void:
	var spawner = get_tree().get_first_node_in_group("spawner")
	if spawner and spawner.has_method("on_enemy_defeated"):
		spawner.on_enemy_defeated()
