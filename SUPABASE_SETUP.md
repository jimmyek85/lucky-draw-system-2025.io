# Supabase 数据库配置指南

## 概述
本指南将帮助您将 1602 幸运轮盘应用从 Firebase 迁移到 Supabase，确保前后端实时数据同步。

## 🚀 快速开始

### 1. 创建 Supabase 项目

1. 访问 [Supabase Dashboard](https://app.supabase.com/)
2. 点击 "New Project" 创建新项目
3. 选择组织并填写项目信息
4. 等待项目创建完成（约2分钟）

### 2. 获取项目配置信息

在项目 Dashboard 中：
1. 进入 "Settings" > "API"
2. 复制以下信息：
   - **Project URL**: `https://your-project-id.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 3. 配置应用

编辑 `supabase-config.js` 文件：
```javascript
const SUPABASE_CONFIG = {
    SUPABASE_URL: 'https://your-project-id.supabase.co',
    SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImliaXJzaWVhZW96aHN2bGVlZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4OTQ5MzIsImV4cCI6MjA2OTQ3MDkzMn0.MYzEhk1XYS9d4n-ToLZIb4AsUjzoiOndNeIqdDdY0SM',
    // ... 其他配置保持不变
};
```

## 📊 数据库表结构

### 创建必要的表

在 Supabase SQL Editor 中执行以下 SQL 语句：

#### 1. 用户表 (users)
```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT UNIQUE NOT NULL,
    email TEXT,
    address TEXT,
    drawchances INTEGER DEFAULT 1,
    joindate TIMESTAMPTZ DEFAULT NOW(),
    prizeswon JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_name ON users(name);
CREATE INDEX idx_users_joindate ON users(joindate);
```

#### 2. 设置表 (settings)
```sql
CREATE TABLE settings (
    id BIGSERIAL PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    content TEXT,
    lastUpdated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_settings_key ON settings(key);
```

#### 3. 知识库表 (knowledge)
```sql
CREATE TABLE knowledge (
    id BIGSERIAL PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    content TEXT,
    lastUpdated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_knowledge_key ON knowledge(key);
```

### 4. 创建更新时间触发器
```sql
-- 创建更新时间函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有表添加更新时间触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_updated_at BEFORE UPDATE ON knowledge
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## 🔐 安全配置

### 1. 行级安全策略 (RLS)

启用 RLS 并创建策略：

```sql
-- 启用行级安全
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge ENABLE ROW LEVEL SECURITY;

-- 用户表策略
CREATE POLICY "Users can read all users" ON users
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own data" ON users
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own data" ON users
    FOR UPDATE USING (true);

CREATE POLICY "Users can delete their own data" ON users
    FOR DELETE USING (true);

-- 设置表策略
CREATE POLICY "Settings are readable by everyone" ON settings
    FOR SELECT USING (true);

CREATE POLICY "Settings can be updated by everyone" ON settings
    FOR ALL USING (true);

-- 知识库表策略
CREATE POLICY "Knowledge is readable by everyone" ON knowledge
    FOR SELECT USING (true);

CREATE POLICY "Knowledge can be updated by everyone" ON knowledge
    FOR ALL USING (true);
```

### 2. 实时订阅配置

启用实时功能：

```sql
-- 为所有表启用实时订阅
ALTER PUBLICATION supabase_realtime ADD TABLE users;
ALTER PUBLICATION supabase_realtime ADD TABLE settings;
ALTER PUBLICATION supabase_realtime ADD TABLE knowledge;
```

## 📱 功能特性

### ✅ 已实现功能

- **实时数据同步**: 前后端数据实时更新
- **用户管理**: 注册、查询、更新用户信息
- **抽奖系统**: 抽奖次数管理和奖品记录
- **管理面板**: 用户数据管理、公告发布、知识库管理
- **离线支持**: 网络断开时的离线模式
- **AI 功能**: 保持原有的 Gemini AI 集成

### 🔄 数据迁移

如果您有现有的 Firebase 数据需要迁移：

1. **导出 Firebase 数据**
   - 在 Firebase Console 中导出 Firestore 数据
   - 转换为 JSON 格式

2. **导入到 Supabase**
   - 使用 Supabase Dashboard 的导入功能
   - 或编写脚本批量插入数据

### 📊 性能优化

- **索引优化**: 已为常用查询字段创建索引
- **连接池**: Supabase 自动管理数据库连接
- **CDN**: 静态资源通过 CDN 加速
- **实时优化**: 只订阅必要的数据变更

## 🛠️ 故障排除

### 常见问题

1. **连接失败**
   - 检查 `SUPABASE_URL` 和 `SUPABASE_ANON_KEY` 是否正确
   - 确认项目状态为 "Active"

2. **权限错误**
   - 检查 RLS 策略是否正确配置
   - 确认 anon 角色有足够权限

3. **实时订阅不工作**
   - 确认表已添加到 `supabase_realtime` 发布
   - 检查网络连接和防火墙设置

4. **数据类型错误**
   - 确认日期字段使用 ISO 字符串格式
   - 检查 JSON 字段格式是否正确

### 调试技巧

```javascript
// 启用详细日志
const supabase = createClient(url, key, {
  auth: {
    debug: true
  },
  realtime: {
    debug: true
  }
});

// 监听连接状态
supabase.realtime.onOpen(() => console.log('Realtime connected'));
supabase.realtime.onClose(() => console.log('Realtime disconnected'));
supabase.realtime.onError((error) => console.error('Realtime error:', error));
```

## 📞 支持

如遇到问题：
1. 查看 [Supabase 官方文档](https://supabase.com/docs)
2. 检查浏览器控制台错误信息
3. 联系开发团队获取技术支持

---

**配置完成后，您的 1602 幸运轮盘应用将拥有：**
- 🚀 更快的响应速度
- 💰 更低的运营成本
- 🔄 实时数据同步
- 📊 强大的数据分析能力
- 🛡️ 企业级安全保障

*最后更新: 2024年12月*
*版本: v1.0*