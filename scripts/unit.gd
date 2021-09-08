extends KinematicBody2D
class_name Unit

export (String) var color
export (Array, String) var strong_vs
export (Array, String) var weak_vs

var allegiance


# return winner, if tied returns null
func fight(enemy: Unit) -> Unit:
	if enemy.color in strong_vs:
		attack_animation(enemy.position)
		enemy.die()
		return self
	if enemy.color in weak_vs:
		enemy.attack_animation(position)
		die()
		return enemy
	die()
	enemy.die()
	return null


func die():
#	die animation
	queue_free()
	pass


func attack_animation(pos):
#	animate and move to pos
	pass
