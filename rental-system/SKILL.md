---
name: rental-system
description: 租赁设备管理系统操作技能。当用户询问订单、设备、客户、发货、排单、库存、统计、闲鱼同步等相关问题时使用。支持关键词快捷指令和自然语言查询。
version: 2.0.0
---

# 租赁设备管理系统 - QClaw Skill

为 QClaw/OpenClaw/Agent 提供的租赁设备管理系统操作技能，支持自然语言和快捷指令操作订单、设备、客户等数据。

## API 基础信息

- **Base URL**: `https://your-domain.com/openapi/v1`
- **认证方式**: Bearer Token (`Authorization: Bearer <token>`)
- **响应格式**: JSON

---

## 快捷指令（极速响应）

响应最快，优先使用的接口。

### 1. 今日发货清单
```
GET /shortcuts/today-ship
```
**关键词**: 今日发货、今天发货、待发货、发货清单

**返回字段**:
- `pending_count` - 待发货数量
- `shipped_count` - 今日已发货数量
- `orders[]` - 订单列表（含打包状态 `is_packed`）

### 2. 明日发货清单
```
GET /shortcuts/tomorrow-ship
```
**关键词**: 明日发货、明天发货

### 3. 待排单订单
```
GET /shortcuts/pending
```
**关键词**: 待排单、未排单、待分配、排单

返回未发货且未分配设备的订单。

### 4. 进行中订单
```
GET /shortcuts/in-progress
```
**关键词**: 进行中、在租、已发货、租期中

### 5. 冲突订单检测
```
GET /shortcuts/conflicts
```
**关键词**: 冲突、冲突检测、时间冲突

检测已分配设备的订单是否存在时间冲突。

### 6. 设备状态查询
```
GET /shortcuts/device-status/<manage_code>
```
**关键词**: 设备状态、设备查询、{编号}状态

**示例**: `/shortcuts/device-status/EP7001`

### 7. 快速创建订单（自然语言）
```
POST /shortcuts/quick-create
Content-Type: application/json

{"text": "张三 EP7 3月29到4月5日 上海"}
```
**自动解析**: 客户名、型号、日期、城市

---

## 智能查询

### 单一入口
```
POST /smart-query
Content-Type: application/json

{"text": "今天要发货的"}
```

**支持的查询类型**:
- 时间查询: 今天/明天/下周/本周
- 状态查询: 进行中/未发货/已完成
- 设备查询: EP7空闲吗/设备状态
- 客户查询: 张三的订单

---

## 仪表盘统计

### App Dashboard
```
GET /stats/dashboard
```
**返回**:
- `orders.pending_ship` - 待发货数
- `orders.in_progress` - 进行中数
- `orders.today_ship` - 今日发货数
- `orders.today_return` - 今日归还数
- `orders.overdue` - 逾期数
- `devices.total` - 设备总数
- `devices.rented` - 已租数

### 概览统计
```
GET /stats/overview
```
设备、订单、收入综合统计。

### 待处理订单
```
GET /stats/pending-process
```
租期+回仓天数已过但未完结的订单，含超期天数统计。

### 设备利用率
```
GET /stats/device-utilization?start_date=2026-04-01&end_date=2026-04-30
```

### 收入统计
```
GET /stats/revenue?period=month
```
period 可选: `day`, `week`, `month`, `year`

### 财务统计
```
GET /stats/finance?period=month
```
收入/支出/净收入按分类统计。

---

## 订单管理 API

### 获取订单列表
```
GET /orders?page=1&page_size=20&status=未发货
```

**参数**:
| 参数 | 说明 |
|------|------|
| `status` | 状态：未发货、进行中、已完成、未结算、异常 |
| `tab` | 特殊筛选：pending_process（待处理）|
| `delivery_date` | 发货日期 YYYY-MM-DD |
| `delivery_date_from/to` | 发货日期范围 |
| `start_date_from/to` | 起租日期范围 |
| `device_model` | 设备型号 |
| `is_packed` | 打包状态：true/false |
| `delivery_method` | 发货方式：快递、自提、闪送 |

### 获取订单详情
```
GET /orders/<order_no>
```

### 创建订单
```
POST /orders
Content-Type: application/json

{
  "customer": {
    "name": "张三",
    "phone": "13800138000",
    "address": "北京市朝阳区xxx"
  },
  "rental_period": {
    "start_date": "2026-04-01",
    "end_date": "2026-04-07"
  },
  "delivery": {
    "city": "北京",
    "address": "朝阳区xxx",
    "method": "快递"
  },
  "amount": {
    "total": 500,
    "deposit": 0
  },
  "device_model": "EP7",
  "source": "闲鱼",
  "notes": "备注信息"
}
```

