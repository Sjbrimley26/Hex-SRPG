extends Spatial

const ROTATION_SPEED = 2 * PI / 360
export var RADIUS = 5141
export var CENTER = Vector2(3840, 6651) # same as center tile . translation

var current_rotation = 0
var fixed_point = CENTER

func pan_camera():
	#NOT WORKING
	var ref = get_viewport().get_mouse_position().rotated(current_rotation)
	CENTER.x -= (ref.y - fixed_point.y)
	CENTER.y -= (ref.x - fixed_point.x)
	fixed_point = ref

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(_delta):
	if Input.is_action_pressed("ui_left"):
		current_rotation -= ROTATION_SPEED
	if Input.is_action_pressed("ui_right"):
		current_rotation += ROTATION_SPEED
	if current_rotation > 2 * PI:
		current_rotation = current_rotation - (2 * PI)
	if current_rotation < 0:
		current_rotation = 2 * PI + current_rotation
		
	#if Input.is_action_just_pressed("middle_click"):
		#var ref = get_viewport().get_mouse_position().rotated(current_rotation)
		#fixed_point = ref
		
	#if Input.is_action_pressed("middle_click"):
		#pan_camera()
		
	if Input.is_action_just_released("scroll_up"):
		self.translation.z -= 10
	if Input.is_action_just_released("scroll_down"):
		self.translation.z += 10
		
	if Input.is_action_pressed("ui_up"):
		RADIUS -= 10
		
	if Input.is_action_pressed("ui_down"):
		RADIUS += 10
	
	var pos = Utility.get_point_on_circle(current_rotation, RADIUS, CENTER)
	#self.translation.x = CENTER.x + RADIUS * cos(current_rotation)
	#self.translation.y = CENTER.y + RADIUS * sin(current_rotation)
	self.translation.x = pos.x
	self.translation.y = pos.y 
	$InnerGimbal.rotation.y = current_rotation + PI/2
