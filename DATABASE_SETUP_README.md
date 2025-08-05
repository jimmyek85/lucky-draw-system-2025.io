# 1602 幸运轮盘数据库设置指南

## 📋 概述

本项目包含了完整的 Supabase 数据库设置文件，用于支持 1602 精酿啤酒幸运轮盘应用。

## 🗂️ 数据库文件说明

### 主要设置文件

1. **`supabase-complete-setup.sql`** - 完整的数据库设置脚本
   - 一次性完成所有数据库配置
   - 包含所有表、视图、函数和初始数据
   - 推荐使用此文件进行全新安装

2. **`enhanced-database-setup.sql`** - 增强版数据库设置
   - 包含详细的表结构和关系
   - 适用于需要了解详细结构的开发者

3. **`fix-remaining-chances.sql`** - 修复抽奖次数字段
   - 用于修复现有数据库中的字段问题
   - 确保 `remaining_chances` 字段正确配置

4. **`update-lottery-config.sql`** - 更新抽奖配置
   - 设置新用户只能免费抽奖一次
   - 更新相关配置参数

## 🚀 快速开始

### 方法一：使用完整设置脚本（推荐）

1. 登录到您的 Supabase 项目
2. 进入 SQL Editor
3. 复制并执行 `supabase-complete-setup.sql` 文件内容
4. 等待执行完成，查看成功消息

### 方法二：分步骤设置

1. 首先执行 `enhanced-database-setup.sql`
2. 然后执行 `fix-remaining-chances.sql`
3. 最后执行 `update-lottery-config.sql`

## 📊 数据库结构

### 主要表格

- **`users`** - 用户信息表
  - 存储用户基本信息
  - 抽奖次数和历史记录
  - 获奖信息

- **`draw_history`** - 抽奖历史表
  - 记录每次抽奖的详细信息
  - 包含用户信息、奖品、时间等

- **`settings`** - 系统设置表
  - 应用配置参数
  - 抽奖规则设置
  - 内容管理

- **`knowledge`** - 知识库表
  - 产品信息
  - 常见问题
  - 公司信息

- **`announcements`** - 公告表
  - 系统公告
  - 活动通知

- **`product_knowledge`** - 产品知识库表
  - 详细的产品信息
  - 分类管理

### 视图和函数

- **`user_stats_view`** - 用户统计视图
- **`draw_stats_view`** - 抽奖统计视图
- **`get_prize_stats()`** - 获取奖品统计
- **`get_user_draw_history()`** - 获取用户抽奖历史
- **`update_user_draw_chances()`** - 更新用户抽奖次数
- **`cleanup_old_data()`** - 清理过期数据
- **`system_health_check()`** - 系统健康检查

## 🔒 安全配置

- 所有表都启用了行级安全 (RLS)
- 配置了适当的安全策略
- 支持匿名用户读取，认证用户写入

## 📡 实时功能

- 所有表都启用了实时订阅
- 支持实时数据同步
- 自动更新时间戳

## ⚙️ 配置参数

### 抽奖配置
- 新用户免费抽奖次数：1次
- 最大累积抽奖次数：可配置
- 奖品概率：可在前端配置

### 内容配置
- 应用名称：1602 Craft Beer
- 活动标题：古晋美食节幸运轮盘
- 联系信息：可在 settings 表中修改

## 🛠️ 维护和管理

### 数据清理
```sql
-- 清理90天前的抽奖历史
SELECT cleanup_old_data(90);
```

### 系统健康检查
```sql
-- 检查系统状态
SELECT * FROM system_health_check();
```

### 用户统计
```sql
-- 查看用户统计
SELECT * FROM user_stats_view;
```

### 抽奖统计
```sql
-- 查看抽奖统计
SELECT * FROM draw_stats_view;
```

## 🔧 故障排除

### 常见问题

1. **权限错误**
   - 确保您有 Supabase 项目的管理员权限
   - 检查 RLS 策略是否正确配置

2. **实时订阅不工作**
   - 确保在 Supabase 控制台中启用了实时功能
   - 检查表是否正确添加到实时发布

3. **函数执行错误**
   - 检查函数参数是否正确
   - 确保相关表和数据存在

### 重置数据库

如果需要重置数据库：

1. 在 Supabase SQL Editor 中删除所有表
2. 重新执行 `supabase-complete-setup.sql`

## 📞 支持

如果遇到问题，请检查：
1. Supabase 项目配置
2. 网络连接
3. SQL 语法错误
4. 权限设置

## 🎯 下一步

数据库设置完成后：
1. 更新前端应用的 Supabase 配置
2. 测试用户注册和抽奖功能
3. 验证实时数据同步
4. 配置生产环境参数

---

**注意：** 在生产环境中使用前，请确保：
- 备份现有数据
- 测试所有功能
- 配置适当的安全策略
- 设置监控和日志记录