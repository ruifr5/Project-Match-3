extends Node2D


export (Color) var color


# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		child.color = color


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
