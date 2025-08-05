-- 1602 Lucky Draw 数据库初始化脚本
-- 请在 Supabase SQL 编辑器中运行此脚本

-- 1. 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    company VARCHAR(100),
    position VARCHAR(100),
    registration_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    total_draws INTEGER DEFAULT 0,
    remaining_chances INTEGER DEFAULT 3,
    is_active BOOLEAN DEFAULT true,
    language VARCHAR(10) DEFAULT 'zh',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 创建抽奖记录表
CREATE TABLE IF NOT EXISTS draw_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    prize_type VARCHAR(50) NOT NULL,
    prize_name VARCHAR(200) NOT NULL,
    prize_value DECIMAL(10,2),
    draw_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_claimed BOOLEAN DEFAULT false,
    claim_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 创建系统设置表
CREATE TABLE IF NOT EXISTS settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    category VARCHAR(50) DEFAULT 'general',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 创建知识库表（AI 啤酒推荐）
CREATE TABLE IF NOT EXISTS knowledge (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    tags TEXT[],
    language VARCHAR(10) DEFAULT 'zh',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 创建公告表
CREATE TABLE IF NOT EXISTS announcements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'info', -- info, warning, success, error
    is_active BOOLEAN DEFAULT true,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. 创建奖品配置表
CREATE TABLE IF NOT EXISTS prizes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(50) NOT NULL, -- discount, gift, points, special
    value DECIMAL(10,2),
    probability DECIMAL(5,4) NOT NULL, -- 0.0001 to 1.0000
    description TEXT,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    stock_quantity INTEGER DEFAULT -1, -- -1 表示无限库存
    used_quantity INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. 插入默认系统设置
INSERT INTO settings (key, value, description, category) VALUES
('max_daily_draws', '3', '每日最大抽奖次数', 'draw'),
('registration_required', 'true', '是否需要注册才能抽奖', 'user'),
('system_maintenance', 'false', '系统维护模式', 'system'),
('welcome_message_zh', '欢迎参加1602幸运抽奖！', '中文欢迎消息', 'ui'),
('welcome_message_en', 'Welcome to 1602 Lucky Draw!', '英文欢迎消息', 'ui'),
('company_name', '1602', '公司名称', 'branding'),
('support_email', 'jimmyyekhocksing@gmail.com', '支持邮箱', 'contact'),
('ai_beer_enabled', 'true', '启用AI啤酒推荐', 'features'),
('realtime_updates', 'true', '启用实时更新', 'features'),
('offline_mode', 'true', '启用离线模式', 'features')
ON CONFLICT (key) DO NOTHING;

-- 8. 插入默认奖品配置
INSERT INTO prizes (name, type, value, probability, description) VALUES
('10% 折扣券', 'discount', 10.00, 0.3000, '享受10%的优惠折扣'),
('20% 折扣券', 'discount', 20.00, 0.2000, '享受20%的优惠折扣'),
('30% 折扣券', 'discount', 30.00, 0.1000, '享受30%的优惠折扣'),
('免费啤酒一杯', 'gift', 0.00, 0.1500, '免费享用精选啤酒一杯'),
('精美礼品', 'gift', 0.00, 0.0800, '获得精美纪念礼品'),
('积分奖励', 'points', 100.00, 0.1500, '获得100积分奖励'),
('特别大奖', 'special', 0.00, 0.0200, '恭喜获得特别大奖！')
ON CONFLICT DO NOTHING;

-- 9. 插入默认知识库内容（AI 啤酒推荐）
INSERT INTO knowledge (category, title, content, tags, language) VALUES
('beer_types', 'IPA 印度淡色艾尔', 'IPA是一种酒花味浓郁的啤酒，具有独特的苦味和香气。适合喜欢浓烈口感的人群。', ARRAY['IPA', '苦味', '酒花'], 'zh'),
('beer_types', 'Lager 拉格啤酒', 'Lager是世界上最受欢迎的啤酒类型，口感清爽，适合大多数人群。', ARRAY['拉格', '清爽', '经典'], 'zh'),
('beer_types', 'Stout 世涛啤酒', 'Stout是一种深色啤酒，具有浓郁的咖啡和巧克力风味。', ARRAY['世涛', '深色', '咖啡味'], 'zh'),
('beer_pairing', '啤酒与食物搭配', 'IPA适合搭配辛辣食物，Lager适合搭配海鲜，Stout适合搭配甜点。', ARRAY['搭配', '美食'], 'zh'),
('brewing', '啤酒酿造工艺', '啤酒酿造包括麦芽制备、糖化、发酵等关键步骤。', ARRAY['酿造', '工艺'], 'zh'),
('history', '啤酒历史', '啤酒是人类最古老的酒精饮料之一，有着悠久的历史传统。', ARRAY['历史', '传统'], 'zh')
ON CONFLICT DO NOTHING;

-- 10. 插入默认公告
INSERT INTO announcements (title, content, type) VALUES
('欢迎参加1602幸运抽奖', '感谢您参加我们的幸运抽奖活动！每人每天有3次抽奖机会，祝您好运！', 'info'),
('活动规则说明', '请确保填写真实信息以便领奖。奖品有效期为30天，请及时使用。', 'warning')
ON CONFLICT DO NOTHING;

-- 11. 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_registration_time ON users(registration_time);
CREATE INDEX IF NOT EXISTS idx_draw_records_user_id ON draw_records(user_id);
CREATE INDEX IF NOT EXISTS idx_draw_records_draw_time ON draw_records(draw_time);
CREATE INDEX IF NOT EXISTS idx_settings_key ON settings(key);
CREATE INDEX IF NOT EXISTS idx_knowledge_category ON knowledge(category);
CREATE INDEX IF NOT EXISTS idx_announcements_is_active ON announcements(is_active);
CREATE INDEX IF NOT EXISTS idx_prizes_is_active ON prizes(is_active);

-- 12. 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 13. 为相关表创建更新时间触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_updated_at BEFORE UPDATE ON knowledge
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prizes_updated_at BEFORE UPDATE ON prizes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 14. 启用行级安全策略 (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE draw_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE prizes ENABLE ROW LEVEL SECURITY;

-- 15. 创建基础安全策略（允许匿名用户读取公共数据）
-- 用户表：允许插入新用户，允许用户查看和更新自己的数据
CREATE POLICY "Allow anonymous insert users" ON users
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow users to view own data" ON users
    FOR SELECT USING (true);

CREATE POLICY "Allow users to update own data" ON users
    FOR UPDATE USING (true);

-- 抽奖记录：允许插入，允许查看自己的记录
CREATE POLICY "Allow insert draw records" ON draw_records
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow view own draw records" ON draw_records
    FOR SELECT USING (true);

-- 设置表：允许读取
CREATE POLICY "Allow read settings" ON settings
    FOR SELECT USING (true);

-- 知识库：允许读取
CREATE POLICY "Allow read knowledge" ON knowledge
    FOR SELECT USING (is_active = true);

-- 公告：允许读取活跃公告
CREATE POLICY "Allow read active announcements" ON announcements
    FOR SELECT USING (is_active = true);

-- 奖品：允许读取活跃奖品
CREATE POLICY "Allow read active prizes" ON prizes
    FOR SELECT USING (is_active = true);

-- 完成提示
SELECT 'Database setup completed successfully! 数据库初始化完成！' as status;