-- Enhanced Database Setup for Lucky Draw System
-- 增强版幸运轮盘系统数据库设置

-- 1. 更新 users 表，添加奖品记录和额外机会字段
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS prizes_won JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS extra_chances INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_spins INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_spin_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS remaining_chances INTEGER DEFAULT 3,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS draw_count INTEGER DEFAULT 0;

-- 同步现有的 drawchances 字段到 remaining_chances
UPDATE users SET remaining_chances = drawchances WHERE remaining_chances IS NULL;
UPDATE users SET draw_count = 0 WHERE draw_count IS NULL;

-- 2. 创建公告栏表 (announcements)
CREATE TABLE IF NOT EXISTS announcements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

-- 3. 创建产品知识库表 (product_knowledge)
CREATE TABLE IF NOT EXISTS product_knowledge (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    content TEXT NOT NULL,
    image_urls JSONB DEFAULT '[]'::jsonb,
    document_urls JSONB DEFAULT '[]'::jsonb,
    tags JSONB DEFAULT '[]'::jsonb,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 创建文件上传表 (file_uploads)
CREATE TABLE IF NOT EXISTS file_uploads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    file_size INTEGER NOT NULL,
    file_url TEXT NOT NULL,
    upload_type VARCHAR(50) NOT NULL, -- 'announcement', 'product', 'general'
    reference_id UUID,
    uploaded_by VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 创建抽奖历史表 (draw_history)
CREATE TABLE IF NOT EXISTS draw_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    user_phone VARCHAR(20) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    prize_won VARCHAR(255) NOT NULL,
    draw_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    remaining_chances_after INTEGER DEFAULT 0,
    is_claimed BOOLEAN DEFAULT false,
    claimed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT
);

-- 6. 创建系统统计表 (system_stats)
CREATE TABLE IF NOT EXISTS system_stats (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    stat_date DATE DEFAULT CURRENT_DATE,
    total_users INTEGER DEFAULT 0,
    daily_registrations INTEGER DEFAULT 0,
    daily_spins INTEGER DEFAULT 0,
    total_spins INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(stat_date)
);

-- 7. 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_name ON users(name);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_announcements_active ON announcements(is_active, priority);
CREATE INDEX IF NOT EXISTS idx_product_knowledge_active ON product_knowledge(is_active, category);
CREATE INDEX IF NOT EXISTS idx_draw_history_user_id ON draw_history(user_id);
CREATE INDEX IF NOT EXISTS idx_draw_history_date ON draw_history(draw_date);
CREATE INDEX IF NOT EXISTS idx_draw_history_user_phone ON draw_history(user_phone);
CREATE INDEX IF NOT EXISTS idx_system_stats_date ON system_stats(stat_date);

-- 8. 创建触发器函数来自动更新统计数据
CREATE OR REPLACE FUNCTION update_system_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- 更新或插入今日统计
    INSERT INTO system_stats (stat_date, total_users, daily_registrations, daily_spins, total_spins)
    VALUES (
        CURRENT_DATE,
        (SELECT COUNT(*) FROM users),
        (SELECT COUNT(*) FROM users WHERE DATE(created_at) = CURRENT_DATE),
        (SELECT COUNT(*) FROM draw_history WHERE DATE(draw_date) = CURRENT_DATE),
        (SELECT COUNT(*) FROM draw_history)
    )
    ON CONFLICT (stat_date) 
    DO UPDATE SET
        total_users = EXCLUDED.total_users,
        daily_registrations = EXCLUDED.daily_registrations,
        daily_spins = EXCLUDED.daily_spins,
        total_spins = EXCLUDED.total_spins,
        updated_at = NOW();
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 9. 创建触发器
DROP TRIGGER IF EXISTS trigger_update_stats_on_user_insert ON users;
CREATE TRIGGER trigger_update_stats_on_user_insert
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_system_stats();

DROP TRIGGER IF EXISTS trigger_update_stats_on_draw_insert ON draw_history;
CREATE TRIGGER trigger_update_stats_on_draw_insert
    AFTER INSERT ON draw_history
    FOR EACH ROW
    EXECUTE FUNCTION update_system_stats();

-- 10. 创建更新时间戳的触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 11. 为相关表添加更新时间戳触发器
DROP TRIGGER IF EXISTS trigger_announcements_updated_at ON announcements;
CREATE TRIGGER trigger_announcements_updated_at
    BEFORE UPDATE ON announcements
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_product_knowledge_updated_at ON product_knowledge;
CREATE TRIGGER trigger_product_knowledge_updated_at
    BEFORE UPDATE ON product_knowledge
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 12. 插入一些示例数据
INSERT INTO announcements (title, content, priority, is_active) VALUES
('欢迎来到1602幸运轮盘！', '感谢您参与我们的幸运轮盘活动！每次注册可获得1次免费抽奖机会。', 1, true),
('新品上市通知', '我们推出了全新的精酿啤酒系列，欢迎品尝！', 2, true)
ON CONFLICT DO NOTHING;

INSERT INTO product_knowledge (title, description, category, content, tags) VALUES
('1602 Pale Ale', '清爽果香型精酿啤酒', 'beer', '1602 Pale Ale 是我们的招牌产品，采用优质啤酒花酿造，口感清爽，带有淡淡的果香味。酒精度数适中，适合各种场合饮用。', '["pale ale", "果香", "清爽", "精酿"]'),
('1602 Extra Dark', '浓郁麦芽型黑啤酒', 'beer', '1602 Extra Dark 是一款浓郁的黑啤酒，采用特殊烘焙麦芽酿造，口感醇厚，带有巧克力和咖啡的香味。适合喜欢浓郁口感的啤酒爱好者。', '["黑啤", "浓郁", "麦芽", "巧克力味"]'),
('1602 Lager', '经典清爽拉格啤酒', 'beer', '1602 Lager 是一款经典的拉格啤酒，口感清脆爽口，泡沫丰富持久。采用传统酿造工艺，是聚会和日常饮用的完美选择。', '["拉格", "清脆", "经典", "聚会"]')
ON CONFLICT DO NOTHING;

-- 13. 启用行级安全策略 (RLS)
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_knowledge ENABLE ROW LEVEL SECURITY;
ALTER TABLE file_uploads ENABLE ROW LEVEL SECURITY;
ALTER TABLE draw_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_stats ENABLE ROW LEVEL SECURITY;

-- 14. 创建安全策略（允许匿名读取，但需要认证才能写入）
CREATE POLICY "Allow anonymous read access" ON announcements FOR SELECT USING (true);
CREATE POLICY "Allow anonymous read access" ON product_knowledge FOR SELECT USING (true);
CREATE POLICY "Allow anonymous read access" ON draw_history FOR SELECT USING (true);
CREATE POLICY "Allow anonymous read access" ON system_stats FOR SELECT USING (true);

-- 15. 创建视图来简化查询
CREATE OR REPLACE VIEW user_stats_view AS
SELECT 
    u.id,
    u.name,
    u.phone,
    u.email,
    u.created_at,
    u.is_active,
    u.draw_count,
    u.extra_chances,
    u.total_spins,
    u.last_spin_date,
    u.prizes_won,
    COALESCE(dh.total_draws, 0) as actual_total_draws,
    COALESCE(dh.last_draw_date, NULL) as last_draw_date
FROM users u
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(*) as total_draws,
        MAX(spin_date) as last_draw_date
    FROM draw_history
    GROUP BY user_id
) dh ON u.id = dh.user_id;

-- 完成设置
SELECT 'Enhanced database setup completed successfully!' as status;