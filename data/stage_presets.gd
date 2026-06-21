# ============================================================
# StagePresets.gd — 阶段/关卡预设数据 (静态数据类)
# ============================================================
# 职责：
#   定义 Act 1 全部 10 个阶段的数据（普通阶段 + Boss 阶段）
#   提供静态查询方法供 GameManager 使用
#
# 阶段设计 (Act 1: 沼泽 → 朽败村落):
#   Stage 1-2:  沼泽 — 入门阶段 (skeleton/zombie/fallen)
#   Stage 3-4:  朽败村落 — 僵尸和恶魔增多
#   Stage 5:    扭曲树精的巢穴 — 第一个 Boss (安达瑞尔)
#   Stage 6-9:  沼泽深处 — 难度递增
#   Stage 10:   扭曲树精之王 — Act 1 最终 Boss (安达瑞尔增强版)
#
# 数据字段说明:
#   - stage_id: 唯一阶段编号
#   - stage_name: 显示名称 (中文)
#   - area_level: 区域等级 (影响敌人属性和掉落质量)
#   - act: 所属章节 (1-5)
#   - is_boss: 是否为 Boss 阶段
#   - boss_template: Boss 模板ID (仅 Boss 阶段)
#   - enemy_templates: 可能出现的普通敌人模板ID数组
#   - enemy_count_min/max: 本阶段敌人数量范围
#   - base_gold_drop: 基础金币掉落 (用于参考)
#   - base_xp_drop: 基础经验掉落 (用于参考)
#
# 依赖:
#   - GameManager: 使用阶段数据初始化敌人队列
#   - EnemyPresets: 敌人模板数据
# ============================================================
extends Node

const STAGES = {
    # ============================================================
    # Act 1: 沼泽区域 (入门，area_level 1-5)
    # ============================================================
    1: {
        "stage_id": 1,
        "stage_name": "沼泽",
        "area_level": 1,             # 最低区域等级，无额外缩放
        "act": 1,
        "is_boss": false,
        "boss_template": "",         # 非 Boss 阶段
        "enemy_templates": ["skeleton", "zombie", "fallen"],  # 三种基础敌人
        "enemy_count_min": 3,        # 最少 3 只
        "enemy_count_max": 5,        # 最多 5 只
        "base_gold_drop": 5,
        "base_xp_drop": 10,
    },
    2: {
        "stage_id": 2,
        "stage_name": "沼泽 2",
        "area_level": 2,             # 敌人属性 ×1.12
        "act": 1,
        "is_boss": false,
        "enemy_templates": ["skeleton", "zombie", "demon", "fallen"],  # 新增恶魔
        "enemy_count_min": 3,
        "enemy_count_max": 5,
        "base_gold_drop": 6,
        "base_xp_drop": 12,
    },
    3: {
        "stage_id": 3,
        "stage_name": "朽败村落",
        "area_level": 3,
        "act": 1,
        "is_boss": false,
        "enemy_templates": ["zombie", "demon", "fallen"],  # 骷髅退出
        "enemy_count_min": 3,
        "enemy_count_max": 5,
        "base_gold_drop": 7,
        "base_xp_drop": 14,
    },
    4: {
        "stage_id": 4,
        "stage_name": "朽败村落 2",
        "area_level": 4,
        "act": 1,
        "is_boss": false,
        "enemy_templates": ["zombie", "demon", "fallen"],
        "enemy_count_min": 4,        # 敌人数量增加
        "enemy_count_max": 6,
        "base_gold_drop": 8,
        "base_xp_drop": 16,
    },
    5: {
        "stage_id": 5,
        "stage_name": "扭曲树精的巢穴",
        "area_level": 5,
        "act": 1,
        "is_boss": true,             # ★ 第一个 Boss 阶段
        "boss_template": "andariel",  # 安达瑞尔 (扭曲树精)
        "enemy_templates": ["skeleton", "zombie"],  # 小怪数量减少
        "enemy_count_min": 2,
        "enemy_count_max": 3,
        "base_gold_drop": 20,        # Boss 阶段掉落大幅增加
        "base_xp_drop": 50,
    },

    # ============================================================
    # Act 1 后半: 沼泽深处 (area_level 6-10, 难度递增)
    # ============================================================
    6: {
        "stage_id": 6,
        "stage_name": "深沼地",
        "area_level": 6,
        "act": 1,
        "is_boss": false,
        "enemy_templates": ["zombie", "demon", "fallen"],
        "enemy_count_min": 4,
        "enemy_count_max": 6,
        "base_gold_drop": 9,
        "base_xp_drop": 18,
    },
    7: {
        "stage_id": 7,
        "stage_name": "深沼地 2",
        "area_level": 7,
        "act": 1,
        "is_boss": false,
        "enemy_templates": ["demon", "fallen"],  # 僵尸退出，更强敌人
        "enemy_count_min": 4,
        "enemy_count_max": 6,
        "base_gold_drop": 10,
        "base_xp_drop": 20,
    },
    8: {
        "stage_id": 8,
        "stage_name": "沼泽深处",
        "area_level": 8,
        "act": 1,
        "is_boss": false,
        "enemy_templates": ["demon", "fallen"],
        "enemy_count_min": 4,
        "enemy_count_max": 6,
        "base_gold_drop": 11,
        "base_xp_drop": 22,
    },
    9: {
        "stage_id": 9,
        "stage_name": "沼泽深处 2",
        "area_level": 9,
        "act": 1,
        "is_boss": false,
        "enemy_templates": ["demon", "fallen"],
        "enemy_count_min": 5,        # 敌人最多 7 只 → 考验生存
        "enemy_count_max": 7,
        "base_gold_drop": 12,
        "base_xp_drop": 24,
    },
    10: {
        "stage_id": 10,
        "stage_name": "扭曲树精之王",
        "area_level": 10,            # Act 1 最高等级
        "act": 1,
        "is_boss": true,             # ★ Act 1 最终 Boss
        "boss_template": "andariel",  # 使用同一 Boss 模板 (数值随等级缩放)
        "enemy_templates": ["zombie", "demon"],  # 小怪更强
        "enemy_count_min": 2,
        "enemy_count_max": 3,
        "base_gold_drop": 30,        # 最终 Boss 最高掉落
        "base_xp_drop": 100,
    },
}

# ============================================================
# 静态查询方法
# ============================================================

# 查找阶段数据 (返回副本)
# 找不到时返回 Stage 1 作为保底
func find_stage(stage_id: int) -> Dictionary:
    if STAGES.has(stage_id):
        return STAGES[stage_id].duplicate()
    return STAGES[1].duplicate()  # 保底: 返回第一阶段

# 获取所有阶段编号
func get_all_stages() -> Array[int]:
    var result: Array[int] = []
    result.assign(STAGES.keys())
    return result

# 判断指定阶段是否为 Boss 阶段
func is_boss_stage(stage_id: int) -> bool:
    var stage = find_stage(stage_id)
    return stage.get("is_boss", false)
