# 🚀 Supabase 数据库一键设置指南

## 📋 概述

本指南将帮助您通过一个完整的SQL脚本，一次性完成1602幸运轮盘应用的所有Supabase数据库配置，确保前后端连接完美无缺。

## ⚠️ 重要提醒

**执行前请注意：**
- 此脚本会删除现有的表和数据（如果存在）
- 如果您有重要数据需要保留，请先备份
- 建议在测试环境中先执行一次

## 🔧 执行步骤

### 第一步：登录 Supabase Dashboard

1. 访问 [Supabase Dashboard](https://app.supabase.com/)
2. 登录您的账户
3. 选择您的项目（如果没有项目，请先创建一个）

### 第二步：打开 SQL Editor

1. 在左侧菜单中点击 **"SQL Editor"**
2. 点击 **"New Query"** 创建新查询

### 第三步：复制并执行 SQL 脚本

1. 打开项目中的 `supabase-complete-setup.sql` 文件
2. **复制全部内容**（Ctrl+A 然后 Ctrl+C）
3. **粘贴到 SQL Editor 中**（Ctrl+V）
4. 点击 **"Run"** 按钮执行脚本

### 第四步：验证执行结果

执行完成后，您应该看到类似以下的成功消息：

```
✅ 所有表创建成功
✅ RLS策略配置成功
✅ 实时订阅配置成功
🎉 1602 幸运轮盘应用数据库设置完成！
```

## 📊 脚本包含的功能

### 🗄️ 数据库表结构

1. **users 表** - 用户信息管理
   - 基本信息：姓名、电话、邮箱、地址
   - 参与数据：抽奖次数、参与次数、中奖记录
   - 状态管理：用户状态、推荐码等

2. **settings 表** - 应用设置管理
   - 应用配置：名称、版本、联系信息
   - 活动设置：开始时间、结束时间、奖品池
   - 内容管理：公告、条款等

3. **knowledge 表** - 知识库管理
   - 产品信息：啤酒推荐、公司信息
   - 活动规则：参与规则、常见问题
   - 营销内容：社交媒体链接等

### 🔐 安全配置

- **行级安全策略 (RLS)**：确保数据访问安全
- **权限管理**：为 anon 和 authenticated 角色配置适当权限
- **索引优化**：提高查询性能

### ⚡ 实时功能

- **实时订阅**：支持前后端数据实时同步
- **自动更新时间戳**：自动维护数据更新时间

### 🛠️ 实用功能

- **统计视图**：用户数据统计分析
- **实用函数**：用户查询、参与次数更新、奖品记录等
- **数据维护**：测试数据清理、数据备份等

## 🧪 执行后测试

### 1. 检查表是否创建成功

在 SQL Editor 中执行：

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'settings', 'knowledge');
```

应该返回三个表名。

### 2. 检查初始数据

```sql
-- 检查设置数据
SELECT key, content FROM settings LIMIT 5;

-- 检查知识库数据
SELECT key, title FROM knowledge LIMIT 5;
```

### 3. 测试用户插入

```sql
-- 插入测试用户
INSERT INTO users (name, phone, email, address) 
VALUES ('测试用户', '+60123456789', 'test@example.com', '测试地址');

-- 查询测试用户
SELECT * FROM users WHERE phone = '+60123456789';

-- 清理测试用户
DELETE FROM users WHERE phone = '+60123456789';
```

## 🔄 前端应用配置

执行SQL脚本后，确保您的前端应用配置正确：

### 1. 检查 `supabase-config.js`

确保以下配置正确：

```javascript
const SUPABASE_CONFIG = {
    SUPABASE_URL: 'https://your-project-id.supabase.co',
    SUPABASE_ANON_KEY: 'your-anon-key-here',
    TABLES: {
        USERS: 'users',
        SETTINGS: 'settings', 
        KNOWLEDGE: 'knowledge'
    }
};
```

### 2. 测试前端连接

访问以下测试页面验证连接：

- `http://127.0.0.1:8000/test-supabase-connection.html`
- `http://127.0.0.1:8000/debug-connection.html`
- `http://127.0.0.1:8000/connection-fix-solution.html`

## 🎯 常见问题解决

### Q1: 执行脚本时出现权限错误

**解决方案：**
- 确保您是项目的所有者或管理员
- 检查您的 Supabase 计划是否支持所有功能

### Q2: 实时订阅不工作

**解决方案：**
```sql
-- 手动添加表到实时订阅
ALTER PUBLICATION supabase_realtime ADD TABLE users;
ALTER PUBLICATION supabase_realtime ADD TABLE settings;
ALTER PUBLICATION supabase_realtime ADD TABLE knowledge;
```

### Q3: 前端仍然无法连接

**解决方案：**
1. 检查 API 密钥是否正确
2. 确认项目 URL 是否正确
3. 验证 RLS 策略是否正确应用
4. 使用浏览器开发者工具查看网络请求

### Q4: 需要保留现有数据

**解决方案：**
在执行脚本前，注释掉以下行：
```sql
-- DROP TABLE IF EXISTS users CASCADE;
-- DROP TABLE IF EXISTS settings CASCADE;
-- DROP TABLE IF EXISTS knowledge CASCADE;
```

## 📞 技术支持

如果遇到问题：

1. **检查执行日志**：查看 SQL Editor 中的错误信息
2. **使用诊断工具**：运行 `connection-fix-solution.html` 进行诊断
3. **查看文档**：参考 [Supabase 官方文档](https://supabase.com/docs)
4. **联系支持**：如需进一步帮助，请提供错误信息和执行日志

## ✅ 完成检查清单

执行完成后，请确认以下项目：

- [ ] SQL 脚本执行无错误
- [ ] 三个表（users, settings, knowledge）创建成功
- [ ] RLS 策略配置正确
- [ ] 实时订阅启用
- [ ] 初始数据插入成功
- [ ] 前端应用可以连接数据库
- [ ] 用户注册功能正常工作
- [ ] 数据可以正确保存和读取

## 🎉 恭喜！

完成以上步骤后，您的1602幸运轮盘应用数据库就完全配置好了！现在您可以：

- ✅ 用户可以正常注册和参与
- ✅ 数据实时同步到云端
- ✅ 管理员可以查看和管理数据
- ✅ 应用具有完整的离线保护机制
- ✅ 所有功能都能稳定运行

**祝您的应用运行顺利！** 🚀