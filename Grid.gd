tool
extends Spatial

var mesh: Mesh = preload("res://meshes/hex_mesh_1.tres")
var mesh_2: Mesh = preload("res://meshes/hex_mesh_2.tres")
var hex = preload("res://HexTile.tscn")
var rough_texture = preload("res://textures/BatteredMetal02_2K_Roughness.png")
#var texture = preload("res://textures/BatteredMetal02_2K_BaseColor.png")
var texture = preload("res://textures/NaturalStone01_2K_BaseColor.png")
var Config = preload("res://CONFIG.tres")
export var SIZE = 7 # should be odd for a nice sized hexagon

#const TILE_WIDTH = 384.0
#const TILE_HEIGHT = 221.7

onready var grid = []

func manhattan_distance(vec1: Vector2, vec2: Vector2) -> float:
	return abs(vec1.x - vec2.x) + abs(vec1.y - vec2.y)


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
		Vector2(x, y+1), #N
		Vector2(x+1, y), #NE
		Vector2(x+1, y-1), #SE
		Vector2(x, y-1), #S
		Vector2(x-1, y), #SW,
		Vector2(x-1, y+1) #NW
	]
	for pair in directions:
		if is_inbounds(pair.x, pair.y):
			found.append(pair)
	return found


func get_neighbors_recursive(x, y, n, found, checked):
	var to_check = get_immediate_neighbors(x, y)
	checked.append(Vector2(x, y))
	for neighbor in to_check:
		if not found.has(neighbor):
			found.append(neighbor)
		if n > 1:
			get_neighbors_recursive(neighbor.x, neighbor.y, n - 1, found, checked)
	return found


func get_neighbors(x, y, n):
	#DFS - need BFS version for distances
	var checked = []
	var found = []
	var to_check = get_immediate_neighbors(x, y)
	checked.append(Vector2(x, y))
	found.append(Vector2(x, y))
	for neighbor in to_check:
		if not found.has(neighbor):
			found.append(neighbor)
		if n > 1:
			get_neighbors_recursive(neighbor.x, neighbor.y, n - 1, found, checked)
	found.pop_front()
	return found


func get_neighbors_and_distances(x, y, n):
	var found = {
		Vector2(x, y): 0
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
					"tiles": get_immediate_neighbors(tile.x, tile.y),
					"distance": batch.distance + 1
				})
	var results = []
	for key in found.keys():
		var j = key.x
		var k = key.y
		results.append({
			"x": j, 
			"y": k, 
			"distance": found[key]
		})
	results.pop_front()
	return results


func find_path(x1, y1, x2, y2):
	# Returns an array of Vector2s which are equal to the x,y int of the tile in grid
	# A-star?
	if !is_inbounds(x1, y1) or !is_inbounds(x2, y2):
		return []
	var path = [Vector2(x1, y1)]
	var endgoal = Vector2(x2, y2)
	while path.back() != endgoal:
		var tile = path.back()
		var to_check = get_immediate_neighbors(tile.x, tile.y)
		var closest = Vector2(INF, INF)
		for t in range(to_check.size()):
			var vec = Vector2(to_check[t].x, to_check[t].y)
			if path.has(vec):
				continue
			if vec == endgoal:
				closest = vec
				break
			#if vec.distance_squared_to(endgoal) <= closest.distance_squared_to(endgoal):
				#closest = vec
			if manhattan_distance(vec, endgoal) < manhattan_distance(closest, endgoal):
				closest = vec
		path.append(closest)
	return path


func _on_mouse_enter(mi):
	mi.color = Color(0.7, 0, 0.3, 1)


func _on_mouse_exit(mi, color):
	mi.color = color


func _on_input(_cam, event, _pos, _norm, _shape_idx, x, y):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == false:
			var path = find_path(SIZE/2, SIZE/2, x, y)
			for m in path:
				var h = m.x
				var k = m.y
				var neighbor = grid[h][k]
				neighbor.color = Color(0.25, 0.1, 0.5, 1)
				if h == x and k == y:
					neighbor.change_mesh(mesh_2)
					connect_hex_signals(neighbor)
			#for n in get_neighbors_and_distances(x, y, 2):
				#var h = n.x
				#var k = n.y
				#var neighbor = grid[h][k]
				#neighbor.material_override.albedo_color = Color(1 * 1/float(n.distance), 0, 1 * 1/float(n.distance), 1)


func connect_hex_signals(mi):
	var body: StaticBody = mi.get_child(0)
	var _err1 = body.connect("mouse_entered", self, "_on_mouse_enter", [mi])
	var _err2 = body.connect("mouse_exited", self, "_on_mouse_exit", [mi, mi.base_color])
	var _err3 = body.connect("input_event", self, "_on_input", [mi.grid_coords.x, mi.grid_coords.y])


func generate_tiles():
	for x in range(SIZE):
		grid.append([])
		grid[x].resize(SIZE)
		for y in range(SIZE):
			if not is_inbounds(x, y):
				continue
				#this bit removes the corners of the rhombus, turning it into a hexagon
				
			var mi = hex.instance()
			var material = SpatialMaterial.new()
			material.roughness = 0.5
			material.roughness_texture = rough_texture
			material.albedo_texture = texture
			#material.metallic = 1
			var color = Color(x * 5 / 255.0, abs(y-x) * 3 / 255.0, y * 5 / 255.0, 1)
			if x == SIZE / 2 and y == SIZE / 2: # center tile
				color = Color(1, 1, 1)
			mi.color = color
			mi.base_color = color
			mi.material_override = material
			#mi.translate(Vector3(x * TILE_WIDTH, y * TILE_HEIGHT * 2 + x * TILE_HEIGHT, 0))
			mi.translate(Vector3(x * Config.TILE_WIDTH - 50, y * Config.TILE_HEIGHT * 2, 0))
			#mi.rotate_z(deg2rad(-15))
			mi.grid_coords = Vector2(x, y)
			if not Engine.editor_hint:
				connect_hex_signals(mi)
			grid[x][y] = mi
			call_deferred("add_child", mi)


func _ready():
	generate_tiles()
	var center_tile = grid[SIZE/2][SIZE/2]
	$OuterGimbal.RADIUS = Config.TILE_HEIGHT * SIZE + 500
	$OuterGimbal.CENTER = Vector2(center_tile.translation.x, center_tile.translation.y)
