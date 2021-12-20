tool
extends Spatial

var hex = preload("res://HexTile.tscn")
var rough_texture = preload("res://textures/BatteredMetal02_2K_Roughness.png")
var texture = preload("res://textures/TexturesCom_RockSmooth0076_1_seamless_S.jpg")
#var texture = preload("res://textures/TexturesCom_MarbleVeined0001_1_seamless_S.jpg")
#var texture = preload("res://textures/TexturesCom_BrickRound0050_1_seamless_S.jpg")
#var texture = preload("res://textures/TexturesCom_Camouflage0002_seamless_S.jpg")
var Config = preload("res://CONFIG.tres")
var PriorityQueue = preload("res://PriorityQueue.gd")

export var SIZE = 21 # should be odd for a nice sized hexagon

onready var grid = []
onready var tallest = 0

const MAX_HEIGHT = 30.0
const CAPPED_HEIGHT = 30.0
const WATER_HEIGHT = 0
const USE_HEIGHT_MAP = true

# Both can be false but only one can be true
const ISLAND_MODE = true
const CRATER_MODE = false
const CANYON_MODE = false
const FLAT_MODE = false
const TWEAK_FACTOR = 0.5 # should be between 0 and 1

var noise = OpenSimplexNoise.new()
var secondary_noise = OpenSimplexNoise.new()

var NOISE_CONFIG = {
	"period_1": 12,
	"persistence": 0.5,
	"period_2": 24
}

const DIRECTIONS = [
	Vector2(0, 1),
	Vector2(1, 0),
	Vector2(1, -1),
	Vector2(0, -1),
	Vector2(-1, 0),
	Vector2(-1, 1)
]

func _ready():
	randomize()
	var curr_seed = 5228
	print("SEED: ", curr_seed)
	noise.seed = curr_seed
	#noise.octaves = 1
	noise.period = NOISE_CONFIG.period_1
	noise.persistence = NOISE_CONFIG.persistence
	var seed_2 = 5228
	secondary_noise.seed = seed_2
	secondary_noise.period = NOISE_CONFIG.period_2
	generate_tiles()
	var center_tile = grid[SIZE/2][SIZE/2]
	$OuterGimbal.RADIUS = Config.TILE_HEIGHT * SIZE + 600
	$OuterGimbal.CENTER = Vector2(center_tile.translation.x, center_tile.translation.y)
	$OuterGimbal.translation.z += tallest * 64


func is_inbounds(x: int, y: int) -> bool:
	if (x + y <= SIZE / 2 - 1) or (x + y >= SIZE + SIZE / 2) or x < 0 or y < 0 or x >= SIZE or y >= SIZE:
		return false
	else:
		return true

func get_height(x, y):
	if not is_inbounds(x, y):
		return NAN
	return grid[x][y].scale.z


func get_immediate_neighbors(x: int, y: int) -> Array:
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


func get_neighbors_and_distances(x: int, y: int, n: int) -> Array:
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


func find_line(x1: int, y1: int, x2: int, y2: int, max_length = INF) -> Array:
	if !is_inbounds(x1, y1) or !is_inbounds(x2, y2) or (x1 == x2 and y1 == y2):
		return []
	var dist = Hex.axial_distance(Vector2(x1, y1), Vector2(x2, y2))
	var dx = (x2 - x1) / dist
	var dy = (y2 - y1) / dist
	if max_length < dist:
		dist = max_length
	var path = []
	for i in range(dist + 1):
		#var vec = Vector2(x1 + dx * i, y1 + dy * i).round()
		var rounded = Hex.axial_round(x1 + dx * i, y1 + dy * i)
		var vec = Vector2(rounded.x, rounded.y)
		if not path.has(vec):
			path.append(vec)
	path.pop_front()
	return path


func line_of_sight(x1, y1, x2, y2):
	if !is_inbounds(x1, y1) or !is_inbounds(x2, y2) or (x1 == x2 and y1 == y2):
		return []
	var dist = Hex.axial_distance(Vector2(x1, y1), Vector2(x2, y2))
	var dx = (x2 - x1) / dist
	var dy = (y2 - y1) / dist
	var path = []
	var shaded = []
	var start_height = get_height(x1, y1)
	var prev_height = start_height
	var min_height = 0
	var absolute_min = 0
	var has_increased_height = false
	for i in range(dist + 1):
		var rounded = Hex.axial_round(x1 + dx * i, y1 + dy * i)
		var vec = Vector2(rounded.x, rounded.y)
		var height = get_height(vec.x, vec.y)
		if height < absolute_min:
			continue
		
		if height < min_height:
			if has_increased_height: # can't see over crest of hill
				shaded.append(vec)
				absolute_min = height
				continue
			if height <= start_height and not path.has(vec): # normally a tile would get full cover but if
				shaded.append(vec)                       # they're on the same level then they should be in half cover 
				#print(".")
			min_height -= 1
			continue
		
		if not path.has(vec):
			path.append(vec)
		
		if height > prev_height + 1 and height > start_height: # if current tile is > 1 tile taller than previous tile
			min_height = height + 1
			has_increased_height = true
			continue                                              # then the line of sight is broken
		
		if height > prev_height:
			min_height = height
		
		if height > start_height + 1:
			has_increased_height = true
		
		prev_height = height
		
	path.pop_front()
	return { "lit": path, "shaded": shaded }


