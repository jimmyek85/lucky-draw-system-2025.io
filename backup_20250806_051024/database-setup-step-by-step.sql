-- =====================================================
-- 1602 幸运轮盘应用 - 分步数据库设置脚本
-- 请按顺序逐步执行每个部分
-- =====================================================

-- =====================================================
-- 步骤 1: 清理现有结构（可选，如果是全新安装可跳过）
-- =====================================================

-- 删除现有的 RLS 策略
DROP POLICY IF EXISTS "Users can read all users" ON users;
DROP POLICY IF EXISTS "Users can insert their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can delete their own data" ON users;
DROP POLICY IF EXISTS "Settings are readable by everyone" ON settings;
DROP POLICY IF EXISTS "Settings can be updated by everyone" ON settings;
DROP POLICY IF EXISTS "Knowledge is readable by everyone" ON knowledge;
DROP POLICY IF EXISTS "Knowledge can be updated by everyone" ON knowledge;
DROP POLICY IF EXISTS "Allow all operations on users" ON users;
DROP POLICY IF EXISTS "Allow all operations on settings" ON settings;
DROP POLICY IF EXISTS "Allow all operations on knowledge" ON knowledge;
DROP POLICY IF EXISTS "Allow all operations on draw_history" ON draw_history;
DROP POLICY IF EXISTS "Allow all operations on announcements" ON announcements;
DROP POLICY IF EXISTS "Allow all operations on product_knowledge" ON product_knowledge;

-- 删除现有的触发器
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP TRIGGER IF EXISTS update_settings_updated_at ON settings;
DROP TRIGGER IF EXISTS update_knowledge_updated_at ON knowledge;
DROP TRIGGER IF EXISTS update_draw_history_updated_at ON draw_history;
DROP TRIGGER IF EXISTS update_announcements_updated_at ON announcements;
DROP TRIGGER IF EXISTS update_product_knowledge_updated_at ON product_knowledge;

-- 删除现有的视图
DROP VIEW IF EXISTS user_stats_view;
DROP VIEW IF EXISTS draw_stats_view;

-- 删除现有的函数
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP FUNCTION IF EXISTS get_prize_stats();
DROP FUNCTION IF EXISTS get_user_draw_history(TEXT);
DROP FUNCTION IF EXISTS update_user_draw_chances(TEXT, INTEGER);
DROP FUNCTION IF EXISTS cleanup_old_data();
DROP FUNCTION IF EXISTS system_health_check();

-- 删除现有的表（注意：这会删除所有数据！）
DROP TABLE IF EXISTS draw_history CASCADE;
DROP TABLE IF EXISTS announcements CASCADE;
DROP TABLE IF EXISTS product_knowledge CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS settings CASCADE;
DROP TABLE IF EXISTS knowledge CASCADE;

SELECT 'Step 1 completed: Cleanup finished' as status;

-- =====================================================
-- 步骤 2: 创建基础表结构
-- =====================================================

-- 创建用户表 (users)
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT UNIQUE NOT NULL,
    email TEXT,
    address TEXT,
    drawchances INTEGER DEFAULT 1,
    remaining_chances INTEGER DEFAULT 1,
    draw_count INTEGER DEFAULT 0,
    last_draw_date TIMESTAMPTZ,
    participation_count INTEGER DEFAULT 1,
    joindate TIMESTAMPTZ DEFAULT NOW(),
    last_participation TIMESTAMPTZ DEFAULT NOW(),
    prizeswon JSONB DEFAULT '[]'::jsonb,
    prizes_won JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'active',
    notes TEXT,
    referral_code TEXT,
    referred_by TEXT,
    is_active BOOLEAN DEFAULT true
);

