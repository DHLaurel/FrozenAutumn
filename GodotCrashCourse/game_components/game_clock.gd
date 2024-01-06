extends Label

@export var hour_start : int
@export var minute_start : int

const MINUTE_MAX = 60
const HOUR_MAX = 24

@onready var timer = $GameTimer
@onready var _minutes = max(0, MINUTE_MAX - minute_start)
@onready var _hours = max(0, HOUR_MAX - hour_start)

@onready var current_time : Vector2i = Vector2i(HOUR_MAX - _hours, MINUTE_MAX - _minutes)

func _ready():
	update_clock()
	timer.start(GlobalNode.tick_speed)


func get_time():
	return current_time


func set_time(new_time : Vector2i):  # With new_time of the form (H, M)
	_hours = max(0, HOUR_MAX - new_time.x)
	_minutes = max(0, MINUTE_MAX - new_time.y)


func reset_timer():
	_minutes = MINUTE_MAX
	_hours = HOUR_MAX


func update_clock():
	var hour = current_time.x
	var minute = current_time.y
	hour = str(hour) if hour >= 10 else ('0' + str(hour))
	minute = str(minute) if minute >= 10 else ('0' + str(minute))
	text = hour + ':' + minute


func _on_game_timer_timeout():
	_minutes -= 1
	if _minutes == 0:
		_minutes = 60
		_hours -= 1
		if _hours == 0:
			reset_timer()
	current_time = Vector2i(HOUR_MAX - _hours, MINUTE_MAX - _minutes)
	update_clock()
	GlobalNode.fuzzy_factors[GlobalNode.FuzzyFactors.GAMETIME] = current_time
	timer.start(GlobalNode.tick_speed)