func find_tiles_in_sight(x, y):
	if not is_inbounds(x, y):
		return []
	var tiles = []
	var shaded = []
	for i in range(SIZE):
		for j in range(SIZE):
			if (i == x and j == y) or tiles.has(Vector2(i, j)) or not is_inbounds(i, j):
				continue
			var line = line_of_sight(x, y, i, j)
			for t in line.lit:
				if not tiles.has(t):
					tiles.append(t)
			for t in line.shaded:
				if not shaded.has(t) and not tiles.has(t):
					shaded.append(t)
	
	var filtered = []
	for t in shaded:
		if not tiles.has(t):
			filtered.append(t)
	return { "lit": tiles, "shaded": filtered }


func find_cone(x1: int, y1: int, x2: int, y2: int, length: int, ignore_walls = false) -> Array:
	if x1 == x2 and y1 == y2:
		return []
	var cone = []
	var helper_line = find_line(x1, y1, x2, y2, 2)
	var root = helper_line[0]
	var direction = root - Vector2(x1, y1)
	var secondary_direction
	var s_height = grid[x1][y1].scale.z
	
	if helper_line.size() >= 2:
		var helper_node = helper_line[1]
		secondary_direction = helper_node - root
	else:
		secondary_direction = direction
	
	var dI = DIRECTIONS.find(direction)
	if secondary_direction == direction:
		if dI == 0:
			secondary_direction = DIRECTIONS[5]
		else:
			secondary_direction = DIRECTIONS[dI - 1]
	
	var obstacles = []
	var min_heights = {}
	for i in range(length):
		if not is_inbounds(root.x, root.y):
			break
		for j in range(i + 2):
			var to_add = root + secondary_direction * j
			if obstacles.has(j):
				continue
			if not is_inbounds(to_add.x, to_add.y):
				break
			var e_height = grid[to_add.x][to_add.y].scale.z
			if min_heights.has(j) and e_height <= min_heights[j]:
				continue
			cone.append(to_add)
			if e_height > s_height:
				var min_height = e_height
				if not min_heights.has(j) or min_heights[j] > min_height:
					min_heights[j] = min_height
				if j == i + 1:
					var et = length - j
					for o in range(j + 1, j + et):
						if not min_heights.has(o) or min_heights[o] > min_height:
							min_heights[o] = min_height
						
			#if e_height - s_height >= 2 and not ignore_walls:
			#	obstacles.append(j)
			#	if j == i + 1:
			#		var et = length - j
			#		for o in range(j + 1, j + et):
			#			obstacles.append(o)
		root = root + direction
	for i in range(length, length * 2):
		if not is_inbounds(root.x, root.y):
			break
		for j in range(0, length + (length - i)):
			var to_add = root + secondary_direction * j
			if obstacles.has(j):
				continue
			if not is_inbounds(to_add.x, to_add.y):
				break
			var e_height = grid[to_add.x][to_add.y].scale.z
			if min_heights.has(j) and e_height <= min_heights[j]:
				continue
			cone.append(to_add)
			if e_height > s_height:
				var min_height = e_height
				if not min_heights.has(j) or min_heights[j] > min_height:
					min_heights[j] = min_height
				if j == i + 1:
					var et = length - j
					for o in range(j + 1, j + et):
						if not min_heights.has(o) or min_heights[o] > min_height:
							min_heights[o] = min_height
			#if e_height - s_height >= 2 and not ignore_walls:
			#	obstacles.append(j)
		root = root + direction
	# 12 cones possible, some slight overlap
	return cone


