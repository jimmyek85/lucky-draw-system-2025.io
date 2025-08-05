# 🚀 快速修复数据库配置

## 问题解决
✅ **已修复的问题：**
- `settings.value` 字段不匹配问题 → 已改为 `settings.content`
- 前端和后端数据库字段统一
- 所有配置加载和保存功能已修复

## 🔧 立即配置数据库

### 步骤 1: 登录 Supabase
1. 访问 [https://supabase.com](https://supabase.com)
2. 登录您的账户
3. 选择您的项目

### 步骤 2: 执行数据库脚本
1. 在 Supabase 控制台，点击左侧 **"SQL Editor"**
2. 点击 **"New query"**
3. 复制粘贴以下完整脚本：

```sql
-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255),
    address TEXT,
    remaining_chances INTEGER DEFAULT 1,
    joindate TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    prizeswon JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建设置表
CREATE TABLE IF NOT EXISTS settings (
    id SERIAL PRIMARY KEY,
    key VARCHAR(255) UNIQUE NOT NULL,
    content JSONB,
    description TEXT,
    category VARCHAR(100) DEFAULT 'general',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建抽奖记录表
CREATE TABLE IF NOT EXISTS draw_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    user_name VARCHAR(255),
    user_phone VARCHAR(20),
    prize_name VARCHAR(255),
    prize_type VARCHAR(100),
    draw_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_claimed BOOLEAN DEFAULT false,
    claim_time TIMESTAMP WITH TIME ZONE,
    notes TEXT
);

-- 创建知识库表
CREATE TABLE IF NOT EXISTS knowledge (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    description TEXT,
    features TEXT,
    price VARCHAR(100),
    image_urls JSONB DEFAULT '[]'::jsonb,
    document_urls JSONB DEFAULT '[]'::jsonb,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建公告表
CREATE TABLE IF NOT EXISTS announcements (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    image_url VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 插入默认配置数据
INSERT INTO settings (key, content, description, category) VALUES
('lottery_config', '{"INITIAL_CHANCES": 1, "SPIN_AGAIN_BONUS": 1, "MAX_ACCUMULATED_CHANCES": 10, "DAILY_FREE_CHANCES": 1, "ENABLE_DAILY_FREE": false, "ALLOW_ADMIN_ADD_CHANCES": true}', '抽奖系统配置', 'lottery'),
('prizes_config', '{"prizes": [{"text": "1602 Mug", "name": "1602 Mug", "percentage": 1, "probability": 0.01, "color": "#FF6B6B"}, {"text": "1602 Pen", "name": "1602 Pen", "percentage": 15, "probability": 0.15, "color": "#4ECDC4"}, {"text": "Cash Voucher RM5", "name": "Cash Voucher RM5", "percentage": 18, "probability": 0.18, "color": "#45B7D1"}, {"text": "Online Voucher RM10", "name": "Online Voucher RM10", "percentage": 7, "probability": 0.07, "color": "#96CEB4"}, {"text": "Online Voucher RM20", "name": "Online Voucher RM20", "percentage": 5, "probability": 0.05, "color": "#FFEAA7"}, {"text": "Free 660ml Bottle", "name": "Free 660ml Bottle", "percentage": 8, "probability": 0.08, "color": "#DDA0DD"}, {"text": "New 330ml Can", "name": "New 330ml Can", "percentage": 12, "probability": 0.12, "color": "#98D8C8"}, {"text": "Cooler Bag", "name": "Cooler Bag", "percentage": 7, "probability": 0.07, "color": "#F7DC6F"}, {"text": "Wine Card", "name": "Wine Card", "percentage": 0, "probability": 0, "color": "#BB8FCE"}, {"text": "Spin Again!", "name": "Spin Again!", "percentage": 9, "probability": 0.09, "color": "#85C1E9"}, {"text": "Thank You", "name": "Thank You", "percentage": 18, "probability": 0.18, "color": "#F8C471"}], "updated_at": "2024-01-01T00:00:00.000Z"}', '奖品配置', 'lottery'),
('terms_conditions', '"1. 每位用户每天可获得1次免费抽奖机会\n2. 中奖后请在7天内联系客服领取奖品\n3. 奖品不可转让或兑换现金\n4. 活动最终解释权归1602手工精酿所有"', '领奖条款', 'content'),
('promotion_content', '"🍺 1602手工精酿优惠套餐\n\n📦 套餐A: 6瓶装 - RM88 (原价RM108)\n📦 套餐B: 12瓶装 - RM168 (原价RM216)\n📦 套餐C: 24瓶装 - RM318 (原价RM432)\n\n✨ 所有套餐均包含免费配送\n✨ 购买任意套餐即可获得额外抽奖机会\n\n📞 订购热线: +60 12-345 6789"', '优惠套餐内容', 'content')
ON CONFLICT (key) DO UPDATE SET
content = EXCLUDED.content,
updated_at = NOW();

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_joindate ON users(joindate);
CREATE INDEX IF NOT EXISTS idx_draw_history_user_id ON draw_history(user_id);
CREATE INDEX IF NOT EXISTS idx_draw_history_draw_time ON draw_history(draw_time);
CREATE INDEX IF NOT EXISTS idx_settings_key ON settings(key);
CREATE INDEX IF NOT EXISTS idx_knowledge_category ON knowledge(category);
CREATE INDEX IF NOT EXISTS idx_announcements_active ON announcements(is_active);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有表创建更新时间触发器
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_settings_updated_at ON settings;
CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_knowledge_updated_at ON knowledge;
CREATE TRIGGER update_knowledge_updated_at BEFORE UPDATE ON knowledge FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_announcements_updated_at ON announcements;
CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 启用行级安全策略 (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE draw_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- 创建允许所有操作的策略（适用于公开应用）
CREATE POLICY "Allow all operations on users" ON users FOR ALL USING (true);
CREATE POLICY "Allow all operations on settings" ON settings FOR ALL USING (true);
CREATE POLICY "Allow all operations on draw_history" ON draw_history FOR ALL USING (true);
CREATE POLICY "Allow all operations on knowledge" ON knowledge FOR ALL USING (true);
CREATE POLICY "Allow all operations on announcements" ON announcements FOR ALL USING (true);

-- 启用实时订阅
ALTER PUBLICATION supabase_realtime ADD TABLE users;
ALTER PUBLICATION supabase_realtime ADD TABLE settings;
ALTER PUBLICATION supabase_realtime ADD TABLE draw_history;
ALTER PUBLICATION supabase_realtime ADD TABLE knowledge;
ALTER PUBLICATION supabase_realtime ADD TABLE announcements;
```

4. 点击 **"Run"** 执行脚本

### 步骤 3: 验证配置
1. 刷新您的 [admin.html](http://localhost:8000/admin.html) 页面
2. 检查以下功能：
   - ✅ 加载抽奖配置
   - ✅ 用户统计
   - ✅ 更新领奖条款
   - ✅ 更新优惠套餐内容

## 🎯 测试系统
访问以下页面验证系统：
- **用户前端**: [http://localhost:8000/index.html](http://localhost:8000/index.html)
- **管理后台**: [http://localhost:8000/admin.html](http://localhost:8000/admin.html)
- **系统检查**: [http://localhost:8000/system-ready-check.html](http://localhost:8000/system-ready-check.html)

## 🆘 如果仍有问题
1. 检查 Supabase 项目 URL 和 API Key 是否正确
2. 确认数据库脚本执行成功
3. 查看浏览器控制台是否有错误信息
4. 确认网络连接正常

---
**✅ 修复完成！现在您的 1602 Lucky Draw 系统应该完全正常运行了。**