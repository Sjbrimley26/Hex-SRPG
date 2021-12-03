extends Spatial

const ROTATION_SPEED = 2 * PI / 360
export var RADIUS = 5141
export var CENTER = Vector2(3840, 6651) # same as center tile . translation

var current_rotation = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(_delta):
	if Input.is_action_pressed("ui_left"):
		current_rotation += ROTATION_SPEED
	if Input.is_action_pressed("ui_right"):
		current_rotation -= ROTATION_SPEED
	if current_rotation > 2 * PI:
		current_rotation = current_rotation - (2 * PI)
	if current_rotation < 0:
		current_rotation = 2 * PI + current_rotation
	
	var pos = Utility.get_point_on_circle(current_rotation, RADIUS, CENTER)
	#self.translation.x = CENTER.x + RADIUS * cos(current_rotation)
	#self.translation.y = CENTER.y + RADIUS * sin(current_rotation)
	self.translation.x = pos.x
	self.translation.y = pos.y 
	$InnerGimbal.rotation.y = current_rotation + PI/2
