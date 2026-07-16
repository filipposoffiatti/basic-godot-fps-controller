extends CharacterBody3D

#SPEED VARIABLES
var base_speed = 3.0 #Base player speed
var speed = base_speed #Current speed (Default to base_speed)
var sprint_speed = 6.0 #Sprint player speed
var shift_speed = 2.0 #Shift player speed
var crouch_speed = 1.0 #Crouch player speed

#TOGGLES
var is_sprinting := false #Sprint toggle
var is_crouching := false #Crouch toggle

#JUMP BUFFER
var jump_buffer_time = 0.15 #Jump buffer time
var jump_buffer_timer = 0.0 #Jump buffer timer

#OTHERS
var gravity = 9.81 #Gravity
var senstivity = 0.006 #Mouse senstivity

#HEAD BOB
@export var bob_frequency = 10.0 #Default head bob frequency
@export var bob_height = 0.05 #Default head bob "height"
@export var bob_sprint_frequency_multiplier = 1.3 #Spriting head bob multiplier
@export var bob_sprint_height_multiplier = 1.1 #Sprinting head bob "height" multiplier
@export var bob_smooth = 8.0 #Head bob smoothness

var bob_time = 0.0
var bob_current_intensity = 0.0
var camera_default_position: Vector3

@onready var head = $Head #Head reference
@onready var camera = $Head/Camera3D #Camera reference

var player_velocity = Vector3.ZERO #Empty vector of the player velocity

func _ready(): #Called when the player is ready on the scene
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#Function that blocks the mouse movement
	
	camera_default_position = camera.position #Sets camera default position when player is ready
	
func _unhandled_input(event): #Used for the unhandled inputs
	
	if event is InputEventMouseMotion: #If there is mouse movement
		head.rotate_y(-event.relative.x * senstivity) #Rotate head
		camera.rotate_x(-event.relative.y * senstivity / 1.5) #Rotate camera
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		#Set a clamp to the max rotation upwards and downwards of the camera
		
func _get_target_speed(): #Used for returning the needed speed based on the current action
	
	if is_crouching == true:
		return crouch_speed
	if Input.is_action_pressed("Shift"):
		return shift_speed
	if is_sprinting == true:
		return sprint_speed
	return base_speed
	
func _update_head_bob(delta): #Used for the head bob
	
	#Set a Vector2 to get total speed of the horizontal speed (in any direction)
	var horizontal_speed = Vector2(player_velocity.x, player_velocity.z).length()
	
	#Sets "moving" to true if both conditions are true
	var moving = horizontal_speed > 0.5 and is_on_floor()
	
	#Sets the target_intesity to 1 if it's moving or 0 if not
	var target_intensity = 1.0 if moving else 0.0
	
	#The current intensity is interpolated with the target_intensity (current frame) by the smoothness
	bob_current_intensity = lerp(bob_current_intensity, target_intensity, bob_smooth * delta)
	
	#If the player sprints the frequency and the height of the head bob increase
	var frequency_multiplier = bob_sprint_frequency_multiplier if is_sprinting else 1.0
	var height_multiplier = bob_sprint_height_multiplier if is_sprinting else 1.0
	
	#If the intensity is greater than 0 gets multpilied by the frequency and the frequency multiplier
	if bob_current_intensity > 0.001:
		bob_time += delta * bob_frequency * frequency_multiplier
	else:
		bob_time = 0.0
	
	#The vertical offset is set based off -1 and 1 of the sin() function times the maxium height with or without the multiplier and by the current intensity
	var vertical_offset = sin(bob_time) * bob_height * height_multiplier * bob_current_intensity
	
	#It changes the vertical camera position
	camera.position = camera_default_position + Vector3(0, vertical_offset, 0)
		
func _physics_process(delta): #Used for physics related things (Locked at 60fps)
	
	#WASD
	var player_direction = Vector3.ZERO #Empty vector of the player direction
	
	var inputs = Input.get_vector("Left", "Right", "Forward", "Backward")
	#A 2 vector that return inputs.x based of the first two inputs and input.y based on the second two
	
	player_direction = (head.transform.basis * Vector3(inputs.x, 0, inputs.y))
	#Assigns the inputs vector to the player_direction vector based on the head direction
 
	#SPRINTING
	if Input.is_action_pressed("Sprint"): #Checking if the player is sprinting
		is_sprinting = true #Sets is_sprinting true
	else:
		is_sprinting = false #Sets is_sprinting false
		
	#CROUCHING
	if is_on_floor() and Input.is_action_just_pressed("Crouch"):
		is_crouching = !is_crouching #When pressing "crouch" the state of the variable is inverted
 
	if is_crouching == true: #While crouch_toggle is true the player stays in crouch
		$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, 0.5, delta * 10.0)
	else:
		$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, 1.0, delta * 10.0)
	
	#SPEED 
	var target_speed = _get_target_speed()
	speed = lerp(speed, target_speed, 0.1)
	
	#GRAVITY
	if is_on_floor(): #When is on floor the player_velocity.y is set to 0
		player_velocity.y = 0
	else: #When is not on floor the player_velocity.y is changed
		if player_velocity.y > 0:
			player_velocity.y -= (gravity * delta * 1.5)
			#While the player is going up (velocity.y positive) gravity is normal
		else:
			player_velocity.y -= (gravity * delta * 1.8)
			#While the player is falling (velocity.y negative or zero) gravity is increased
	
	#JUMPING
	if jump_buffer_timer > 0: #If the buffer_timer is greater than 0 it begins to reduce every delta frame
		jump_buffer_timer -= delta
 
	if Input.is_action_just_pressed("Jump"): #If the player jumps the buffer time is added to the timer
		jump_buffer_timer = jump_buffer_time
 
	if is_on_floor() and jump_buffer_timer > 0: #If the player is on the floor and the buffer is not 0 the player jumps
		player_velocity.y = 6
		jump_buffer_timer = 0.0
	
	#MOVEMENT
	if is_on_floor(): #If the player is on the floor the player velocity is interpolated beetween the player direction times the speed and the velocity of the previous frame
		player_velocity.x = lerp(player_velocity.x, player_direction.x * speed, 0.2)
		player_velocity.z = lerp(player_velocity.z, player_direction.z * speed, 0.2)
	else: #If the player is not on the floor the player can only change the direction a little
		player_velocity.x = lerp(player_velocity.x, player_direction.x * speed, 0.03)
		player_velocity.z = lerp(player_velocity.z, player_direction.z * speed, 0.03)
 
	velocity = player_velocity #Define where the player goes based on the player velocity
	move_and_slide() #Makes the player move
	
	#I put it here to get the update velocity parameters of the current frame
	_update_head_bob(delta)
