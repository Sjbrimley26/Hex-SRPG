extends Node

class_name PriorityQueue

var priorities

func _init():
	priorities = {}


func append(x, priority: int):
	if priorities.has(priority):
		priorities[priority].append(x)
	else:
		priorities[priority] = [x]


func pop():
	var h = INF
	for p in priorities.keys():
		if p < h:
			h = p
	var to_return = priorities[h].pop_front()
	if priorities[h].size() == 0:
		priorities.erase(h)
	return to_return


func is_empty() -> bool:
	return priorities.size() == 0
