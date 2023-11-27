extends Label

@export var hour_start : int
@export var minute_start : int

const MINUTE_MAX = 60
const HOUR_MAX = 24

@onready var timer = $GameTimer
@onready var minutes = max(0, MINUTE_MAX - minute_start)
@onready var hours = max(0, HOUR_MAX - hour_start)

func _ready():
	update_clock()
	timer.start(2)
	

func reset_timer():
	minutes = MINUTE_MAX
	hours = HOUR_MAX
	

func update_clock():
	var hour = HOUR_MAX - hours
	var minute = MINUTE_MAX - minutes
	hour = str(hour) if hour >= 10 else ('0' + str(hour))
	minute = str(minute) if minute >= 10 else ('0' + str(minute))
	text = hour + ':' + minute
	

func _on_game_timer_timeout():
	minutes -= 1
	if minutes == 0:
		minutes = 60
		hours -= 1
		if hours == 0:
			reset_timer()
	update_clock()
	GlobalNode.fuzzy_factors[GlobalNode.FuzzyFactors.GAMETIME] = Vector2i(HOUR_MAX - hours, MINUTE_MAX - minutes)
	timer.start(2)
	