**source 支持格式**:
- `"闲鱼"` / `"微信"` / `"淘宝"` - 标准来源
- `"帮人发 海达"` - 代发订单（帮别人发）
- `"别人发 海达"` - 代发订单（别人帮我发，无需排单）

### 更新订单
```
PUT /orders/<order_no>
Content-Type: application/json

{
  "delivery_method": "快递",
  "delivery_city": "北京",
  "manage_code": "EP7001",
  "notes": "备注"
}
```

**重要参数**:
- `manage_code` - 绑定设备，冲突时返回 `code: 1002`
- `force: true` - 强制绑定（解绑冲突订单的设备）
- `sync_linked: true` - 同步关联订单（同客户+同租期）

### 取消订单
```
POST /orders/<order_no>/cancel
```
仅限未发货/打包好状态，物理删除订单。

### 切换打包状态
```
POST /orders/<order_no>/toggle-packed
```

---

## 订单状态操作

### 发货
```
POST /orders/<order_no>/ship
Content-Type: application/json

{
  "tracking_no": "SF1234567890",  // 可选，不填则自动顺丰下单
  "delivery_method": "快递"
}
```

**发货逻辑**:
1. 快递 → 调用顺丰 API 下单
2. 自提/闪送 → 直接标记发货
3. 自动同步闲鱼发货状态

### 完结订单
```
POST /orders/<order_no>/complete
Content-Type: application/json

{
  "device_return_status": "未打包"  // 可选：未打包/打包好/维修
}
```

- 普通订单 → 已完成
- 代发订单 → 未结算

### 结算订单
```
POST /orders/<order_no>/settle
```
未结算 → 已完成

### 标记异常
```
POST /orders/<order_no>/exception
Content-Type: application/json

{
  "exception_type": "设备损坏",
  "exception_note": "镜头有划痕"
}
```

### 处理异常
```
POST /orders/<order_no>/resolve-exception
```
异常 → 未结算/已完成

---

## 排单 API

### 待排单订单列表
```
GET /orders/pending-assign?page=1&page_size=20
```
返回 `available_count`（该型号可用设备数）。

### 查询订单可用设备
```
GET /orders/<order_no>/available-devices
```
返回可分配设备列表，含 `is_direct_transfer`（是否可直连发货）。

### 分配设备
```
POST /orders/<order_no>/assign
Content-Type: application/json

{
  "device_id": 10
}
```

### 一键自动排单
```
POST /scheduling/auto
Content-Type: application/json

{
  "models": ["EP7", "Action5"]  // 可选，不传则处理所有
}
```

---

## 设备管理 API

### 获取设备列表
```
GET /devices?status=在库&model=EP7
```

**状态值**: 未打包、打包好、已租、维修、丢失

### 获取设备详情
```
GET /devices/<device_id>
```

### 获取设备排期
```
GET /devices/<device_id>/schedule?month=2026-04
```
返回每日占用状态。

### 获取设备占用时间线
```
GET /devices/<device_id>/timeline
```
返回设备占用时段列表。

### 获取设备历史订单
```
GET /devices/<device_id>/history
```

### 获取设备收益统计
```
GET /devices/<device_id>/revenue
```

### 创建设备
```
POST /devices
Content-Type: application/json

{
  "device_name": "EP7-001",
  "brand": "Insta360",
  "model": "EP7",
  "manage_code": "EP7001",
  "status": "未打包",
  "location": "上海仓库"
}
```

### 更新设备
```
PUT /devices/<device_id>
Content-Type: application/json

{
  "status": "已租",
  "manage_code": "EP7001"
}
```

**注意**: 修改管理编号会检测订单冲突。

### 设备问题上报
```
POST /devices/<device_id>/report-issue
Content-Type: application/json

{
  "issue_type": "损坏",
  "description": "镜头有划痕",
  "reporter": "张三"
}
```

---

## 设备分组 API

### 获取分组列表
```
GET /device-groups
```

### 获取分组详情
```
GET /device-groups/<group_id>
```

### 创建/更新/删除分组
```
POST /device-groups
PUT /device-groups/<group_id>
DELETE /device-groups/<group_id>
```

---

## 客户管理 API

### 获取客户列表
```
GET /customers?q=张三&page=1&page_size=20
```

### 获取客户详情
```
GET /customers/<customer_id>
GET /customers/phone/<phone>
```

### 获取客户订单
```
GET /customers/<customer_id>/orders?status=进行中
```

### 获取客户当前租借
```
GET /customers/<customer_id>/current-rentals
```

### 创建客户
```
POST /customers
Content-Type: application/json

{
  "name": "李四",
  "phone": "13800138000",
  "xianyu_nick": "闲鱼用户名"
}
```

