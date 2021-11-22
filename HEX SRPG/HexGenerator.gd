extends Spatial

export var HEIGHT = 1

func _ready():
	var height = HEIGHT * 200
	var a = Vector3(128, 221.7, height)
	var b = Vector3(256, 0, height)
	var c = Vector3(128, -221.7, height)
	var d = Vector3(-128, -221.7, height)
	var e = Vector3(-256, 0, height)
	var f = Vector3(-128, 221.7, height)
	var g = Vector3(128, 221.7, 0)
	var h = Vector3(256, 0, 0)
	var i = Vector3(128, -221.7, 0)
	var j = Vector3(-128, -221.7, 0)
	var k = Vector3(-256, 0, 0)
	var l = Vector3(-128, 221.7, 0)
	
	var triangles := [
		# top face
		a,b,c,
		a,c,f,
		f,c,d,
		f,d,e,
		# south
		d,c,i,
		d,i,j,
		# sw
		e,d,j,
		e,j,k, 
		# nw
		f,e,k, 
		f,k,l,
		# n
		a,f,l, 
		a,l,g,
		# ne
		b,a,g, 
		b,g,h, 
		# se
		c,b,h, 
		c,h,i
	]
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in triangles:
		surface_tool.add_vertex(v)
	surface_tool.index()
	surface_tool.generate_normals()
	var array_mesh = surface_tool.commit()
	var err = ResourceSaver.save("meshes/hex_mesh_" + str(HEIGHT) + ".tres", array_mesh)
	if err:
		print(err)

	
