extends MeshInstance3D

func init(pos1, pos2):
	pos1 = Vector3(0.365934, 2.733976, 0.511929)
	pos2 = Vector3(10.365934, 2.733976, 0.511929)
	var new_mesh = ImmediateMesh.new()
	mesh = new_mesh
	new_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	new_mesh.surface_add_vertex(pos1)
	new_mesh.surface_add_vertex(pos2)
	new_mesh.surface_end()
	
func _on_timer_timeout() -> void:
	print('freed')
	queue_free()
