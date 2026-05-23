---
name: rental-system
description: 租赁设备管理系统操作技能。当用户询问订单、设备、客户、发货、排单、库存、统计、闲鱼同步、免押码、定价规则等相关问题时使用。支持关键词快捷指令和自然语言查询。
version: 3.0.0
---

# 租赁设备管理系统 - QClaw Skill

为 QClaw/OpenClaw/Agent 提供的租赁设备管理系统操作技能，支持自然语言和快捷指令操作订单、设备、客户等数据。

## API 基础信息

- **Base URL**: `https://your-domain.com/openapi/v1`
- **响应格式**: JSON

---

## 认证方式

系统有三种认证方式，绝大多数接口使用 **方式一**。

### 方式一：OAuth2 Bearer Token（主要）

适用于所有业务 API 接口。

**1. 获取 Token（client_credentials 模式）**

在 ERP 开发者平台创建应用后，获得 `client_id`（AppKey）和 `client_secret`（AppSecret），然后：

```
POST /openapi/v1/oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&client_id=你的AppKey&client_secret=你的AppSecret
```

**响应**:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJhbG...",
    "refresh_token": "dGhpcyBpcy...",
    "token_type": "Bearer",
    "expires_in": 2592000,
    "scope": "order:read order:write device:read inventory:read customer:read callback:manage"
  }
}
```

**2. 使用 Token**

```
Authorization: Bearer {access_token}
```

**3. 刷新 Token**

```
POST /openapi/v1/oauth/token

grant_type=refresh_token&refresh_token=xxx&client_id=xxx&client_secret=xxx
```

**Token 有效期**: 30 天（refresh_token 90 天）

### 方式二：App 用户登录

适用于移动端应用，用用户名密码直接换 Token。

```
POST /openapi/v1/auth/login
Content-Type: application/json

{"username": "admin", "password": "admin123"}
```

返回相同的 `access_token`，额外包含用户信息和租户信息。Token 有效期 30 天。

### 方式三：X-API-Key（小程序回调专用）

仅用于小程序扫码下单的回调接口（`/miniprogram-order-callback` 和 `/miniprogram-order-unlink`），不走 OAuth。

```
X-API-Key: {MINIPROGRAM_API_KEY}
```

此 Key 在 ERP 系统设置中配置。

### 权限范围（Scope）

| Scope | 说明 |
|-------|------|
| `order:read` | 查询订单、统计 |
| `order:write` | 创建/修改/取消订单、发货、完结 |
| `device:read` | 查询设备 |
| `device:write` | 设备管理、上报问题、分组 |
| `inventory:read` | 查询库存、定价规则 |
| `inventory:write` | 管理物流规则、定价规则 |
| `customer:read` | 查询客户 |
| `customer:write` | 创建/修改客户 |
| `callback:manage` | 管理回调配置 |

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
- `orders.unsettled` - 未结算数
- `orders.exception` - 异常数
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
period 可选: `day`, `week`, `month`

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
| `status` | 状态：未发货、进行中、已完成、未结算、异常、已取消 |
| `tab` | 特殊筛选：pending_process（待处理）|
| `delivery_date` | 发货日期 YYYY-MM-DD |
| `delivery_date_from/to` | 发货日期范围 |
| `start_date_from/to` | 起租日期范围 |
| `device_model` | 设备型号 |
| `is_packed` | 打包状态：true/false |
| `delivery_method` | 发货方式：快递、自提、闪送 |
| `customer_phone` | 客户手机号 |

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

| 输入值 | 存储值 | 说明 |
|--------|--------|------|
| `"闲鱼"` | `xianyu` | 闲鱼来源 |
| `"微信"` | `wechat` | 微信来源 |
| `"淘宝"` | `taobao` | 淘宝来源 |
| `"帮人发 海达"` | `agent_help` | 代发订单（帮别人发），需排单 |
| `"别人发 海达"` | `agent_recv` | 代发订单（别人帮我发），无需排单 |

**代发订单返回字段**:
```json
{
  "source": "agent_help",
  "is_agent": true,
  "agent_name": "海达",
  "agent_type": "help",
  "need_scheduling": true
}
```

- `agent_type = "help"` → 需要排单、需要绑定设备
- `agent_type = "recv"` → 不需要排单、不需要绑定设备

### 从闲鱼订单创建
```
POST /orders/from-xianyu
Content-Type: application/json

{
  "xianyu_order_no": "3302162799871039670",
  "buyer_nick": "买家昵称",
  "receiver_name": "张三",
  "receiver_mobile": "13800138000",
  "model": "GR3",
  "start_date": "2026-04-01",
  "end_date": "2026-04-07",
  "city": "北京",
  "pay_amount": 350,
  "exempt_deposit_no": "my123456",
  "seller_remark": "自提"
}
```
含重复检测（code=2006），`force: true` 强制创建，`sync: true` 同步更新已存在订单。

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
Content-Type: application/json

{"reason": "客户取消"}
```
支持取消未发货/进行中/异常/已完成/未结算订单。取消时自动恢复设备状态（如无其他活跃订单）并清理财务账单。

### 切换打包状态
```
POST /orders/<order_no>/toggle-packed
```

