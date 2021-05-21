extends KinematicBody3D

@export var mouse_sensitivity := 0.35
#var speed := 15

@onready var head = $Head

var direction := Vector3.ZERO
var accel := 0
var speed := 0
var medium = "ground"
var accel_type := {
	"ground": 12,
	"air": 1,
	"water": 4
	}
var speed_type := {
	"ground": 15,
	"air": 15,
	"water": 7.5
	}
var gravity := 28
var jump := 14

var velocity := Vector3.ZERO
var movement := Vector3.ZERO
var gravity_vec := Vector3.ZERO
var slide := Vector3.ZERO
var snap := Vector3.ZERO

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func aim(event) -> void:
	var mouse_motion = event as InputEventMouseMotion
	
	if mouse_motion:
		rotation_degrees.y -= mouse_motion.relative.x * mouse_sensitivity
		
		var current_tilt: float = head.rotation_degrees.x
		current_tilt -= mouse_motion.relative.y * mouse_sensitivity
		head.rotation_degrees.x = clamp(current_tilt, -90, 90)

func _input(event) -> void:
	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	aim(event)
	
func _physics_process(delta):
	direction = Vector3.ZERO
	
	if is_on_floor():
		snap = -get_floor_normal()
		medium = "ground"
		gravity_vec = Vector3.ZERO
	else:
		snap = Vector3.DOWN
		medium = "air"
		gravity_vec += Vector3.DOWN * gravity * delta
		
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		snap = Vector3.ZERO
		gravity_vec = Vector3.UP * jump
	
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	
	if direction.length() > 0: # normalized() will return a null
		direction = direction.normalized()
	
	speed = speed_type[medium]
	accel = accel_type[medium]
	
	velocity = velocity.lerp(direction * speed, accel * delta)
	
	movement = velocity + gravity_vec
	
	slide = move_and_slide_with_snap(movement, snap, Vector3.UP)
	
	if not is_on_floor(): # while in mid-air collisions affect momentum
		velocity.x = slide.x
		velocity.z = slide.z
		gravity_vec.y = slide.y