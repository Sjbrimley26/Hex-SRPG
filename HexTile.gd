extends MeshInstance


export var color: Color
export var height: int
export var grid_coords: Vector2
export var base_color: Color

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
