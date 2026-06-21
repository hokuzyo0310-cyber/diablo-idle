# ============================================================
# Boot.gd - 游戏启动引导脚本
# 职责：
#   1. 检查是否有存档 → 有则加载，无则显示角色选择
#   2. 初始化所有 Autoload 系统
#   3. 应用离线进度（如果有）
#   4. 切换到主游戏场景
# ============================================================
extends Node

# ============================================================
# 启动流程
# ============================================================
func _ready() -> void:
    print("=".repeat(40))
    print("  暗黑破坏神 — 挂机刷宝 v0.1.0")
    print("  Diablo Idle - MVP Phase 1")
    print("=".repeat(40))

    # 步骤 1：检查存档
    var has_save := SaveManager.has_save()

    if has_save:
        # 有存档 → 加载 + 计算离线进度
        print("[启动] 发现存档，正在加载...")
        var loaded := SaveManager.load_game()
        if loaded:
            SaveManager.calculate_and_apply_offline_progress()
            GameManager._recalculate_stats()
            _start_main_game()
        else:
            # 存档损坏 → 回退到角色选择
            push_warning("[启动] 存档加载失败，回退到角色选择")
            _show_character_select()
    else:
        # 无存档 → 显示角色选择
        print("[启动] 未找到存档，显示角色选择")
        _show_character_select()


# ============================================================
# 场景切换
# ============================================================
func _start_main_game() -> void:
    # 尝试加载主游戏场景
    var path := "res://scenes/main_game.tscn"
    if ResourceLoader.exists(path):
        get_tree().change_scene_to_file(path)
    else:
        _create_main_game_dynamic()

func _show_character_select() -> void:
    var path := "res://scenes/character_select.tscn"
    if ResourceLoader.exists(path):
        get_tree().change_scene_to_file(path)
    else:
        _create_character_select_dynamic()


# ============================================================
# 动态创建场景（当 .tscn 文件尚未通过编辑器生成时使用）
# ============================================================
func _create_main_game_dynamic() -> void:
    # 清除当前场景
    _clear_root()

    # 创建主游戏 UI
    var main_ui := load("res://scripts/ui/main_game_ui.gd").new()
    main_ui.name = "MainGameUI"
    get_tree().root.add_child(main_ui)

    # 确保 GameManager 定时器已启动
    if not GameManager.is_initialized:
        GameManager._setup_timers()
        GameManager.is_initialized = true

    print("✓ 主游戏已启动（动态创建模式）")

func _create_character_select_dynamic() -> void:
    _clear_root()

    var select_ui := load("res://scripts/ui/character_select.gd").new()
    select_ui.name = "CharacterSelect"
    get_tree().root.add_child(select_ui)

    print("✓ 角色选择已显示（动态创建模式）")

func _clear_root() -> void:
    # 移除所有非 Autoload 子节点
    for child in get_tree().root.get_children():
        if child.name in ["EventBus", "GameManager", "SaveManager", "LootManager",
                           "CharacterPresets", "EquipmentPresets", "EnemyPresets",
                           "AffixPresets", "StagePresets"]:
            continue  # 保留 Autoload 节点
        child.queue_free()
