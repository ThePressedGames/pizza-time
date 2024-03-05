extends CharacterBody3D
class_name NPC

@export var NPC_name: String
@export var main_dialogue_index: String = "01"
var main_dialogue_done = false
@export var random_dialogues_indexes: Array[String]
var rng = RandomNumberGenerator.new()

func start_dialogue():
	if !main_dialogue_done:
		Dialogic.start(NPC_name + "_" + main_dialogue_index)
		main_dialogue_done = true
	else:
		var my_random_number = rng.randi_range(0, random_dialogues_indexes.size() - 1)
		var random_dialogue_index = random_dialogues_indexes[my_random_number]
		Dialogic.start(NPC_name + "_" + random_dialogue_index)