func find_cones_around_point(x: int, y: int, distance: int) -> Array:
	if not is_inbounds(x, y):
		return []
	var tiles = []
	var points = [
		Vector2(0, 1),
		Vector2(1, 0),
		Vector2(1, -1),
		Vector2(0, -1),
		Vector2(-1, 0),
		Vector2(-1, 1),
		Vector2(1, 2),
		Vector2(3, -1),
		Vector2(2, -3),
		Vector2(-1, -2),
		Vector2(-2, 1),
		Vector2(-1, 2)
	]
	for p in points:
		if not is_inbounds(x + p.x, y + p.y):
			continue
		var cone = find_cone(x, y, x + p.x, y + p.y, distance)
		for c in cone:
			if not tiles.has(c):
				tiles.append(c)
	return tiles


func get_movement_cost(start: Vector2, end: Vector2) -> int:
	var s_height = grid[start.x][start.y].scale.z
	var e_height = grid[end.x][end.y].scale.z
	var diff = abs(s_height - e_height)
	var water_cost = 10 if e_height == WATER_HEIGHT else 0
	return water_cost + 10 + diff * 10
	
func reverse_array(arr: Array) -> Array:
	var reversed = []
	for i in range(arr.size() - 1, 0, -1):
		reversed.append(arr[i])
	return reversed

func find_path(x1, y1, x2, y2, jump_height = 1):
	var queue = PriorityQueue.new()
	var start = Vector2(x1, y1)
	var endgoal = Vector2(x2, y2)
	queue.append(start, 0)
	var origin = {}
	var cumulative_cost = {}
	origin[start] = null
	cumulative_cost[start] = 0
	
	while not queue.is_empty():
		var current: Vector2 = queue.pop()
		if current == endgoal:
			break
		
		for n in get_immediate_neighbors(int(current.x), int(current.y)):
			var s_height = grid[current.x][current.y].scale.z
			var e_height = grid[n.x][n.y].scale.z
			var diff = abs(s_height - e_height)
			if diff > jump_height:
				continue
			var new_cost = cumulative_cost[current] + get_movement_cost(current, n)
			if not cumulative_cost.has(n) or new_cost < cumulative_cost[n]:
				cumulative_cost[n] = new_cost
				var priority = new_cost + Hex.axial_distance(endgoal, n)
				queue.append(n, priority)
				origin[n] = current
	
	var current = endgoal
	var path = []
	while current != start:
		path.append(current)
		if not origin.has(current):
			path = []
			print("NO PATH!")
			break
		current = origin[current]
	return reverse_array(path)


func _on_mouse_enter(mi: Hex):
	#print("ENTER")
	mi.color = Color(0.7, 0, 0.3, 1)
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
	#var cone = find_cones_around_point(mi.grid_coords.x, mi.grid_coords.y, SIZE/4)
	var cone = find_tiles_in_sight(mi.grid_coords.x, mi.grid_coords.y)
	for c in cone.lit:
		var h = c.x
		var k = c.y
		var n = grid[h][k]
		n.viewable = true
	for c in cone.shaded:
		var h = c.x
		var k = c.y
		var n = grid[h][k]
		n.shaded = true
		n.viewable = true

func _on_mouse_exit(mi: Hex):
	#print("EXIT")
	reset_color(mi)
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
	#var cone = find_cones_around_point(mi.grid_coords.x, mi.grid_coords.y, SIZE/4)
	var cone = find_tiles_in_sight(mi.grid_coords.x, mi.grid_coords.y)
	for c in cone.lit:
		var h = c.x
		var k = c.y
		var n = grid[h][k]
		n.viewable = false
	for c in cone.shaded:
		var h = c.x
		var k = c.y
		var n = grid[h][k]
		n.shaded = false
		n.viewable = false
	
func reset_color(mi: Hex):
	mi.color = mi.base_color
	
func firework(x, y):
	for n in get_neighbors_and_distances(x, y, 4):
		var p = n.x
		var q = n.y
		var te = grid[p][q]
		te.color = Color(te.color.b * 1/float(n.distance), 0, te.color.r * 1/float(n.distance), 1)
		var _err = get_tree().create_timer(0.2 * n.distance).connect("timeout", self, "reset_color", [te])


