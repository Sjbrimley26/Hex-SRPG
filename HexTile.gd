tool
extends MeshInstance
class_name Hex

export var color: Color
export var height: int
export var grid_coords: Vector2
export var base_color: Color
export var viewable = false

func make_pickable():
	get_child(0).input_ray_pickable = true

func change_mesh(m: Mesh):
	mesh = m
	var old = get_child(0)
	remove_child(old)
	old.queue_free()
	create_convex_collision()
	make_pickable()

func _init():
	create_convex_collision()

# Called when the node enters the scene tree for the first time.
func _ready():
	make_pickable()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var material = get_active_material(0)
	if material.albedo_color != color:
		material.albedo_color = color
	if not viewable:
		material.albedo_color = color.darkened(0.9)

static func axial_distance(vec1: Vector2, vec2: Vector2) -> float:
	return (abs(vec1.x - vec2.x) + abs(vec1.x + vec1.y - vec2.x - vec2.y) + abs(vec1.y - vec2.y)) / 2

static func axial_round(x: float, y: float) -> Vector2:
	var xgrid = round(x)
	var ygrid = round(y)
	var remx = x - xgrid
	var remy = y - ygrid
	if abs(remx) > abs(remy):
		return Vector2(xgrid + round(remx + 0.5 * remy), ygrid)
	else:
		return Vector2(xgrid, ygrid + round(remy + 0.5 * remx))


