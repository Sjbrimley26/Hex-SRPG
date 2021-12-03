extends Node

class_name Utility

static func get_point_on_circle(angle: float, radius: float, center = Vector2(0, 0)):
	return Vector2(radius * cos(angle) + center.x, radius * sin(angle) + center.y).round()