func _on_input(_cam, event, _pos, _norm, _shape_idx, x, y):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == false:
			#print(grid[x][y].scale.z)
			#var cone = find_cone(SIZE/2, SIZE/2, x, y, 5)
			var cone = find_cones_around_point(x, y, SIZE)
			var i = -1
			for c in cone:
				i += 1
				var h = c.x
				var k = c.y
				var n = grid[h][k]
				#n.viewable = true
				n.color = Color(0, n.color.g + 0.0125 * i, n.color.b + 0.0125 * i, 0.2)
				#var _err = get_tree().create_timer(1).connect("timeout", self, "reset_color", [n])
			var path = find_path(SIZE/2, SIZE/2, x, y)
			if path.size() == 0:
				return
			#var di = 1.0 / path.size()
			#var i = 0
			#for m in path:
			#	i += 1
			#	var h = m.x
			#	var k = m.y
			#	var neighbor = grid[h][k]
			#	neighbor.color = Color(0, 0, min(di * i, 0.1), 0.2)
			#	var _err = get_tree().create_timer(0.08 * i).connect("timeout", self, "reset_color", [neighbor])
				#if h == x and k == y:
					#neighbor.scale.z += 1
					#var _err2 = get_tree().create_timer(0.08 * i).connect("timeout", self, "firework", [h, k])
		if event.button_index == 2 and event.pressed == false:
			var path = find_path(SIZE/2, SIZE/2, x, y, 2)
			if path.size() == 0:
				return
			var di = 1.0 / path.size()
			var i = 0
			for m in path:
				i += 1
				var h = m.x
				var k = m.y
				var neighbor = grid[h][k]
				neighbor.color = Color(min(di * i, 0.1), 0, 0, 0.2)


func connect_hex_signals(mi: Hex):
	var body: StaticBody = mi.get_child(0)
	var _err1 = body.connect("mouse_entered", self, "_on_mouse_enter", [mi])
	var _err2 = body.connect("mouse_exited", self, "_on_mouse_exit", [mi])
	var _err3 = body.connect("input_event", self, "_on_input", [mi.grid_coords.x, mi.grid_coords.y])


func tweak(value, adjusted_value, tweak_factor):
	var diff = abs(value - adjusted_value)
	return round(value + diff * tweak_factor) if value < adjusted_value else round(value - diff * tweak_factor)


func generate_tiles():
	randomize()
	for x in range(SIZE):
		grid.append([])
		grid[x].resize(SIZE)
		for y in range(SIZE):
			if not is_inbounds(x, y):
				continue
				#this bit removes the corners of the rhombus, turning it into a hexagon
			
			var mi: Hex = hex.instance()
			var material = SpatialMaterial.new()
			material.roughness = 0.3
			material.roughness_texture = rough_texture
			material.albedo_texture = texture
			mi.material_override = material
			
			var color = Color(x * 5 / 255.0, abs(y-x) * 3 / 255.0, y * 5 / 255.0, 1)
			
			var noise_x = (secondary_noise.get_noise_2d(x, y) + 1) / 2.0 * MAX_HEIGHT
			var noise_y = (secondary_noise.get_noise_2d(y, x) + 1) / 2.0 * MAX_HEIGHT
			var height = abs(ceil(noise.get_noise_2d(noise_x, noise_y) * MAX_HEIGHT)) + 1
			
			# MODE ADJUSTMENTS
			var size = SIZE / 2
			var dist_to_center = Hex.axial_distance(Vector2(x, y), Vector2(size, size))
			var dx = abs(x - size)
			var adjusted_height
			adjusted_height = max(ceil(((size) - dist_to_center) * height / size), 1) if ISLAND_MODE else height
			adjusted_height = max(ceil(dist_to_center / size * height), 1) if CRATER_MODE else adjusted_height
			adjusted_height = max(ceil(height * 1.5 * (dx / MAX_HEIGHT)), 1) if CANYON_MODE else adjusted_height
			height = tweak(height, adjusted_height, TWEAK_FACTOR)
			height = 3 if FLAT_MODE else height
			height = min(height, CAPPED_HEIGHT)
			
			if height > tallest:
				tallest = height # for camera settings
			
			# height mapping color
			if USE_HEIGHT_MAP:
				color = Color((CAPPED_HEIGHT - height) / 255.0 + height * (2 / CAPPED_HEIGHT), height * (1 / CAPPED_HEIGHT) * 0.6, 0, 1) 
			

			if height <= WATER_HEIGHT:
				color = Color(0, 0.5, 0.5, 0.2)
				mi.material_override.flags_transparent = true
				height = WATER_HEIGHT
			
			if x == size and y == size: # center tile
				#color = Color(1, 1, 1)
				pass
			
			mi.color = color
			mi.base_color = color
			mi.scale.z = height
			mi.translate(Vector3(x * Config.TILE_WIDTH, y * Config.TILE_HEIGHT * 2 + x * Config.TILE_HEIGHT, 0))
			mi.rotate_z(randi() % 5 * (2 * PI / 6))
			mi.grid_coords = Vector2(x, y)
			if not Engine.editor_hint:
				connect_hex_signals(mi)
			grid[x][y] = mi
			call_deferred("add_child", mi)



