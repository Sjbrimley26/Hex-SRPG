extends Node


class_name Memoizer

var function: FuncRef
var data = {}

func init(fn: FuncRef):
	function = fn

func run(args: Array):
	if data.has(args):
		return data[args]
	var res = function.call_funcv(args)
	data[args] = res
	return res
