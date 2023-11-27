extends Node

var phrases : Array[Dictionary]
var fuzzy_phrases : Array[Dictionary]


func init(agent_name):
	get_phrases_from_db(agent_name)  # Call db once per object to avoid unnecessary r/w


func get_phrases_from_db(agent_name):
	var agent_id = GlobalNode.readFromDB('agents', 'id', ("name = '" + agent_name + "'"))[0]['id']
	var results = GlobalNode.readFromDB('catchphrases', '*', ('agent_id = ' + str(agent_id)))
	# TODO: Sort phrases by frequency for quicker calls down the line
	# FOR NOW: Assume phrases have been inserted in the correct frequency order in the db
	for result in results:
		pass
	phrases = results
	
	var gametime_name = GlobalNode.FuzzyFactors.keys()[GlobalNode.FuzzyFactors.GAMETIME]
	var fuzzy_factor_id = GlobalNode.readFromDB('fuzzy_factors', 'id', ("name = '" + gametime_name + "'"))[0]['id']
	results = GlobalNode.readFromDB('fuzzy_phrases', '*', ('agent_id = ' + str(agent_id) + ' and fuzzy_factor_id = ' + str(fuzzy_factor_id)))
	fuzzy_phrases = results


func get_catchphrase():
	var choice_f = randf()
	for phrase in phrases:  # Assume 1.0 is always inserted in db as base case
		if phrase["frequency"] >= choice_f:
			return phrase["phrase"]


func get_fuzzy_catchphrase():
	var gametime = GlobalNode.fuzzy_factors[GlobalNode.FuzzyFactors.GAMETIME]
	gametime = (gametime.x * 60) + gametime.y  # Converts hour:minute to minutes since 00:00
	gametime = gametime + (randf_range(-1, 1) * sqrt(gametime))
	gametime = minf(gametime, GlobalNode.TimeConsts.MAX_TIME)
	gametime = maxf(gametime, GlobalNode.TimeConsts.MIN_TIME)
	
	var fuzzy_weighted_phrases = {}
	for phrase in fuzzy_phrases:
		if gametime >= phrase["fuzzy_value_min"] and gametime <= phrase["fuzzy_value_max"]:
			var midpoint = (phrase["fuzzy_value_min"] + phrase["fuzzy_value_max"]) / 2.0
			var dist = snapped((abs(midpoint - gametime) / (phrase["fuzzy_value_max"] - phrase["fuzzy_value_min"])), 0.01)
			if not fuzzy_weighted_phrases.has(dist):
				fuzzy_weighted_phrases[dist] = [phrase]
			else:
				fuzzy_weighted_phrases[dist].append(phrase)
	
	var rand_index = randf_range(-0.5, 1)
	var phrase_i = fuzzy_weighted_phrases.keys()[0]
	for fuzzy_weight in fuzzy_weighted_phrases.keys():
		if abs(fuzzy_weight - rand_index) < abs(phrase_i - rand_index):
			phrase_i = fuzzy_weight
	return fuzzy_weighted_phrases[phrase_i][randi() % fuzzy_weighted_phrases[phrase_i].size()]["phrase"]
