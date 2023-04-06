extends CharacterBody3D

var mag_in_gun = true
var mag_in_hand = false
var isHoldingMag = false

var speed = 7
const ACCEL_DEFAULT = 7
const ACCEL_AIR = 1
@onready var accel = ACCEL_DEFAULT
var gravity = 9.8
var jump = 5

var cam_accel = 40
var mouse_sense = 0.1
var snap

var direction = Vector3()
var gravity_direction = Vector3()
var movement = Vector3()

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var release_anim = $MagRelease
@onready var grab_anim = $GrabMag
#@onready var swap_anim = $MagSwap
@onready var insert_anim = $InsertMag
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

func grab_mag_1_from_vest():
	if mag_in_hand:
		grab_anim.play_backwards("mag_1")
		await grab_anim.animation_finished
		mag_in_hand = false
		return
	grab_anim.play("mag_1")
	await grab_anim.animation_finished
	mag_in_hand = true

func grab_mag_2_from_vest():
	if mag_in_hand:
		grab_anim.play_backwards("mag_2")
		await grab_anim.animation_finished
		mag_in_hand = false
		return
	grab_anim.play("mag_2")
	await grab_anim.animation_finished
	mag_in_hand = true

func grab_mag_3_from_vest():
	if mag_in_hand:
		grab_anim.play_backwards("mag_3")
		await grab_anim.animation_finished
		mag_in_hand = false
		return
	grab_anim.play("mag_3")
	await grab_anim.animation_finished
	mag_in_hand = true

func release_mag_from_gun():
	if mag_in_gun and !isHoldingMag:
		print("start")
		release_anim.play("drop_mag")
		await release_anim.animation_finished
		mag_in_gun = false
		print('end')
	elif isHoldingMag:
		release_anim.play("swap_mags")
		await release_anim.animation_finished
		mag_in_gun = true
	
func insert_mag_in_gun():
	if !mag_in_gun and mag_in_hand:
		insert_anim.play("insert_mag")
		await insert_anim.animation_finished
		reset_anim.play("reset_all")
	elif mag_in_gun and mag_in_hand:
		insert_anim.play("hold_mag")
		await insert_anim.animation_finished
		isHoldingMag = true
	mag_in_gun = true
	mag_in_hand = false

func _process(delta):
	if Input.is_action_just_pressed("mag_release"):
		release_mag_from_gun()	
	if Input.is_action_just_pressed("insert"):
		insert_mag_in_gun()
	if Input.is_action_just_pressed("mag_1"):
		grab_mag_1_from_vest()
	if Input.is_action_just_pressed("mag_2"):
		grab_mag_2_from_vest()
	if Input.is_action_just_pressed("mag_3"):
		grab_mag_3_from_vest()
		
	#camera physics interpolation to reduce physics jitter on high refresh-rate monitors
	if Engine.get_frames_per_second() > Engine.physics_ticks_per_second:
		camera.set_as_top_level(true)
		camera.global_transform.origin = camera.global_transform.origin.lerp(head.global_transform.origin, cam_accel * delta)
		camera.rotation.y = rotation.y
		camera.rotation.x = head.rotation.x
	else:
		camera.set_as_top_level(false)
		camera.global_transform = head.global_transform
		
func _physics_process(delta):
	#get keyboard input
	direction = Vector3.ZERO
	var h_rot = global_transform.basis.get_euler().y
	var f_input = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	var h_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
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
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		snap = Vector3.ZERO
		gravity_direction = Vector3.UP * jump
	
	#make it move
	velocity = velocity.lerp(direction * speed, accel * delta)
	movement = velocity + gravity_direction
	
	set_velocity(movement)
	# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `snap`
	set_up_direction(Vector3.UP)
	move_and_slide()