### 更新客户
```
PUT /customers/<customer_id>
```

---

## 订单搜索

### 模糊搜索
```
GET /orders/search?q=张三
```
支持搜索：订单号、客户名、闲鱼昵称、设备型号、管理编号、代发人。

---

## 系统配置 API

### 获取系统设置
```
GET /settings
```

### 顺丰配置
```
GET /settings/sf   // 敏感字段脱敏
POST /settings/sf  // 仅管理员
```

### 闲鱼配置
```
GET /settings/xy   // 敏感字段脱敏
POST /settings/xy  // 仅管理员
```

---

## 关键词映射表

| 用户输入 | 调用接口 |
|---------|---------|
| 今日发货/今天发货/待发货 | `GET /shortcuts/today-ship` |
| 明日发货/明天发货 | `GET /shortcuts/tomorrow-ship` |
| 待排单/未排单/排单 | `GET /shortcuts/pending` |
| 进行中/在租/已发货 | `GET /shortcuts/in-progress` |
| 冲突/时间冲突 | `GET /shortcuts/conflicts` |
| {编号}状态/设备{编号} | `GET /shortcuts/device-status/{编号}` |
| 创建订单 {文本} | `POST /shortcuts/quick-create` |
| 统计/概览/仪表盘 | `GET /stats/dashboard` |
| 其他自然语言 | `POST /smart-query` |

---

## 响应格式说明

所有接口统一响应格式：
```json
{
  "code": 0,        // 0=成功，其他=错误码
  "message": "操作成功",
  "data": { ... }   // 返回数据
}
```

**常见错误码**:
| 错误码 | 说明 |
|--------|------|
| 1001 | 参数错误 |
| 1002 | 数据验证失败/时间冲突 |
| 1003 | 设备不存在/权限不足 |
| 2001 | 记录不存在 |
| 2002 | 状态不允许操作 |
| 2003 | 设备不存在 |
| 3001 | 权限不足 |
| 4001 | 有关联数据，无法删除 |

---

## 业务逻辑说明

### 订单状态流转
```
未发货 → 进行中 → 已完成
                 ↘ 未结算（代发订单）→ 已完成
         ↘ 异常 → 已完成
```

### 代发订单
- `is_agent=True` 表示代发订单
- `agent_type`: `help`（帮人发）/ `recv`（别人发）
- `recv` 类型订单不需要排单，不需要绑定设备

### 直连发货
设备从上一客户直发下一客户：
- `is_direct_transfer=True`
- 跳过仓库中转
- 节省物流时间

### 物流时间计算
- 仓库城市：上海
- 发货日期 = 起租日期 - 发货物流天数
- 可用日期 = 归还日期 + 回仓物流天数

---

## 使用示例

### 示例 1: 查询今日发货
```
用户: 今天要发哪些货？
QClaw: 调用 GET /shortcuts/today-ship
响应: 今天共有 5 单待发货，3 单已发货...
```

### 示例 2: 快速创建订单
```
用户: 帮我创建一个订单，王五，EP7，4月1号到4月7号，北京
QClaw: 调用 POST /shortcuts/quick-create
       Body: {"text": "王五 EP7 4月1到4月7日 北京"}
响应: 订单创建成功，订单号 ORD20260401xxx
```

### 示例 3: 查设备状态
```
用户: EP7001 这个设备现在什么状态？
QClaw: 调用 GET /shortcuts/device-status/EP7001
响应: EP7001 当前状态：已租，租给张三，4月7日归还
```

### 示例 4: 排单
```
用户: 帮我把所有待排单的订单自动排一下
QClaw: 调用 POST /scheduling/auto
响应: 自动排单完成，成功 5 单，失败 2 单
```

### 示例 5: 代发订单
```
用户: 创建一个订单，来源是帮人发，代发人叫海达
QClaw: 调用 POST /orders
       Body: {"customer": {...}, "source": "帮人发 海达", ...}
响应: 订单创建成功，标记为代发订单
```

### 示例 6: 发货
```
用户: 把订单 ORD20260401xxx 发货，快递单号 SF123456
QClaw: 调用 POST /orders/ORD20260401xxx/ship
       Body: {"tracking_no": "SF123456"}
响应: 发货成功，状态已同步闲鱼
```

---

## 注意事项

1. **认证**: 所有请求需要携带有效的 Bearer Token
2. **租户隔离**: 通过 Token 自动识别租户，数据自动隔离
3. **关联订单**: 同客户+同租期的订单会同步发货信息
4. **冲突检测**: 分配设备和修改编号时会自动检测时间冲突
5. **闲鱼同步**: 快递发货自动同步闲鱼，自提/闪送需手动
6. **代发订单**: `别人发` 类型不需要排单，直接发货即可
