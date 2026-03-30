---
name: rental-system
description: 租赁设备管理系统操作技能。当用户询问订单、设备、客户、发货、排单、库存等相关问题时使用。支持关键词快捷指令和自然语言查询。
version: 1.0.0
---

# 租赁设备管理系统 - Agent Skill

这是一个为 QClaw/OpenClaw/Agent 提供的租赁系统操作技能，支持通过自然语言或快捷指令操作订单、设备、客户等数据。

## API 基础信息

- **Base URL**: `https://your-domain.com/openapi/v1`
- **认证方式**: Bearer Token (Authorization: Bearer <token>)
- **响应格式**: JSON

---

## 快捷指令（极速响应）

这些接口响应最快，优先使用：

### 1. 今日发货清单
```
GET /shortcuts/today-ship
```
**关键词**: 今日发货、今天发货、待发货、发货清单

**返回示例**:
```json
{
  "code": 0,
  "data": {
    "date": "2026-03-30",
    "count": 5,
    "orders": [
      {
        "order_no": "ORD20260330001",
        "customer": "张三",
        "phone": "138xxxx1234",
        "xianyu_nick": "闲鱼用户ABC",
        "device": "EP7 运动相机",
        "model": "EP7",
        "manage_code": "EP7001",
        "start_date": "03-30",
        "end_date": "04-05",
        "delivery_date": "03-28",
        "delivery_city": "上海",
        "delivery_method": "顺丰快递",
        "is_packed": false,
        "status": "未发货",
        "notes": "备注信息"
      }
    ]
  }
}
```

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

**返回示例**:
```json
{
  "code": 0,
  "data": {
    "count": 2,
    "conflicts": [
      {
        "order_no": "ORD20260330001",
        "device": "EP7001",
        "conflict_with": "ORD20260325002"
      }
    ]
  }
}
```

### 6. 设备状态查询
```
GET /shortcuts/device-status/<manage_code>
```
**关键词**: 设备状态、设备查询、{编号}状态

**示例**: `/shortcuts/device-status/EP7001`

**返回示例**:
```json
{
  "code": 0,
  "data": {
    "name": "EP7 运动相机",
    "model": "EP7",
    "manage_code": "EP7001",
    "status": "在租",
    "location": "上海仓库",
    "current_order": {
      "order_no": "ORD20260330001",
      "customer": "张三",
      "start_date": "03-30",
      "end_date": "04-05"
    }
  }
}
```

### 7. 快速创建订单（自然语言）
```
POST /shortcuts/quick-create
Content-Type: application/json

{"text": "张三 EP7 3月29到4月5日 上海"}
```
**自动解析**: 客户名、型号、日期、城市

**返回示例**:
```json
{
  "code": 0,
  "message": "订单创建成功",
  "data": {
    "order_no": "ORD202603301530451234",
    "customer": "张三",
    "model": "EP7",
    "start_date": "2026-03-29",
    "end_date": "2026-04-05",
    "delivery_city": "上海"
  }
}
```

---

## 智能查询（自然语言）

### 单一入口
```
POST /smart-query
Content-Type: application/json

{"text": "今天要发货的"}
```

**支持的查询类型**:
- **时间查询**: 今天/明天/下周/本周
- **状态查询**: 进行中/未发货/已完成
- **设备查询**: EP7空闲吗/设备状态
- **客户查询**: 张三的订单

**返回示例**:
```json
{
  "code": 0,
  "data": {
    "query": "今天要发货的",
    "count": 5,
    "orders": [...]
  }
}
```

---

## 订单管理 API

### 获取订单列表
```
GET /orders?page=1&page_size=20&status=未发货
```

**状态值**: 未发货、进行中、已完成、已取消

### 获取订单详情
```
GET /orders/<order_id>
```

### 创建订单
```
POST /orders
Content-Type: application/json

{
  "customer_id": 1,
  "device_id": 10,
  "expected_model": "EP7",
  "start_date": "2026-04-01",
  "end_date": "2026-04-07",
  "delivery_city": "上海",
  "delivery_address": "浦东新区xxx"
}
```

### 更新订单
```
PUT /orders/<order_id>
Content-Type: application/json

{
  "delivery_date": "2026-03-30",
  "delivery_method": "顺丰快递"
}
```

**注意**: 修改发货信息会同步到关联订单（同客户+同租期）

### 批量发货
```
POST /orders/batch-ship
Content-Type: application/json

{
  "order_ids": [1, 2, 3],
  "shipments": [
    {"order_id": 1, "manage_code": "EP7001"}
  ]
}
```

---

## 设备管理 API

### 获取设备列表
```
GET /devices?status=在库
```

**状态值**: 在库、在租、维修、丢失

### 获取设备详情
```
GET /devices/<device_id>
```

### 更新设备
```
PUT /devices/<device_id>
Content-Type: application/json

{
  "manage_code": "EP7001",
  "status": "在租",
  "location": "上海仓库"
}
```

**注意**: 修改管理编号会检查是否与现有订单冲突

### 设备可用性检查
```
GET /devices/<device_id>/availability?start_date=2026-04-01&end_date=2026-04-07
```

---

## 客户管理 API

### 获取客户列表
```
GET /customers?search=张三
```

### 创建客户
```
POST /customers
Content-Type: application/json

{
  "customer_name": "李四",
  "phone": "13800138000",
  "address": "北京市朝阳区xxx"
}
```

---

## 关键词映射表

| 用户输入 | 调用接口 |
|---------|---------|
| 今日发货/今天发货/待发货 | GET /shortcuts/today-ship |
| 明日发货/明天发货 | GET /shortcuts/tomorrow-ship |
| 待排单/未排单/排单 | GET /shortcuts/pending |
| 进行中/在租/已发货 | GET /shortcuts/in-progress |
| 冲突/时间冲突 | GET /shortcuts/conflicts |
| {编号}状态/设备{编号} | GET /shortcuts/device-status/{编号} |
| 创建订单 {文本} | POST /shortcuts/quick-create |
| 其他自然语言 | POST /smart-query |

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
- 1001: 参数错误
- 1002: 数据验证失败
- 2001: 记录不存在
- 2003: 设备不存在
- 3001: 权限不足

---

## 使用示例

### 示例 1: 查询今日发货
```
用户: 今天要发哪些货？
QClaw: 调用 GET /shortcuts/today-ship
响应: 今天共有 5 单待发货，分别是...
```

### 示例 2: 快速创建订单
```
用户: 帮我创建一个订单，王五，EP7，4月1号到4月7号，北京
QClaw: 调用 POST /shortcuts/quick-create
       Body: {"text": "王五 EP7 4月1到4月7日 北京"}
响应: 订单创建成功，订单号 ORD20260330xxx
```

### 示例 3: 查设备状态
```
用户: EP7001 这个设备现在什么状态？
QClaw: 调用 GET /shortcuts/device-status/EP7001
响应: EP7001 当前状态：在租，租给张三，4月7日归还
```

### 示例 4: 智能查询
```
用户: 帮我查一下张三下周的订单
QClaw: 调用 POST /smart-query
       Body: {"text": "张三下周的订单"}
响应: 找到张三的 2 个订单...
```

---

## 注意事项

1. **认证**: 所有请求需要携带有效的 Bearer Token
2. **租户隔离**: 通过 Token 自动识别租户，数据自动隔离
3. **关联订单**: 同客户+同租期的订单会同步发货信息
4. **冲突检测**: 分配设备和修改编号时会自动检测时间冲突
