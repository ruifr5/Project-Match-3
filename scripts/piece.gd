extends Node2D

export var color: String;
var move_tween: Tween

var locked_x
var locked_y

# Called when the node enters the scene tree for the first time.
func _ready():
	move_tween = $move_tween

func move(target):
#	if (locked_x):
#		target.x = locked_x
#	elif (locked_y):
#		target.y = locked_y
#	else:
#
#		pass
#
	move_tween.interpolate_property(self, "position", position, target, .1, Tween.TRANS_SINE, Tween.EASE_OUT)
	move_tween.start()

#func release_lock():
#	locked_x = null
#	locked_y = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
