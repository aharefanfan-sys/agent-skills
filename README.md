# Agent Skills

这是一个为 QClaw/OpenClaw/Agent 提供的技能库。

## 可用技能

### rental-system
租赁设备管理系统操作技能。

**功能**:
- 订单管理（创建、查询、更新、发货）
- 设备管理（状态查询、可用性检查）
- 客户管理
- 快捷指令（今日发货、待排单、冲突检测等）
- 自然语言查询

**使用方式**: QClaw 从此仓库加载 skill 后，可通过微信发送自然语言指令操作租赁系统。

## 如何使用

1. 在 QClaw 配置中添加此仓库地址
2. QClaw 会自动加载 `rental-system/SKILL.md`
3. 通过微信发送指令即可调用

## 目录结构

```
agent-skills/
├── README.md
└── rental-system/
    └── SKILL.md          # 租赁系统技能定义
```

## 添加新技能

1. 创建新目录 `your-skill/`
2. 添加 `SKILL.md` 文件
3. 在文件开头添加 frontmatter:

```yaml
---
name: your-skill
description: 技能描述，说明何时使用此技能
version: 1.0.0
---
```
