extends CharacterBody2D

@export var speed: float = 300.0

func _physics_process(delta: float) -> void:
	# استقبال أزرار الحركة (يمين، يسار، فوق، تحت)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		velocity = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.y = move_toward(velocity.y, 0, speed)

	# تنفيذ الحركة الفعلية
	move_and_slide()
