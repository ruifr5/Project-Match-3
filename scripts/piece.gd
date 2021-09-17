class_name Piece
extends Node2D

export (String) var color;
export (Color) var default_modulate = Color(1, 1, 1, 1)
export (Color) var highlighted_modulate = Color(2, 2, 2, 1)
export (Color) var matched_modulate = Color(1, 1, 1, 0.3)

var movement_start_position
var old_movement_distance
var matched = false
var highlighted = false
var locked = false
var new_color

var inverted_texture_path


func _enter_tree():
	inverted_texture_path = "res://art/tiles/%s_tile_flip.png" % color


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	update_color()


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
	$SpriteScreenWrap.modulate = matched_modulate


func update_color():
	if matched:
		return
	elif highlighted:
		$SpriteScreenWrap.modulate = highlighted_modulate
	elif new_color != null:
		$SpriteScreenWrap.modulate = new_color
	else:
		$SpriteScreenWrap.modulate = default_modulate


func lock():
	locked = true


func unlock():
	locked = false


func set_sprite_color(c: Color):
	new_color = c


func reset_sprite_color():
	new_color = null


func set_sprite_texture(new_sprite_texture: Texture):
	$SpriteScreenWrap.set_texture(new_sprite_texture)


func get_sprite_texture():
	return $SpriteScreenWrap.texture


func flip_v_texture():
	if color:
		if ResourceLoader.exists(inverted_texture_path):
			set_sprite_texture(load(inverted_texture_path))
