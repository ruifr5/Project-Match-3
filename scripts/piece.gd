extends Node2D

export var color: String;

var move_tween: Tween
var movement_start_position


# Called when the node enters the scene tree for the first time.
func _ready():
	move_tween = $move_tween


func move(difference):
	if !movement_start_position:
		movement_start_position = position
	
	move_tween.interpolate_property(self, "position", position, movement_start_position + difference, .1, Tween.TRANS_SINE, Tween.EASE_OUT)
	move_tween.start()


func movement_stop():
	move_tween.stop_all()
	movement_start_position = null


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
