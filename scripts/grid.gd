extends Node2D

export (int) var width
export (int) var height
export (int) var x_start
export (int) var y_start
export (int) var offset

var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/orange_piece.tscn")
]

# piece array
var all_pieces

# touch variables
var touch_down = Vector2(0,0)
var touch_up = Vector2(0,0)
var controlling = false


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()


func make_2d_array():
	var array = []
	for x in width:
		array.append([])
		for y in height:
			array[x].append([null])
	return array
	
	
func spawn_pieces():
	for x in width:
		for y in height:
#			choose a random number and store it
			var rand = floor(rand_range(0, possible_pieces.size()))
#			instanciatee that piece from the array
			var piece = possible_pieces[rand].instance()
#			remove starting matches
			var new_piece_id = 0
			while match_at(x,y,piece.color) && new_piece_id < possible_pieces.size():
				piece = possible_pieces[new_piece_id].instance()
				new_piece_id += 1
#			set position and save piece to array
			piece.position = grid_to_pixel(Vector2(x,y))
			add_child(piece)
			all_pieces[x][y] = piece


func match_at(x, y, color):
	if x > 1:
		if all_pieces[x-1][y] && all_pieces[x-2][y]:
			if all_pieces[x-1][y].color == color && all_pieces[x-2][y].color == color:
				return true
	if y > 1:
		if all_pieces[x][y-1] && all_pieces[x][y-2]:
			if all_pieces[x][y-1].color == color && all_pieces[x][y-2].color == color:
				return true
	return false


func grid_to_pixel(position):
	var new_x = x_start + offset * position.x
	var new_y = y_start + -offset * position.y
	return Vector2(new_x, new_y)


func pixel_to_grid(position):
	var new_x = round((position.x - x_start) / offset)
	var new_y = round((position.y - y_start) / -offset)
	return Vector2(new_x, new_y)


func is_in_grid(x, y):
	if x >= 0 && x < width:
		if y >= 0 && y < height:
			return true;
	return false


func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		touch_down = get_global_mouse_position()
		var grid_position = pixel_to_grid(touch_down)
		if is_in_grid(grid_position.x, grid_position.y):
			controlling = true
			
	if Input.is_action_just_released("ui_touch"):
		touch_up = get_global_mouse_position()
		var grid_position = pixel_to_grid(touch_up)
		if is_in_grid(grid_position.x, grid_position.y) && controlling:
			var grid_touch_down = pixel_to_grid(touch_down)
			var difference = touch_difference(grid_touch_down, pixel_to_grid(touch_up))
			if difference:
				swap_pieces(grid_touch_down.x, grid_touch_down.y, difference)
		controlling = false


func swap_pieces(x, y, direction):
	var first_piece = all_pieces[x][y]
	var other_piece = all_pieces[x + direction.x][y + direction.y]
	all_pieces[x][y] = other_piece
	all_pieces[x + direction.x][y + direction.y] = first_piece
	first_piece.move(grid_to_pixel(Vector2(x + direction.x, y + direction.y)))
	other_piece.move(grid_to_pixel(Vector2(x, y)))

#
#func move_pieces(x, y, direction):
#	if abs(direction.x) > 0:
#		for column in all_pieces:
#			column[y].move()
#	elif abs(direction.y) > 0:
#		for piece in all_pieces[x]:
#			piece.move()


func touch_difference(touch_down, touch_up):
	var difference = touch_up - touch_down
	var direction
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			direction = Vector2(1, 0)
		if difference.x < 0:
			direction = Vector2(-1, 0)
	if abs(difference.x) < abs(difference.y):
		if difference.y > 0:
			direction = Vector2(0, 1)
		if difference.y < 0:
			direction = Vector2(0, -1)
	return direction

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	touch_input()

