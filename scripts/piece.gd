extends Node2D
class_name Piece

export var color: String;

var movement_start_position
var old_movement_distance
var matched = false
var highlighted = false


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass

func move_as_group(difference, duration = .5, trans_type = Tween.TRANS_EXPO, ease_type = Tween.EASE_OUT):
	if !movement_start_position:
		movement_start_position = position
		
	move(movement_start_position + difference, duration, trans_type, ease_type)
	reset_mirrors_if_passed_origin(difference)


func move(target, duration = .5, trans_type = Tween.TRANS_EXPO, ease_type = Tween.EASE_OUT):
	$move_tween.interpolate_property(self, "position", position, target, duration, trans_type, ease_type)
	$move_tween.start()
	pass

func reset_mirrors_if_passed_origin(new_movement_distance):
	if !old_movement_distance:
		old_movement_distance = new_movement_distance
	if old_movement_distance.y < 0 && new_movement_distance.y > 0 || old_movement_distance.y > 0 && new_movement_distance.y < 0:
		remove_mirrors()
	old_movement_distance = new_movement_distance


func stop_movement():
	$move_tween.stop_all()
	remove_mirrors()
	movement_start_position = null

func remove_mirrors():
	$SpriteScreenWrap.removeMirrors()


func mark_matched():
	matched = true
	$SpriteScreenWrap.modulate = Color(1, 1, 1, 0.3)


func check_if_highlighted():
	if matched:
		return
	elif highlighted:
		$SpriteScreenWrap.modulate = Color(2, 2, 2, 1)
	else:
		$SpriteScreenWrap.modulate = Color(1, 1, 1, 1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	check_if_highlighted()