-- 创建设置表 (settings)
CREATE TABLE settings (
    id BIGSERIAL PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    content TEXT,
    description TEXT,
    category TEXT DEFAULT 'general',
    is_active BOOLEAN DEFAULT true,
    lastUpdated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建知识库表 (knowledge)
CREATE TABLE knowledge (
    id BIGSERIAL PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    content TEXT,
    title TEXT,
    category TEXT DEFAULT 'general',
    tags TEXT[],
    is_published BOOLEAN DEFAULT true,
    lastUpdated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建抽奖历史表 (draw_history)
CREATE TABLE draw_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    user_phone TEXT NOT NULL,
    user_name TEXT NOT NULL,
    prize_won TEXT NOT NULL,
    draw_date TIMESTAMPTZ DEFAULT NOW(),
    remaining_chances_after INTEGER DEFAULT 0,
    is_claimed BOOLEAN DEFAULT false,
    claimed_at TIMESTAMPTZ,
    notes TEXT
);

-- 创建公告表 (announcements)
CREATE TABLE announcements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- 创建产品知识库表 (product_knowledge)
CREATE TABLE product_knowledge (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'general',
    content TEXT NOT NULL,
    image_urls JSONB DEFAULT '[]'::jsonb,
    document_urls JSONB DEFAULT '[]'::jsonb,
    tags JSONB DEFAULT '[]'::jsonb,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

SELECT 'Step 2 completed: Tables created' as status;

-- =====================================================
-- 步骤 3: 创建索引
-- =====================================================

-- 用户表索引
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_name ON users(name);
CREATE INDEX idx_users_joindate ON users(joindate);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_participation_count ON users(participation_count);
CREATE INDEX idx_users_remaining_chances ON users(remaining_chances);
CREATE INDEX idx_users_draw_count ON users(draw_count);

-- 设置表索引
CREATE INDEX idx_settings_key ON settings(key);
CREATE INDEX idx_settings_category ON settings(category);
CREATE INDEX idx_settings_is_active ON settings(is_active);

-- 知识库表索引
CREATE INDEX idx_knowledge_key ON knowledge(key);
CREATE INDEX idx_knowledge_category ON knowledge(category);
CREATE INDEX idx_knowledge_is_published ON knowledge(is_published);
CREATE INDEX idx_knowledge_tags ON knowledge USING GIN(tags);

-- 抽奖历史表索引
CREATE INDEX idx_draw_history_user_id ON draw_history(user_id);
CREATE INDEX idx_draw_history_user_phone ON draw_history(user_phone);
CREATE INDEX idx_draw_history_draw_date ON draw_history(draw_date);
CREATE INDEX idx_draw_history_prize_won ON draw_history(prize_won);

-- 公告表索引
CREATE INDEX idx_announcements_is_active ON announcements(is_active);
CREATE INDEX idx_announcements_priority ON announcements(priority);
CREATE INDEX idx_announcements_created_at ON announcements(created_at);

-- 产品知识库表索引
CREATE INDEX idx_product_knowledge_is_active ON product_knowledge(is_active);
CREATE INDEX idx_product_knowledge_category ON product_knowledge(category);
CREATE INDEX idx_product_knowledge_tags ON product_knowledge USING GIN(tags);

SELECT 'Step 3 completed: Indexes created' as status;

-- =====================================================
-- 步骤 4: 创建触发器函数
-- =====================================================

-- 创建更新时间函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有表添加更新时间触发器
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settings_updated_at 
    BEFORE UPDATE ON settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_updated_at 
    BEFORE UPDATE ON knowledge
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_draw_history_updated_at 
    BEFORE UPDATE ON draw_history
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_announcements_updated_at 
    BEFORE UPDATE ON announcements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_knowledge_updated_at 
    BEFORE UPDATE ON product_knowledge
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

SELECT 'Step 4 completed: Triggers created' as status;

-- =====================================================
-- 步骤 5: 启用行级安全策略 (RLS)
-- =====================================================

-- 启用 RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge ENABLE ROW LEVEL SECURITY;
ALTER TABLE draw_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_knowledge ENABLE ROW LEVEL SECURITY;

-- 创建允许所有操作的策略（开发环境）
CREATE POLICY "Allow all operations on users" ON users FOR ALL USING (true);
CREATE POLICY "Allow all operations on settings" ON settings FOR ALL USING (true);
CREATE POLICY "Allow all operations on knowledge" ON knowledge FOR ALL USING (true);
CREATE POLICY "Allow all operations on draw_history" ON draw_history FOR ALL USING (true);
CREATE POLICY "Allow all operations on announcements" ON announcements FOR ALL USING (true);
CREATE POLICY "Allow all operations on product_knowledge" ON product_knowledge FOR ALL USING (true);

SELECT 'Step 5 completed: RLS policies created' as status;

-- =====================================================
-- 步骤 6: 启用实时订阅
-- =====================================================

-- 启用实时订阅
ALTER PUBLICATION supabase_realtime ADD TABLE users;
ALTER PUBLICATION supabase_realtime ADD TABLE settings;
ALTER PUBLICATION supabase_realtime ADD TABLE knowledge;
ALTER PUBLICATION supabase_realtime ADD TABLE draw_history;
ALTER PUBLICATION supabase_realtime ADD TABLE announcements;
ALTER PUBLICATION supabase_realtime ADD TABLE product_knowledge;

SELECT 'Step 6 completed: Realtime subscriptions enabled' as status;

-- =====================================================
-- 步骤 7: 创建视图
-- =====================================================

-- 创建用户统计视图
CREATE VIEW user_stats_view AS
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_users,
    COUNT(CASE WHEN remaining_chances > 0 THEN 1 END) as users_with_chances,
    AVG(draw_count) as avg_draws_per_user,
    SUM(draw_count) as total_draws,
    COUNT(CASE WHEN DATE(joindate) = CURRENT_DATE THEN 1 END) as new_users_today,
    COUNT(CASE WHEN DATE(last_participation) = CURRENT_DATE THEN 1 END) as active_users_today
FROM users;

-- 创建抽奖统计视图
CREATE VIEW draw_stats_view AS
SELECT 
    COUNT(*) as total_draws,
    COUNT(DISTINCT user_phone) as unique_participants,
    COUNT(CASE WHEN DATE(draw_date) = CURRENT_DATE THEN 1 END) as draws_today,
    COUNT(CASE WHEN DATE(draw_date) >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as draws_this_week,
    COUNT(CASE WHEN DATE(draw_date) >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as draws_this_month,
    COUNT(CASE WHEN is_claimed = true THEN 1 END) as claimed_prizes,
    COUNT(CASE WHEN is_claimed = false THEN 1 END) as unclaimed_prizes
FROM draw_history;

SELECT 'Step 7 completed: Views created' as status;

-- =====================================================
-- 步骤 8: 创建业务函数
-- =====================================================

-- 获取奖品统计函数
CREATE OR REPLACE FUNCTION get_prize_stats()
RETURNS TABLE(
    prize_name TEXT,
    count BIGINT,
    claimed_count BIGINT,
    unclaimed_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dh.prize_won,
        COUNT(*) as count,
        COUNT(CASE WHEN dh.is_claimed = true THEN 1 END) as claimed_count,
        COUNT(CASE WHEN dh.is_claimed = false THEN 1 END) as unclaimed_count
    FROM draw_history dh
    GROUP BY dh.prize_won
    ORDER BY count DESC;
END;
$$ LANGUAGE plpgsql;

-- 获取用户抽奖历史函数
CREATE OR REPLACE FUNCTION get_user_draw_history(user_phone_param TEXT)
RETURNS TABLE(
    id UUID,
    prize_won TEXT,
    draw_date TIMESTAMPTZ,
    is_claimed BOOLEAN,
    claimed_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dh.id,
        dh.prize_won,
        dh.draw_date,
        dh.is_claimed,
        dh.claimed_at
    FROM draw_history dh
    WHERE dh.user_phone = user_phone_param
    ORDER BY dh.draw_date DESC;
END;
$$ LANGUAGE plpgsql;

-- 更新用户抽奖次数函数
CREATE OR REPLACE FUNCTION update_user_draw_chances(user_phone_param TEXT, new_chances INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    user_exists BOOLEAN;
BEGIN
    -- 检查用户是否存在
    SELECT EXISTS(SELECT 1 FROM users WHERE phone = user_phone_param) INTO user_exists;
    
    IF NOT user_exists THEN
        RETURN FALSE;
    END IF;
    
    -- 更新用户抽奖次数
    UPDATE users 
    SET 
        remaining_chances = new_chances,
        drawchances = new_chances,
        updated_at = NOW()
    WHERE phone = user_phone_param;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 清理过期数据函数
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS TEXT AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- 删除30天前的抽奖历史（已领奖的）
    DELETE FROM draw_history 
    WHERE is_claimed = true 
    AND claimed_at < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN format('Cleaned up %s old draw history records', deleted_count);
END;
$$ LANGUAGE plpgsql;

-- 系统健康检查函数
CREATE OR REPLACE FUNCTION system_health_check()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    user_count INTEGER;
    setting_count INTEGER;
    knowledge_count INTEGER;
    draw_count INTEGER;
    announcement_count INTEGER;
    product_knowledge_count INTEGER;
BEGIN
    -- 获取各表的记录数
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO setting_count FROM settings;
    SELECT COUNT(*) INTO knowledge_count FROM knowledge;
    SELECT COUNT(*) INTO draw_count FROM draw_history;
    SELECT COUNT(*) INTO announcement_count FROM announcements;
    SELECT COUNT(*) INTO product_knowledge_count FROM product_knowledge;
    
    -- 构建结果
    result := jsonb_build_object(
        'status', 'healthy',
        'timestamp', NOW(),
        'tables', jsonb_build_object(
            'users', user_count,
            'settings', setting_count,
            'knowledge', knowledge_count,
            'draw_history', draw_count,
            'announcements', announcement_count,
            'product_knowledge', product_knowledge_count
        ),
        'views', jsonb_build_object(
            'user_stats_view', 'available',
            'draw_stats_view', 'available'
        ),
        'functions', jsonb_build_object(
            'get_prize_stats', 'available',
            'get_user_draw_history', 'available',
            'update_user_draw_chances', 'available',
            'cleanup_old_data', 'available',
            'system_health_check', 'available'
        )
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

SELECT 'Step 8 completed: Business functions created' as status;

-- =====================================================
-- 步骤 9: 插入默认设置数据
-- =====================================================

-- 插入设置数据
INSERT INTO settings (key, content, description, category) VALUES
('app_name', '1602 幸运轮盘', '应用程序名称', 'basic'),
('app_version', '1.0.0', '应用程序版本', 'basic'),
('max_draw_chances', '3', '每个用户的最大抽奖次数', 'lottery'),
('announcement', '欢迎参与1602幸运轮盘活动！每天都有机会赢取精美奖品！', '首页公告内容', 'content'),
('terms_and_conditions', '1. 每位用户每天最多可抽奖3次\n2. 奖品需在7天内领取\n3. 活动最终解释权归主办方所有', '活动条款和条件', 'legal'),
('contact_info', '客服电话：400-1602-1602\n客服邮箱：service@1602.com\n工作时间：9:00-18:00', '联系方式信息', 'contact'),
('activity_start_time', '2024-01-01 00:00:00', '活动开始时间', 'schedule'),
('activity_end_time', '2024-12-31 23:59:59', '活动结束时间', 'schedule'),
('prize_pool', '{"total_prizes": 1000, "remaining_prizes": 1000, "daily_limit": 50}', '奖品池配置', 'lottery'),
('lottery_config', '{"enabled": true, "daily_limit": 3, "cooldown_minutes": 60, "require_phone": true}', '抽奖系统配置', 'lottery'),
('prizes_config', '[
    {"id": 1, "name": "一等奖 - iPhone 15", "probability": 0.01, "quantity": 10, "remaining": 10, "image": "/images/iphone15.jpg"},
    {"id": 2, "name": "二等奖 - AirPods Pro", "probability": 0.05, "quantity": 50, "remaining": 50, "image": "/images/airpods.jpg"},
    {"id": 3, "name": "三等奖 - 1602定制T恤", "probability": 0.15, "quantity": 200, "remaining": 200, "image": "/images/tshirt.jpg"},
    {"id": 4, "name": "四等奖 - 1602马克杯", "probability": 0.25, "quantity": 300, "remaining": 300, "image": "/images/mug.jpg"},
    {"id": 5, "name": "参与奖 - 1602贴纸", "probability": 0.54, "quantity": 1000, "remaining": 1000, "image": "/images/sticker.jpg"}
]', '奖品配置信息', 'lottery'),
('claim_terms', '领奖须知：\n1. 中奖后请在7个工作日内联系客服领奖\n2. 领奖时需提供有效身份证明\n3. 奖品不可转让、不可兑换现金\n4. 如有疑问请联系客服', '领奖条款', 'legal'),
('promotion_packages', '[
    {"id": 1, "name": "新用户专享包", "description": "注册即送3次抽奖机会", "price": 0, "draw_chances": 3, "validity_days": 30},
    {"id": 2, "name": "幸运加倍包", "description": "购买后获得额外5次抽奖机会", "price": 9.9, "draw_chances": 5, "validity_days": 7},
    {"id": 3, "name": "超级幸运包", "description": "购买后获得额外10次抽奖机会", "price": 19.9, "draw_chances": 10, "validity_days": 15}
]', '优惠套餐配置', 'promotion'),
('share_content', '我在1602幸运轮盘中了大奖！快来一起参与吧！', '分享内容模板', 'social');

SELECT 'Step 9 completed: Settings data inserted' as status;

-- =====================================================
-- 步骤 10: 插入默认知识库数据
-- =====================================================

-- 插入知识库数据
INSERT INTO knowledge (key, content, title, category, tags) VALUES
('beer_recommendation', '推荐几款精酿啤酒：\n1. 1602 IPA - 浓郁的啤酒花香味\n2. 1602 小麦啤酒 - 清爽顺滑\n3. 1602 世涛 - 醇厚的咖啡巧克力味', '啤酒推荐', 'product', ARRAY['啤酒', '推荐', '精酿']),
('company_info', '1602啤酒公司成立于2016年，致力于为消费者提供高品质的精酿啤酒产品。我们坚持使用优质原料，传统工艺与现代技术相结合。', '公司简介', 'about', ARRAY['公司', '介绍', '历史']),
('activity_rules', '活动规则详情：\n1. 活动时间：2024年全年\n2. 参与方式：注册用户即可参与\n3. 抽奖次数：每日最多3次\n4. 奖品领取：中奖后7天内联系客服', '活动规则', 'activity', ARRAY['规则', '活动', '抽奖']),
('faq', '常见问题：\nQ: 如何增加抽奖次数？\nA: 可以通过购买优惠套餐获得额外抽奖机会。\n\nQ: 奖品如何领取？\nA: 中奖后请联系客服，提供相关信息即可领取。', '常见问题', 'help', ARRAY['FAQ', '帮助', '问题']),
('social_media', '关注我们的社交媒体：\n微信公众号：1602啤酒\n微博：@1602啤酒官方\n抖音：1602beer', '社交媒体', 'social', ARRAY['社交', '媒体', '关注']);

SELECT 'Step 10 completed: Knowledge data inserted' as status;

-- =====================================================
-- 步骤 11: 插入默认公告数据
-- =====================================================

-- 插入公告数据
INSERT INTO announcements (title, content, is_active, priority) VALUES
('欢迎参与1602幸运轮盘', '感谢您参与1602幸运轮盘活动！每天都有机会赢取精美奖品，快来试试手气吧！', true, 1),
('活动规则提醒', '请注意：每位用户每天最多可抽奖3次，奖品需在7天内领取。', true, 2),
('新奖品上线', '本周新增iPhone 15作为一等奖，中奖概率不变，快来参与吧！', true, 3);

SELECT 'Step 11 completed: Announcements data inserted' as status;

-- =====================================================
-- 步骤 12: 插入默认产品知识库数据
-- =====================================================

-- 插入产品知识库数据
INSERT INTO product_knowledge (title, description, category, content, tags) VALUES
('1602 IPA 精酿啤酒', '浓郁啤酒花香味的印度淡色艾尔啤酒', 'beer', '1602 IPA采用优质麦芽和精选啤酒花酿造，具有浓郁的柑橘和花香味，酒精度5.5%，苦度适中，是精酿啤酒爱好者的首选。', '["IPA", "精酿", "啤酒花", "柑橘"]'::jsonb),
('1602 小麦啤酒', '清爽顺滑的德式小麦啤酒', 'beer', '采用德国传统工艺酿造的小麦啤酒，口感清爽顺滑，带有淡淡的香蕉和丁香香味，酒精度4.8%，适合夏日饮用。', '["小麦", "德式", "清爽", "夏日"]'::jsonb),
('1602 世涛啤酒', '醇厚的咖啡巧克力味黑啤酒', 'beer', '深色的世涛啤酒，具有浓郁的咖啡和巧克力香味，口感醇厚丰富，酒精度6.2%，适合在寒冷的夜晚品尝。', '["世涛", "咖啡", "巧克力", "黑啤"]'::jsonb);

SELECT 'Step 12 completed: Product knowledge data inserted' as status;

-- =====================================================
-- 最终状态检查
-- =====================================================

-- 检查所有表是否创建成功
SELECT 
    'Database setup completed successfully!' as message,
    'Tables created: ' || string_agg(table_name, ', ') as tables
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'settings', 'knowledge', 'draw_history', 'announcements', 'product_knowledge');

-- 检查视图是否创建成功
SELECT 
    'Views created: ' || string_agg(table_name, ', ') as views
FROM information_schema.views 
WHERE table_schema = 'public' 
AND table_name IN ('user_stats_view', 'draw_stats_view');

-- 检查函数是否创建成功
SELECT 
    'Functions created: ' || string_agg(routine_name, ', ') as functions
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_prize_stats', 'get_user_draw_history', 'update_user_draw_chances', 'cleanup_old_data', 'system_health_check');

-- 显示设置数据统计
SELECT 
    'Settings inserted: ' || COUNT(*) as settings_count
FROM settings;

-- 显示知识库数据统计
SELECT 
    'Knowledge entries inserted: ' || COUNT(*) as knowledge_count
FROM knowledge;

SELECT 'All steps completed successfully! Database is ready for use.' as final_status;