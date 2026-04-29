extends CharacterBody3D

var speed = 8.0 #Player speed
var gravity = 9.81 #Gravity
var senstivity = 0.01 #Mouse senstivity
var is_sprinting := false #Sprinting flag

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
	
	var inputs = Input.get_vector("Left", "Right", "Forward", "Backward") #A 2d vector that contains the movement inputs
	
	player_direction = Vector3(inputs.x, 0, inputs.y) #Assigns the inputs vector to the player_direction vector
			
	if Input.is_action_pressed("Sprint"): #Checking if the player is sprinting
		is_sprinting = true
	else:
		is_sprinting = false
		
	if is_on_floor(): #If the player is sprinting on the floor it sprints gradually with lerp()
		if is_sprinting == true:
			speed = lerp(speed, 14.0, 0.05)
		else: #If not he doesn't
			speed = lerp(speed, 8.0, 0.1)
			
	if Input.is_action_pressed("Shift"): #The player goes into "shift" gradually
			speed = lerp(speed, 4.0, 0.5)
	if Input.is_action_just_released("Shift"): #the player exits "shift" gradually
			speed = lerp(speed, 8.0, 0.3)
		
	if player_direction != Vector3.ZERO: #If the player direction is not empty
		player_direction = (head.transform.basis * player_direction)
		#Transforms player direction based on the head
		
	if is_on_floor(): #If the player is on the floor the player velocity is interpolated beetween the player direction times the speed and the velocity of the previous frame
		player_velocity.x = lerp(player_velocity.x, player_direction.x * speed, 0.2)
		player_velocity.z = lerp(player_velocity.z, player_direction.z * speed, 0.2)
		
	else: #If the player is not on the floor the player can only change the direction a little
		player_velocity.x = lerp(player_velocity.x, player_direction.x * speed, 0.03)
		player_velocity.z = lerp(player_velocity.z, player_direction.z * speed, 0.03)
	
	if is_on_floor() and Input.is_action_pressed("Jump"): 
		player_velocity.y = 6
		#If the player is on ground and presses "Jump" it makes him jump
	
	if not is_on_floor(): 
		
		if player_velocity.y < 0:
			player_velocity.y -= (gravity * delta) 
			#When the player jumps, while he goes up the gravity is normal
		else:
			player_velocity.y -= (gravity * delta * 2.5) 
			#When the player is falling the gravity is increased
		
	velocity = player_velocity #Define where the player goes based on the player velocity
	move_and_slide() #Makes the player move
		
	
	
