# 测试 Step 2 - 战斗循环核心逻辑

extends Node

func _ready():
	test_combat_loop()

func test_combat_loop():
	print("=== 开始测试 Step 2: 战斗循环 ===\n")

	# 初始化游戏状态
	GameManager.character_class = "barbarian"
	GameManager.level = 1
	GameManager.experience = 0
	GameManager.experience_to_next = 100
	GameManager.gold = 0
	GameManager.current_stage = 1
	GameManager.difficulty = "普通"

	# 初始化角色属性
	var barbarian_data = CharacterPresets.find_character_class("barbarian")
	GameManager.strength = barbarian_data.base_strength
	GameManager.dexterity = barbarian_data.base_dexterity
	GameManager.vitality = barbarian_data.base_vitality
	GameManager.energy = barbarian_data.base_energy

	GameManager._recalculate_stats()

	print("初始状态：")
	print("  - 等级: %d" % GameManager.level)
	print("  - 生命: %.0f/%.0f" % [GameManager.current_health, GameManager.max_health])
	print("  - DPS: %.0f" % GameManager.dps)
	print("  - 金币: %.0f\n" % GameManager.gold)

	# 模拟 100 个战斗 tick
	print("模拟 100 个战斗 tick...\n")
	for i in range(100):
		GameManager._process_combat_tick()
		GameManager._update_stats()

		if i % 20 == 0:
			print("[Tick %d]" % (i + 1))
			print("  - 击杀: %d" % GameManager.total_kills)
			print("  - 等级: %d" % GameManager.level)
			print("  - 金币: %.0f" % GameManager.gold)
			print("  - 经验: %.0f/%.0f" % [GameManager.experience, GameManager.experience_to_next])
			print("  - 阶段: %d" % GameManager.current_stage)
			print("  - 背包: %d 件物品" % GameManager.inventory.size())
			print("")

	print("=== 战斗循环测试完成 ===")
	print("\n最终统计:")
	print("  - 总击杀: %d" % GameManager.total_kills)
	print("  - 最终等级: %d" % GameManager.level)
	print("  - 最终金币: %.0f" % GameManager.gold)
	print("  - 背包物品: %d 件" % GameManager.inventory.size())

	get_tree().quit()