### 模糊搜索
```
GET /orders/search?q=张三
```
支持搜索：订单号、客户名、闲鱼昵称、设备型号、管理编号、代发人。

### 批量创建
```
POST /orders/batch-create
Content-Type: application/json

{"orders": [{...}, {...}]}
```

### 批量发货
```
POST /orders/batch-ship
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

## 免押码接口

通过支付宝小程序生成免押二维码，客户扫码后自动关联订单。

### 按 ERP 订单号生成
```
POST /orders/<order_no>/generate-qrcode
Content-Type: application/json

{
  "rental_days": 5,        // 可选，默认用订单起止日期
  "total_amount": 100.00,  // 可选，默认 0.01 × 租期天数
  "deposit_amount": 500    // 可选，留空由芝麻评估
}
```

**响应**:
```json
{
  "code": 0,
  "data": {
    "qrcode_url": "https://...",
    "qrcode_base64": "data:image/png;base64,...",
    "device_name": "佳能 IXUS130",
    "rental_days": 5,
    "erp_order_no": "ORD202605101347400145",
    "expire_at": "2026-05-11T12:00:00.000Z"
  }
}
```

### 按闲鱼订单号生成（外部 Agent 专用）
```
POST /xianyu-orders/<xianyu_order_no>/generate-qrcode
Content-Type: application/json
```

参数和响应与上方一致，额外返回 `order_no` 和 `xianyu_order_no` 字段。

**外部 Agent 使用流程**:
1. 持有闲鱼订单号 → 调用此接口生成二维码
2. 把二维码发给客户 → 客户支付宝扫码下单
3. 小程序自动回调关联 ERP 订单
4. 轮询 `miniprogram-status` 确认状态

### 查询免押状态
```
GET /orders/<order_no>/miniprogram-status
```

### 小程序下单回调（X-API-Key 认证）
```
POST /miniprogram-order-callback
X-API-Key: {MINIPROGRAM_API_KEY}
Content-Type: application/json

{"erp_order_no": "ORD20260510xxx", "mp_order_no": "小程序订单号"}
```
客户扫码下单成功后，小程序自动调用此接口关联 ERP 订单并更新 `exempt_deposit_no`。

### 小程序订单解绑（X-API-Key 认证）
```
POST /miniprogram-order-unlink
X-API-Key: {MINIPROGRAM_API_KEY}
Content-Type: application/json

{"erp_order_no": "ORD20260510xxx", "mp_order_no": "小程序订单号"}
```
小程序订单取消后自动解除关联。

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

### 抢占式分配
```
POST /orders/<order_no>/preempt-device
Content-Type: application/json

{"device_id": 100}
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

## 库存查询 API

### 型号库存查询
```
GET /inventory/models/<model>/availability?start_date=2026-04-01&end_date=2026-04-07&city=北京
```

**响应**:
```json
{
  "code": 0,
  "data": {
    "model": "GR3",
    "total_devices": 5,
    "available_devices": 3,
    "normal_available": 2,
    "direct_transfer_available": 1,
    "unavailable_reason": [
      {"device_id": 101, "manage_code": "GR3-002", "reason": "已出租", "available_from": "2026-04-05"}
    ]
  }
}
```

### 可用型号列表
```
GET /inventory/models/available?start_date=2026-04-01&end_date=2026-04-07
```

### 批量检查库存
```
POST /inventory/batch-check
Content-Type: application/json

{
  "models": ["GR3", "X100V", "A7M4"],
  "start_date": "2026-04-01",
  "end_date": "2026-04-07",
  "city": "北京"
}
```

---

## 型号定价规则 API

定价规则为文本描述（如「首天70，第二天90，前三天110，续租25一天」），供 AI 客服等外部系统查询。

### 获取所有定价规则
```
GET /models/pricing-rules
```

### 按型号查询
```
GET /models/<model>/pricing-rule
```
型号不存在时返回 `pricing_rule: null`。

### 创建/更新定价规则
```
POST /models/<model>/pricing-rule
Content-Type: application/json

{"pricing_rule": "首天70，第二天90，前三天110，续租25一天"}
```
同型号已存在则更新，不存在则创建。按租户隔离。

### 删除定价规则
```
DELETE /models/<model>/pricing-rule
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

## 账单 API

### 账单列表
```
GET /bills?type=income&date_from=2026-04-01&date_to=2026-04-30&page=1
```
响应含 summary 字段（总收入、总支出、净额）。

### 订单收款记录
```
GET /orders/<order_no>/bills
```

### 添加收款
```
POST /orders/<order_no>/bills
Content-Type: application/json

{
  "amount": 350.00,
  "type": "income",
  "category": "租金",
  "payment_method": "支付宝",
  "notes": "尾款"
}
```

### 编辑/删除账单
```
PUT /bills/<bill_id>
DELETE /bills/<bill_id>
```

---

## 闲鱼订单 API

### 闲鱼订单列表
```
GET /xianyu/orders?page=1
```

### 同步已发货状态
```
POST /xianyu/sync-shipped
```
将租赁系统中已发货的闲鱼订单同步到闲鱼平台。

### 全量同步
```
POST /xianyu/sync-all
```
从闲鱼拉取全部订单并同步到租赁系统。

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

## 回调通知

### 配置回调
```
POST /callbacks/config
Content-Type: application/json

