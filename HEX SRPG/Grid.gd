tool
extends Spatial

var mesh: Mesh = preload("res://meshes/hex_mesh_1.tres")

export var SIZE = 21 # should be odd for a nice sized hexagon

const TILE_WIDTH = 384.0
const TILE_HEIGHT = 221.7

onready var grid = []

func is_inbounds(x, y):
	if (x + y <= SIZE / 2 - 1) or (x + y >= SIZE + SIZE / 2) or x < 0 or y < 0 or x >= SIZE or y >= SIZE:
		return false
	else:
		return true


func get_immediate_neighbors(x, y):
	if not is_inbounds(x, y):
		return []
	var found = []
	var directions = [
		[x, y+1], #N
		[x+1, y], #NE
		[x+1, y-1], #SE
		[x, y-1], #S
		[x-1, y], #SW,
		[x-1, y+1] #NW
	]
	for pair in directions:
		if is_inbounds(pair[0], pair[1]):
			found.append(pair)
	return found


func get_neighbors_recursive(x, y, n, found, checked):
	var to_check = get_immediate_neighbors(x, y)
	checked.append([x, y])
	for neighbor in to_check:
		if not found.has(neighbor):
			found.append(neighbor)
		if n > 1:
			get_neighbors_recursive(neighbor[0], neighbor[1], n - 1, found, checked)
	return found


func get_neighbors(x, y, n):
	#DFS - need BFS version for distances
	var checked = []
	var found = []
	var to_check = get_immediate_neighbors(x, y)
	checked.append([x, y])
	found.append([x, y])
	for neighbor in to_check:
		if not found.has(neighbor):
			found.append(neighbor)
		if n > 1:
			get_neighbors_recursive(neighbor[0], neighbor[1], n - 1, found, checked)
	found.pop_front()
	return found


func get_neighbors_and_distances(x, y, n):
	var found = {
		[x, y]: 0
	}
	var to_check = [{
		"tiles": get_immediate_neighbors(x, y),
		"distance": 1
	}]
	while to_check.size() > 0:
		var batch = to_check.pop_front()
		for tile in batch.tiles:
			if found.has(tile):
				continue
			found[tile] = batch.distance
			if batch.distance < n:
				to_check.append({
					"tiles": get_immediate_neighbors(tile[0], tile[1]),
					"distance": batch.distance + 1
				})
	var results = []
	for key in found.keys():
		var j = key[0]
		var k = key[1]
		results.append({
			"x": j, 
			"y": k, 
			"distance": found[key]
		})
	results.pop_front()
	return results
	
	
func find_path(x1, y1, x2, y2):
	# A-star?
	var path = [Vector2(x1, y1)]
	var endgoal = Vector2(x2, y2)
	while !path.back().is_equal_approx(endgoal):
		var tile = path.back()
		var to_check = get_immediate_neighbors(tile.x, tile.y)
		var closest = Vector2(INF, INF)
		for t in range(to_check.size()):
			var vec = Vector2(to_check[t][0], to_check[t][1])
			if path.has(vec):
				continue
			if vec.is_equal_approx(endgoal):
				closest = vec
				break
			if vec.distance_squared_to(endgoal) <= closest.distance_squared_to(endgoal):
				closest = vec
		path.append(closest)
	return path


func _on_mouse_enter(mi):
	mi.material_override.albedo_color = Color(0.7, 0, 0.3, 1)
	
func _on_mouse_exit(mi, color):
	mi.material_override.albedo_color = color
	
func _on_input(_cam, event, _pos, _norm, _shape_idx, x, y):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == false:
			var path = find_path(0, 10, x, y)
			for m in path:
				var h = m.x
				var k = m.y
				var neighbor = grid[h][k]
				neighbor.material_override.albedo_color = Color(0.25, 0.1, 0.5, 1)
			#for n in get_neighbors_and_distances(x, y, 12):
				#var h = n.x
				#var k = n.y
				#var neighbor = grid[h][k]
				#neighbor.material_override.albedo_color = Color(2 * 1/float(n.distance), 0, 2 * 1/float(n.distance), 1)


func generate_tiles():
	for x in range(SIZE):
		grid.append([])
		grid[x].resize(SIZE)
		for y in range(SIZE):
			if not is_inbounds(x, y):
				continue
				#this bit removes the corners of the rhombus, turning it into a hexagon
				
			var mi = MeshInstance.new()
			mi.mesh = mesh
			var material = SpatialMaterial.new()
			var color = Color(x * 5 / 255.0, abs(y-x) * 3 / 255.0, y * 5 / 255.0, 1)
			material.albedo_color = color
			mi.material_override = material
			mi.translate(Vector3(x * TILE_WIDTH, y * TILE_HEIGHT * 2 + x * TILE_HEIGHT, 0))
			mi.create_convex_collision()
			var body: StaticBody = mi.get_child(0)
			body.input_ray_pickable = true
			var _err1 = body.connect("mouse_entered", self, "_on_mouse_enter", [mi])
			var _err2 = body.connect("mouse_exited", self, "_on_mouse_exit", [mi, color])
			var _err3 = body.connect("input_event", self, "_on_input", [x, y])
			grid[x][y] = mi
			call_deferred("add_child", mi)


func _ready():
	generate_tiles()
