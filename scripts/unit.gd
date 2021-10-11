class_name Unit
extends KinematicBody2D

export (String) var color
export (Array, String) var strong_vs
export (Array, String) var weak_vs
export (float) var pixel_size = 64
export (float) var aggro_radius = (pixel_size + pixel_size * 0.7) * scale.y
export (float) var flee_speed_multiplier = 0.8
export (float) var chase_speed_multiplier = 1.5


var state
var allegiance: Vector2 # aka what direction am I walking in (up or down)
var enemies_near = []
var closest_enemy: Unit

enum State {MOVING, CHASING, FLEEING, FIGHTING, DYING}
enum Result {WIN, LOSE, TIE}


func _ready():
	$aggro_area/CollisionShape2D.shape.radius = aggro_radius
	play_walk_animation()


func _process(_delta):
	process_enemies()


func process_enemies():
	if enemies_near.size():
		enemies_near.sort_custom(self, "sort_closest")
		closest_enemy = get_closest_alive_enemy()
	else:
		closest_enemy = null


# if closest is a Result.TIE looks for a better outcome
func get_closest_alive_enemy():
	var prefered
	var closest
	for enemy in enemies_near:
		if enemy.state != State.DYING:
			if !closest:
				closest = enemy
			var fight_result = wins_vs(enemy)
			if fight_result == Result.TIE:
				continue
			if fight_result == Result.WIN:
				prefered = enemy
			break
	return prefered if prefered else closest


func play_walk_animation():
	if allegiance == Vector2.UP:
		$AnimationPlayer.play("walk_up")
	elif allegiance == Vector2.DOWN:
		$AnimationPlayer.play("walk_down")


func sort_closest(a, b):
#	return abs(a.position.x - self.position.x) < abs(b.position.x - self.position.x)
	return a.position.distance_to(self.position) < b.position.distance_to(self.position)


# return loser, if tied returns null
func fight(enemy: Unit) -> Unit:
	state = State.FIGHTING
	var fight_result = wins_vs(enemy)
	if fight_result == Result.WIN:
		enemy.die()
		return enemy
	if fight_result == Result.LOSE:
		die()
		return self
#	Result.TIE
	die()
	enemy.die()
	return null


# return loser, if tied returns null
func move_and_fight(dir: Vector2, speed: float):
	var base_speed = Vector2(speed, speed)
	if state == State.DYING:
		return
#	if there is an enemy and is in front of self
	if closest_enemy and is_facing_me(closest_enemy):
		var fight_result = wins_vs(closest_enemy)
		var new_dir = (closest_enemy.position - position).normalized()
#			when chasing
		if fight_result == Result.WIN or fight_result == Result.TIE:
			state = State.CHASING
			dir = new_dir
			base_speed.x *= chase_speed_multiplier
#			when fleeing
		elif fight_result == Result.LOSE:
			state = State.FLEEING
			dir.x = dir.x + new_dir.x * -1
			base_speed.x *= flee_speed_multiplier
#	no enemy
	else:
		state = State.MOVING
#	move and if colision happens fight
	var collision = move_and_collide(dir * base_speed)
	if collision && allegiance != collision.collider.allegiance && collision.collider.state != State.DYING:
#		who loses?
		return fight(collision.collider)


func die():
	state = State.DYING
	$CollisionShape2D.disabled = true
	pause_mode = PAUSE_MODE_PROCESS
	$AnimationPlayer.play("die")
	yield($AnimationPlayer, "animation_finished")
	queue_free()


func wins_vs(enemy) -> int:
	if enemy.color in strong_vs:
		return Result.WIN
	if enemy.color in weak_vs:
		return Result.LOSE
	return Result.TIE


# return true if enemy is facing self
func is_facing_me(enemy: Unit):
	var facing_angle_vs_enemy = position.direction_to(enemy.position).dot(allegiance)
	return facing_angle_vs_enemy > 0


# todo: possibly move facing detection from move_and_fight() to here instead
func _on_aggro_radius_body_entered(body):
	if body.allegiance != allegiance and body.state != State.DYING and not body in enemies_near:
		enemies_near.append(body)


func _on_aggro_radius_body_exited(body):
	if body in enemies_near:
		enemies_near.erase(body)
