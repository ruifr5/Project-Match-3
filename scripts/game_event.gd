extends Node

class_name GameEvent

var type: int
var context: Array

enum Event { GRID_MOVE, UNIT_SPAWN, UNIT_GOAL, UNIT_FIGHT, POWER }


"""
events
	grid move /? pieces match
		start touch, end touch /? color, count
	spawn unit
		color, position, allegiance(redundante tendo posiçao calcula se allegiance)
	activate power
		color, start, end
	unit reach end
		position
	unit fight
		winner/loser
"""