{
  "callback_url": "https://your-server.com/callback",
  "callback_secret": "your_secret",
  "events": [
    "order.created",
    "order.status_changed",
    "order.delivered",
    "order.completed",
    "order.cancelled",
    "device.status_changed"
  ]
}
```

### 回调消息格式
```
POST {callback_url}
X-Signature: sha256={signature}
X-Timestamp: 1711440000
X-Event: order.status_changed

{
  "event": "order.status_changed",
  "timestamp": 1711440000,
  "data": {
    "order_no": "ORD20260326143052",
    "old_status": "未发货",
    "new_status": "进行中",
    "customer_name": "张三",
    "device_name": "理光GR3"
  }
}
```

### 签名验证
```python
import hmac, hashlib
def verify_signature(secret, timestamp, body, signature):
    message = f"{timestamp}.{body}"
    expected = "sha256=" + hmac.new(secret.encode(), message.encode(), hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)
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
| 定价/价格/租金 | `GET /models/{model}/pricing-rule` |
| 库存/有没有货/空闲 | `GET /inventory/models/{model}/availability` |
| 免押码/二维码/免押 | `POST /orders/{no}/generate-qrcode` |
| 闲鱼订单/同步闲鱼 | `GET /xianyu/orders` 或 `POST /xianyu/sync-all` |
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
| 1003 | Token 过期 |
| 1004 | 权限不足 |
| 1005 | 签名错误 |
| 2001 | 记录不存在 |
| 2002 | 状态不允许操作 |
| 2003 | 设备不存在 |
| 2004 | 设备不可用 |
| 2005 | 库存不足 |
| 2006 | 闲鱼订单已存在 |
| 3001 | 回调地址不可达 |
| 9999 | 系统错误 |

---

## 业务逻辑说明

### 订单状态流转
```
未发货 → 进行中 → 已完成
                 ↘ 未结算（代发订单）→ 已完成
         ↘ 异常 → 已完成
```

### 订单取消
支持取消未发货/进行中/异常/已完成/未结算订单。取消时自动恢复设备状态（如无其他活跃订单），并清理关联的财务账单。

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

### 账单类型
- `order` scope：订单内记账（进行中的收支跟踪）
- `finance` scope：正式财务账单（完结时自动汇总生成）

---

## 使用示例

### 示例 1: 查询今日发货
```
用户: 今天要发哪些货？
Agent: 调用 GET /shortcuts/today-ship
响应: 今天共有 5 单待发货，3 单已发货...
```

### 示例 2: 快速创建订单
```
用户: 帮我创建一个订单，王五，EP7，4月1号到4月7号，北京
Agent: 调用 POST /shortcuts/quick-create
       Body: {"text": "王五 EP7 4月1到4月7日 北京"}
响应: 订单创建成功，订单号 ORD20260401xxx
```

### 示例 3: 查设备状态
```
用户: EP7001 这个设备现在什么状态？
Agent: 调用 GET /shortcuts/device-status/EP7001
响应: EP7001 当前状态：已租，租给张三，4月7日归还
```

### 示例 4: 排单
```
用户: 帮我把所有待排单的订单自动排一下
Agent: 调用 POST /scheduling/auto
响应: 自动排单完成，成功 5 单，失败 2 单
```

### 示例 5: 生成免押二维码
```
用户: 给闲鱼订单 3302162799871039670 生成免押码
Agent: 调用 POST /xianyu-orders/3302162799871039670/generate-qrcode
响应: 二维码已生成，发给客户扫码即可
```

### 示例 6: 查询定价规则
```
用户: GR3 的定价规则是什么？
Agent: 调用 GET /models/GR3/pricing-rule
响应: 首天70，第二天90，前三天110，续租25一天
```

### 示例 7: 查询库存
```
用户: 4月1号到4月7号 GR3 有货吗？
Agent: 调用 GET /inventory/models/GR3/availability?start_date=2026-04-01&end_date=2026-04-07
响应: GR3 共 5 台，可用 3 台，1 台可直连发货
```

### 示例 8: 代发订单
```
用户: 创建一个订单，来源是帮人发，代发人叫海达
Agent: 调用 POST /orders
       Body: {"customer": {...}, "source": "帮人发 海达", ...}
响应: 订单创建成功，标记为代发订单
```

---

## 注意事项

1. **认证**: 所有请求需要携带有效的 Bearer Token
2. **租户隔离**: 通过 Token 自动识别租户，数据自动隔离
3. **关联订单**: 同客户+同租期的订单会同步发货信息
4. **冲突检测**: 分配设备和修改编号时会自动检测时间冲突
5. **闲鱼同步**: 快递发货自动同步闲鱼，自提/闪送需手动
6. **代发订单**: `别人发` 类型不需要排单，直接发货即可
7. **免押二维码**: 每次调用生成新预订单，旧的自动过期
8. **定价规则**: 按型号+租户唯一，供 AI 客服查询报价
