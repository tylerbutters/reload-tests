extends CharacterBody3D

const ACCEL_DEFAULT = 7
const ACCEL_AIR = 1
var speed = 7
var gravity = 9.8
var jump = 5
var direction = Vector3()
var gravity_direction = Vector3()
var movement = Vector3()
var camera_accel = 40
var mouse_sense = 0.1
var snap

var gun_has_mag = true
var is_holding_mag = false
var is_grabbing_gun_mag = false

@onready var accel = ACCEL_DEFAULT
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var mag_release_anim = $MagRelease
@onready var hold_mag_anim = $root/World/Player/HoldMag
@onready var insert_mag_anim = $InsertMag
@onready var reset_anim = $Reset

func _ready():
	#hides the cursor
	reset_anim.play("reset_all")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	#get mouse input for camera rotation
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func dropMag():
	mag_release_anim.play("drop_mag")
	await mag_release_anim.animation_finished
	gun_has_mag = false
	
	
func swapMags():
	mag_release_anim.play("swap_mags")
	await mag_release_anim.animation_finished
	reset_anim.play("reset_all")
	gun_has_mag = true
	is_holding_mag	= false
	is_grabbing_gun_mag = false
	
	
func insertMag():
	insert_mag_anim.play("insert_mag")
	await insert_mag_anim.animation_finished
	reset_anim.play("reset_all")
	gun_has_mag = true
	is_holding_mag = false
		
		
func _process(delta):
	if Input.is_action_just_pressed("MAG_RELEASE") and gun_has_mag and not is_grabbing_gun_mag:
		dropMag()
	if Input.is_action_just_pressed("MAG_RELEASE") and is_grabbing_gun_mag:
		swapMags()
			
	if Input.is_action_just_pressed("INSERT_MAG") and not gun_has_mag and is_holding_mag:
		insertMag()
	if Input.is_action_pressed("INSERT_MAG") and gun_has_mag and not is_grabbing_gun_mag:
		insert_mag_anim.play("hold_mag")
		is_grabbing_gun_mag = true
	if Input.is_action_just_released("INSERT_MAG") and gun_has_mag and not is_holding_mag:
		insert_mag_anim.play_backwards("hold_mag")
		is_grabbing_gun_mag = false
	
	if Input.is_action_pressed("MAG_1") and not is_holding_mag:
		hold_mag_anim.play("mag_1")
		is_holding_mag = true
	if Input.is_action_just_released("MAG_1") and is_holding_mag:
		hold_mag_anim.play_backwards("mag_1")
		is_holding_mag = false
	if Input.is_action_pressed("MAG_2") and not is_holding_mag:
		hold_mag_anim.play("mag_2")
		is_holding_mag = true
	if Input.is_action_just_released("MAG_2"):
		hold_mag_anim.play_backwards("mag_2")
		is_holding_mag = false
	if Input.is_action_pressed("MAG_3") and not is_holding_mag:
		hold_mag_anim.play("mag_3")
		is_holding_mag = true
	if Input.is_action_just_released("MAG_3"):
		hold_mag_anim.play_backwards("mag_3")
		is_holding_mag = false
		
	#camera physics interpolation to reduce physics jitter on high refresh-rate monitors
	if Engine.get_frames_per_second() > Engine.physics_ticks_per_second:
		camera.set_as_top_level(true)
		camera.global_transform.origin = camera.global_transform.origin.lerp(head.global_transform.origin, camera_accel * delta)
		camera.rotation.y = rotation.y
		camera.rotation.x = head.rotation.x
	else:
		camera.set_as_top_level(false)
		camera.global_transform = head.global_transform
		
		
func _physics_process(delta):
	#get keyboard input
	direction = Vector3.ZERO
	var h_rot = global_transform.basis.get_euler().y
	var f_input = Input.get_action_strength("MOVE_BACKWARDS") - Input.get_action_strength("MOVE_FORWARDS")
	var h_input = Input.get_action_strength("MOVE_RIGHT") - Input.get_action_strength("MOVE_LEFT")
	direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
	
	#jumping and gravity
	if is_on_floor():
		snap = -get_floor_normal()
		accel = ACCEL_DEFAULT
		gravity_direction = Vector3.ZERO
	else:
		snap = Vector3.DOWN
		accel = ACCEL_AIR
		gravity_direction += Vector3.DOWN * gravity * delta
		
	if Input.is_action_just_pressed("JUMP") and is_on_floor():
		snap = Vector3.ZERO
		gravity_direction = Vector3.UP * jump
	
	#make it move
	velocity = velocity.lerp(direction * speed, accel * delta)
	movement = velocity + gravity_direction
	
	set_velocity(movement)
	# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `snap`
	set_up_direction(Vector3.UP)
	move_and_slide()
