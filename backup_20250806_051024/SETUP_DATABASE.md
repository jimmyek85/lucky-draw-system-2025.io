# 🚀 1602 Lucky Draw - 数据库快速设置

## 📋 设置步骤

### 1. 登录 Supabase 控制台
1. 访问 [Supabase Dashboard](https://supabase.com/dashboard)
2. 登录您的账户
3. 选择您的项目

### 2. 执行数据库初始化
1. 在左侧菜单中点击 **SQL Editor**
2. 点击 **New Query** 创建新查询
3. 复制并粘贴以下 SQL 代码：

```sql
-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    company VARCHAR(200),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建抽奖记录表
CREATE TABLE IF NOT EXISTS draw_records (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    prize_name VARCHAR(200) NOT NULL,
    prize_type VARCHAR(50) NOT NULL,
    draw_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_claimed BOOLEAN DEFAULT FALSE
);

-- 创建系统设置表
CREATE TABLE IF NOT EXISTS settings (
    id BIGSERIAL PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建知识库表
CREATE TABLE IF NOT EXISTS knowledge (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建公告表
CREATE TABLE IF NOT EXISTS announcements (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建奖品表
CREATE TABLE IF NOT EXISTS prizes (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(50) NOT NULL,
    probability DECIMAL(5,4) NOT NULL,
    total_count INTEGER DEFAULT -1,
    remaining_count INTEGER DEFAULT -1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 插入默认奖品数据
INSERT INTO prizes (name, type, probability, total_count, remaining_count, is_active) VALUES
('一等奖 - iPhone 15 Pro', 'physical', 0.0001, 1, 1, true),
('二等奖 - iPad Air', 'physical', 0.0005, 3, 3, true),
('三等奖 - AirPods Pro', 'physical', 0.001, 10, 10, true),
('四等奖 - 100元京东卡', 'virtual', 0.01, 50, 50, true),
('五等奖 - 50元京东卡', 'virtual', 0.05, 100, 100, true),
('六等奖 - 20元京东卡', 'virtual', 0.1, 200, 200, true),
('谢谢参与', 'none', 0.8384, -1, -1, true)
ON CONFLICT DO NOTHING;

-- 插入默认系统设置
INSERT INTO settings (key, value, description) VALUES
('max_draws_per_user', '3', '每个用户最大抽奖次数'),
('draw_start_time', '2024-01-01 00:00:00', '抽奖开始时间'),
('draw_end_time', '2024-12-31 23:59:59', '抽奖结束时间'),
('system_status', 'active', '系统状态'),
('welcome_message', '欢迎参加1602幸运抽奖！', '欢迎消息')
ON CONFLICT (key) DO NOTHING;

-- 插入默认知识库内容
INSERT INTO knowledge (title, content, category, is_active) VALUES
('如何参与抽奖', '1. 填写个人信息注册\n2. 点击抽奖按钮\n3. 查看抽奖结果\n4. 联系客服领取奖品', '使用指南', true),
('奖品说明', '本次抽奖活动提供多种奖品，包括实物奖品和虚拟奖品。所有奖品均为正品，请放心参与。', '奖品信息', true),
('联系方式', '客服电话：400-1602-1602\n客服邮箱：service@1602.com\n工作时间：周一至周五 9:00-18:00', '联系我们', true)
ON CONFLICT DO NOTHING;

-- 插入默认公告
INSERT INTO announcements (title, content, is_active) VALUES
('抽奖活动正式开始', '1602幸运抽奖活动现已正式开始，欢迎大家踊跃参与！', true),
('奖品发放说明', '中奖用户请在7个工作日内联系客服领取奖品，逾期视为自动放弃。', true)
ON CONFLICT DO NOTHING;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_draw_records_user_id ON draw_records(user_id);
CREATE INDEX IF NOT EXISTS idx_draw_records_draw_time ON draw_records(draw_time);
CREATE INDEX IF NOT EXISTS idx_settings_key ON settings(key);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为相关表创建更新时间触发器
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_settings_updated_at ON settings;
CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_knowledge_updated_at ON knowledge;
CREATE TRIGGER update_knowledge_updated_at BEFORE UPDATE ON knowledge FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_announcements_updated_at ON announcements;
CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_prizes_updated_at ON prizes;
CREATE TRIGGER update_prizes_updated_at BEFORE UPDATE ON prizes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 启用行级安全策略 (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE draw_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE prizes ENABLE ROW LEVEL SECURITY;

-- 创建基本的 RLS 策略（允许匿名用户读取和插入）
CREATE POLICY "Allow anonymous access" ON users FOR ALL USING (true);
CREATE POLICY "Allow anonymous access" ON draw_records FOR ALL USING (true);
CREATE POLICY "Allow anonymous access" ON settings FOR SELECT USING (true);
CREATE POLICY "Allow anonymous access" ON knowledge FOR SELECT USING (true);
CREATE POLICY "Allow anonymous access" ON announcements FOR SELECT USING (true);
CREATE POLICY "Allow anonymous access" ON prizes FOR SELECT USING (true);
```

4. 点击 **Run** 按钮执行 SQL
5. 确认所有语句都成功执行

### 3. 验证数据库设置
1. 在 SQL Editor 中运行以下查询验证：
```sql
-- 检查表是否创建成功
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 检查奖品数据
SELECT * FROM prizes;

-- 检查系统设置
SELECT * FROM settings;
```

### 4. 测试系统功能
1. 打开 [一键测试页面](http://localhost:8000/one-click-test.html)
2. 点击 **🚀 运行所有测试** 按钮
3. 查看测试结果，确保所有项目都通过

## 🔧 故障排除

### 如果遇到权限错误：
1. 确保您是项目的所有者或管理员
2. 检查 RLS 策略是否正确设置
3. 尝试在 Supabase Dashboard 的 Authentication 中禁用 RLS（仅用于测试）

### 如果遇到连接错误：
1. 检查 `supabase-config.js` 中的配置是否正确
2. 确认 Supabase 项目 URL 和 API Key 是否有效
3. 检查网络连接是否正常

### 如果测试仍然失败：
1. 查看浏览器控制台的详细错误信息
2. 检查 Supabase Dashboard 中的 Logs 页面
3. 确认所有表都已正确创建

## 🎯 完成后的下一步
1. 访问 [用户前端](http://localhost:8000/index.html) 测试抽奖功能
2. 访问 [管理后台](http://localhost:8000/admin.html) 查看数据统计
3. 使用 [系统检查](http://localhost:8000/system-ready-check.html) 进行全面验证

---

**注意：** 这是一个演示系统，在生产环境中请确保：
- 使用更严格的 RLS 策略
- 配置适当的用户认证
- 设置数据备份策略
- 监控系统性能和安全性