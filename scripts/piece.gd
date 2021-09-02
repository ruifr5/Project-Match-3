extends Node2D

export var color: String;

var move_tween: Tween
var movement_start_position
var old_movement_distance
var matched = false


# Called when the node enters the scene tree for the first time.
func _ready():
	move_tween = $move_tween


func move(difference):
	if !movement_start_position:
		movement_start_position = position
	if !old_movement_distance:
		old_movement_distance = difference
	
	move_tween.interpolate_property(self, "position", position, movement_start_position + difference, .1, Tween.TRANS_EXPO, Tween.EASE_OUT)
	move_tween.start()
	
	reset_mirrors_if_passed_origin(difference)


func reset_mirrors_if_passed_origin(new_movement_distance):
	if old_movement_distance.y < 0 && new_movement_distance.y > 0 || old_movement_distance.y > 0 && new_movement_distance.y < 0:
		remove_mirrors()
	old_movement_distance = new_movement_distance


func stop_movement():
	move_tween.stop_all()
	movement_start_position = null
	remove_mirrors()


func remove_mirrors():
	$SpriteScreenWrap.removeMirrors()



func mark_matched():
	matched = true
	$SpriteScreenWrap.modulate = Color(1, 1, 1, 0.3)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
