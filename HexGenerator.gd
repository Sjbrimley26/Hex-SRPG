extends Spatial

export var HEIGHT = 2 

var Config = load("res://CONFIG.tres")

func generate_points(radius): #and set TILE_WIDTH and TILE_HEIGHT
	var height = HEIGHT * radius
	var top = []
	var bottom = []
	var minX = INF
	var maxX = -INF
	var maxY = -INF
	for i in range(0, -2 * PI, -2 * PI / 6):
		var pos = Utility.get_point_on_circle(i, radius)
		if pos.x < minX:
			minX = pos.x
		if pos.x > maxX:
			maxX = pos.x
		if pos.y > maxY:
			maxY = pos.y
		top.append(Vector3(pos.x, pos.y, 0))
		bottom.append(Vector3(pos.x, pos.y, height))
	bottom.append_array(top)
	Config.TILE_WIDTH = maxX - minX
	Config.TILE_HEIGHT = maxY
	var err = ResourceSaver.save("res://Config.tres", Config)
	if err:
		print(err)
	print(bottom)
	return bottom

func _ready():
	var v = generate_points(256)
	#var height = HEIGHT * 200
	#var a = Vector3(128, 221.7, height)
	#var b = Vector3(256, 0, height)
	#var c = Vector3(128, -221.7, height)
	#var d = Vector3(-128, -221.7, height)
	#var e = Vector3(-256, 0, height)
	#var f = Vector3(-128, 221.7, height)
	#var g = Vector3(128, 221.7, 0)
	#var g2 = Vector3(128, 221.7, 0)
	#var h = Vector3(256, 0, 0)
	#var h2 = Vector3(256, 0, 0)
	#var i = Vector3(128, -221.7, 0)
	#var i2 = Vector3(128, -221.7, 0)
	#var j = Vector3(-128, -221.7, 0)
	#var j2 = Vector3(-128, -221.7, 0)
	#var k = Vector3(-256, 0, 0)
	#var k2 = Vector3(-256, 0, 0)
	#var l = Vector3(-128, 221.7, 0)
	#var l2 = Vector3(-128, 221.7, 0)
	var a = v[0]
	var b = v[1]
	var c = v[2]
	var d = v[3]
	var e = v[4]
	var f = v[5]
	var g = v[6]
	var g2 = Vector3(g.x, g.y, g.z)
	var h = v[7]
	var h2 = Vector3(h.x, h.y, h.z)
	var i = v[8]
	var i2 = Vector3(i.x, i.y, i.z)
	var j = v[9]
	var j2 = Vector3(j.x, j.y, j.z)
	var k = v[10]
	var k2 = Vector3(k.x, k.y, k.z)
	var l = v[11]
	var l2 = Vector3(l.x, l.y, l.z)
	
	var triangles := [
		# top face
		a,b,c,
		c,f,a,
		f,c,d,
		f,d,e,
		# south
		d,c,i,
		d,i,j,
		# sw
		e,d,j2,
		e,j2,k, 
		# nw
		f,e,k2, 
		f,k2,l,
		# n
		a,f,l2, 
		a,l2,g,
		# ne
		b,a,g2, 
		b,g2,h, 
		# se
		c,b,h2,
		h2,i2,c
	]
	
	var uvs = {
		a: Vector2(0.6491137, 0.7495251),
		b: Vector2(0.7982265, 0.4912618),
		c: Vector2(0.6491137, 0.2329888),
		d: Vector2(0.3507074, 0.2329888),
		e: Vector2(0.2017751, 0.4912618),
		f: Vector2(0.3507074, 0.7495251),
		g: Vector2(0.6491137, 0.982514),
		g2: Vector2(0.8508971, 0.8660195),
		h: Vector2(1, 0.6077514),
		h2: Vector2(1, 0.3747625),
		i: Vector2(0.8508971, 0.1164944),
		i2: Vector2(0.6489331, 0),
		j: Vector2(0.3507074, 0), 
		j2: Vector2(0.1491128, 0.1164944),
		k: Vector2(0, 0.3747625), 
		k2: Vector2(0, 0.6077514),
		l: Vector2(0.1491128, 0.8660195), 
		l2: Vector2(0.3507074, 0.982514)
	}
	

	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in triangles:
		surface_tool.add_uv(uvs[t])
		surface_tool.add_vertex(t)
	surface_tool.index()
	surface_tool.generate_normals()
	var array_mesh = surface_tool.commit()
	var err = ResourceSaver.save("meshes/hex_mesh_" + str(HEIGHT) + ".tres", array_mesh)
	if err:
		print(err)

	
