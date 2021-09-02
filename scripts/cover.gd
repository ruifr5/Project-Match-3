extends Node2D


export (Color) var color


# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		child.color = color
