# Enemy.gd - 敌人数据持有者（运行时）
# 战斗 Tick 中使用的敌人实例
class_name Enemy
extends RefCounted

# ============================================================
# 属性
# ============================================================
var enemy_id: String = ""
var display_name: String = ""
var is_boss: bool = false
var max_health: float = 50.0
var current_health: float = 50.0
var damage: float = 5.0
var defense: float = 0.0
var fire_resist: float = 0.0
var cold_resist: float = 0.0
var lightning_resist: float = 0.0
var poison_resist: float = 0.0
var xp_reward: float = 10.0
var gold_reward: float = 5.0
var sprite_path: String = ""

# ============================================================
# 构造函数
# ============================================================
static func from_template(template: Dictionary, area_level: int) -> Enemy:
    var enemy := Enemy.new()
    enemy.enemy_id = template.get("id", "")
    enemy.display_name = template.get("name", "未知怪物")
    enemy.is_boss = template.get("is_boss", false)

    # 属性随区域等级缩放
    var scaling := pow(1.12, area_level - 1)  # 每阶段 +12%
    enemy.max_health = template.get("base_hp", 50.0) * scaling
    enemy.current_health = enemy.max_health
    enemy.damage = template.get("base_damage", 5.0) * scaling
    enemy.defense = template.get("base_defense", 0.0) * scaling
    enemy.fire_resist = template.get("fire_resist", 0.0)
    enemy.cold_resist = template.get("cold_resist", 0.0)
    enemy.lightning_resist = template.get("lightning_resist", 0.0)
    enemy.poison_resist = template.get("poison_resist", 0.0)
    enemy.xp_reward = template.get("xp_reward", 10.0) * pow(1.10, area_level - 1)
    enemy.gold_reward = template.get("gold_reward", 5.0) * pow(1.08, area_level - 1)
    enemy.sprite_path = template.get("sprite_path", "")

    return enemy

# ============================================================
# 战斗方法
# ============================================================
func take_damage(amount: float) -> float:
    """造成伤害，返回实际伤害值"""
    var actual_damage := maxf(amount - defense * 0.1, 1.0)  # 防御减伤，最小 1 点
    current_health -= actual_damage
    return actual_damage

func is_dead() -> bool:
    return current_health <= 0.0

func get_health_percent() -> float:
    if max_health <= 0.0:
        return 0.0
    return clampf(current_health / max_health, 0.0, 1.0)
