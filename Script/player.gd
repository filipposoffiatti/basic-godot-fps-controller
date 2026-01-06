extends CharacterBody3D

var speed = 8 #Player speed
var gravity = 9.81 #Gravity
var senstivity = 0.01 #Senstivity

@onready var head = $Head #Head reference (Camera pivot)
@onready var camera = $Head/Camera3D #Camera reference

var player_velocity = Vector3.ZERO #Empty vector of the player velocity

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	 #Function to block mouse movement
	
func _unhandled_input(event): #Used for global inputs
	
	if event is InputEventMouseMotion: #If there is mouse movement
		head.rotate_y(-event.relative.x * senstivity) #Rotate head
		camera.rotate_x(-event.relative.y * senstivity) #Rotate camera
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		#Set a clamp to the max rotation upwards and downwards of the camera
	

func _physics_process(delta): #Phyisics function
	
	var player_direction = Vector3.ZERO #Empty vector of the player direction
	
	if Input.is_action_pressed("Forward"): 
		player_direction.z -= 1
	if Input.is_action_pressed("Backward"): 
		player_direction.z += 1
	if Input.is_action_pressed("Left"): 
		player_direction.x -= 1
	if Input.is_action_pressed("Right"): 
		player_direction.x += 1	
	if Input.is_action_pressed("Sprint"):
			speed = 14
	if Input.is_action_just_released("Sprint"):
			speed = 8
	if Input.is_action_pressed("Shift"):
			speed = 4
	if Input.is_action_just_released("Shift"):
			speed = 8
		
	if player_direction != Vector3.ZERO: #If the player direction is not empty
		player_direction = (head.transform.basis * player_direction).normalized() 
		#Transforms player direction based on the head
		#normalized() <- Normalizes player direction
		
	player_velocity.x = player_direction.x * speed #Sets pv.x to pd.x * speed
	player_velocity.z = player_direction.z * speed #Sets pv.z to pd.z * speed
	
	if is_on_floor() and Input.is_action_pressed("Jump"): 
		player_velocity.y = 4
		#If the player is on ground and presses "Jump" it makes him jump
	
	if not is_on_floor():
		player_velocity.y -= (gravity * delta) 
		#If the player is not on the floor it makes him fall
		
	velocity = player_velocity #Define where the player goes based on the player velocity
	move_and_slide() #Makes the player move
		
	
	
