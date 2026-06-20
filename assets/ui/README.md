# UI 界面资源

## 目录用途
存放所有用户界面元素：面板背景、按钮、血球、装备槽、掉落光束、背包格子等。

## 图片规格要求
- **格式**: PNG（支持透明通道）
- **风格**: 哥特式暗黑 UI — 暗色石材纹理 + 金色镶边 + 符文铭文装饰
- **9-Slice**: 面板和按钮需支持 9-slice 缩放（四周固定边框 + 中间可拉伸）

## 面板背景

| 资源名称 | 描述 | 尺寸 | 9-Slice | 优先级 |
|----------|------|------|---------|--------|
| `panel_dark.png` | 暗色石板面板（主 UI 背景） | 256×256 | 是 | P0 |
| `panel_gold_border.png` | 金色镶边面板（稀有物品/重要界面） | 256×256 | 是 | P0 |
| `panel_inventory.png` | 背包面板（深色底+网格线） | 512×512 | 是 | P0 |
| `panel_tooltip.png` | 提示框背景（半透明暗色） | 128×128 | 是 | P1 |
| `panel_skill_tree.png` | 技能树背景（大面积暗色） | 512×512 | 是 | P1 |

## 按钮

| 资源名称 | 描述 | 尺寸 | 优先级 |
|----------|------|------|--------|
| `btn_normal.png` | 普通状态 — 暗色石材 | 200×60 | P0 |
| `btn_hover.png` | 悬停状态 — 符文发光 | 200×60 | P0 |
| `btn_pressed.png` | 按下状态 — 石材凹陷 | 200×60 | P0 |
| `btn_disabled.png` | 禁用状态 — 灰色暗沉 | 200×60 | P0 |
| `btn_small_normal.png` | 小按钮 — 属性分配+/- | 40×40 | P1 |
| `btn_tab_normal.png` | 标签按钮 — 菜单切换 | 120×40 | P1 |

## 血球/资源球（Diablo 2 风格）

| 资源名称 | 描述 | 尺寸 | 优先级 |
|----------|------|------|--------|
| `orb_health_bg.png` | 生命球底 — 暗色球体+金属边框 | 128×128 | P0 |
| `orb_health_fill.png` | 生命球填充 — 红色液体 | 128×128 | P0 |
| `orb_mana_bg.png` | 法力球底 — 暗色球体+金属边框 | 128×128 | P0 |
| `orb_mana_fill.png` | 法力球填充 — 蓝色液体 | 128×128 | P0 |

## 装备槽位

| 资源名称 | 描述 | 尺寸 | 优先级 |
|----------|------|------|--------|
| `slot_helm.png` | 头盔槽 | 64×64 | P0 |
| `slot_armor.png` | 盔甲槽 | 64×64 | P0 |
| `slot_gloves.png` | 手套槽 | 64×64 | P0 |
| `slot_boots.png` | 靴子槽 | 64×64 | P0 |
| `slot_belt.png` | 腰带槽 | 64×64 | P0 |
| `slot_weapon_main.png` | 主手武器槽 | 64×128 | P0 |
| `slot_weapon_off.png` | 副手槽 | 64×96 | P0 |
| `slot_ring.png` | 戒指槽 | 48×48 | P0 |
| `slot_amulet.png` | 项链槽 | 48×48 | P0 |
| `slot_empty.png` | 空槽位通用背景 | 64×64 | P1 |

## 掉落光束

| 资源名称 | 描述 | 配色 | 优先级 |
|----------|------|------|--------|
| `beam_common.png` | 普通掉落光束 | 白色 #ffffff | P1 |
| `beam_magic.png` | 魔法掉落光束 | 蓝色 #4169e1 | P1 |
| `beam_rare.png` | 稀有掉落光束 | 黄色 #ffd700 | P1 |
| `beam_epic.png` | 史诗掉落光束 | 金色 #daa520 | P1 |
| `beam_legendary.png` | 传奇掉落光束 | 橙色 #ff8c00 | P1 |
| `beam_ancient.png` | 远古掉落光束 | 红色 #ff4444 | P1 |

## 背包/物品

| 资源名称 | 描述 | 尺寸 | 优先级 |
|----------|------|------|--------|
| `inventory_cell.png` | 背包格子 — 单个物品槽 | 48×48 | P0 |
| `inventory_cell_selected.png` | 选中状态 — 高亮边框 | 48×48 | P1 |
| `inventory_cell_equipped.png` | 已装备标记 — 小E角标 | 48×48 | P2 |

## 通用图标

| 资源名称 | 描述 | 尺寸 | 优先级 |
|----------|------|------|--------|
| `icon_gold.png` | 金币图标 | 24×24 | P0 |
| `icon_soul.png` | 灵魂图标 | 24×24 | P1 |
| `icon_blood_shard.png` | 血石图标 | 24×24 | P2 |
| `icon_close.png` | 关闭按钮 X | 32×32 | P1 |
| `icon_sort.png` | 排序按钮 | 32×32 | P2 |
| `icon_filter.png` | 筛选按钮 | 32×32 | P2 |

## 引擎内使用
- 9-Slice 面板：在 `TextureRect` 中将 stretch mode 设为 "Scale on Expand"，在 `Theme` 中配置 `StyleBoxTexture`
- 按钮：使用 `Button` 节点的 `Theme Overrides` 设置各状态样式
- 血球：使用 `TextureProgressBar`，设置 `under` 和 `progress` 纹理
- 掉落光束：使用 `Sprite2D` 或 `GPUParticles2D` 放置在战斗区域
