# 测试 Step 1 - 数据资源加载

extends Node

func _ready():
	test_data_loading()

func test_data_loading():
	print("=== 开始测试 Step 1: 数据资源加载 ===\n")

	# 测试角色预设
	var barbarian = CharacterPresets.get_class("barbarian")
	assert(barbarian.class_id == "barbarian", "野蛮人数据加载失败")
	print("✓ 角色预设加载成功")
	print("  - 职业: %s" % barbarian.class_name)
	print("  - 初始属性: STR %d, DEX %d, VIT %d, ENE %d" % [
		barbarian.base_strength, barbarian.base_dexterity,
		barbarian.base_vitality, barbarian.base_energy
	])

	# 测试装备预设
	var sword = EquipmentPresets.get_base_item("sword")
	assert(sword.item_id == "sword", "装备数据加载失败")
	print("\n✓ 装备预设加载成功")
	print("  - 剑: 伤害 %d-%d" % [sword.base_min_damage, sword.base_max_damage])

	# 测试敌人预设
	var skeleton = EnemyPresets.get_enemy_template("skeleton")
	assert(skeleton.enemy_id == "skeleton", "敌人数据加载失败")
	print("\n✓ 敌人预设加载成功")
	print("  - 骷髅战士: HP %d, 伤害 %d, 防御 %d" % [
		skeleton.base_health, skeleton.base_damage, skeleton.base_defense
	])

	# 测试词缀预设
	var rarity_tiers = AffixPresets.get_all_rarity_tiers()
	assert(rarity_tiers.size() == 6, "稀有度层级数据错误")
	print("\n✓ 词缀预设加载成功")
	print("  - 稀有度层级: %d 个" % rarity_tiers.size())
	for tier in rarity_tiers:
		print("    - %s: 词缀数 %d-%d" % [
			tier.name, tier.min_affixes, tier.max_affixes
		])

	# 测试阶段预设
	var stage1 = StagePresets.get_stage(1)
	assert(stage1.stage_id == 1, "阶段数据加载失败")
	print("\n✓ 阶段预设加载成功")
	print("  - 第 1 阶段: %s (区域等级 %d)" % [stage1.stage_name, stage1.area_level])
	print("  - 敌人模板: %s" % ", ".join(stage1.enemy_templates))

	# 测试掉落系统
	print("\n✓ 测试物品掉落系统")
	var test_items = []
	for i in range(20):
		var item = LootManager.generate_item(1, 0.0)
		if not item.is_empty():
			test_items.append(item)

	print("  - 生成了 %d 件物品" % test_items.size())

	# 统计稀有度分布
	var rarity_count = {}
	for item in test_items:
		var rarity = item.get("rarity", "未知")
		rarity_count[rarity] = rarity_count.get(rarity, 0) + 1

	print("  - 稀有度分布:")
	for rarity in rarity_count:
		print("    - %s: %d 件" % [rarity, rarity_count[rarity]])

	print("\n=== Step 1 测试完成 ===\n")
	get_tree().quit()
