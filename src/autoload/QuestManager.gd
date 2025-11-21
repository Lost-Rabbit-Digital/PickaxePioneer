extends Node

# QuestManager
# Manages active quests in mining levels

signal quest_started(quest_data: Dictionary)
signal quest_item_collected()
signal quest_completed(reward: int)

var active_quest: Dictionary = {}
var item_collected: bool = false
var quest_npc: Node2D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_quest(npc: Node2D, item_name: String, reward: int) -> void:
	active_quest = {
		"npc": npc,
		"item_name": item_name,
		"reward": reward,
		"completed": false
	}
	item_collected = false
	quest_npc = npc
	quest_started.emit(active_quest)
	print("Quest started: Find ", item_name)

func collect_item() -> void:
	if active_quest.is_empty():
		return
	
	item_collected = true
	quest_item_collected.emit()
	print("Quest item collected! Return to quest giver.")

func complete_quest() -> void:
	if active_quest.is_empty() or not item_collected:
		return
	
	var reward = active_quest.reward
	GameManager.add_currency(reward)
	quest_completed.emit(reward)
	print("Quest completed! Reward: ", reward, " scrap")
	
	# Clear quest
	active_quest = {}
	item_collected = false
	quest_npc = null

func clear_quest() -> void:
	active_quest = {}
	item_collected = false
	quest_npc = null
