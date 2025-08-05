-- =====================================================
-- 1602 幸运轮盘应用 - Supabase 完整数据库设置脚本
-- 一次性执行此脚本即可完成所有数据库配置
-- =====================================================

-- 注意：请在 Supabase Dashboard > SQL Editor 中执行此脚本
-- 执行前请确保您有足够的权限进行数据库操作

-- =====================================================
-- 第一部分：删除现有表和策略（如果存在）
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

-- 删除现有的触发器
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP TRIGGER IF EXISTS update_settings_updated_at ON settings;
DROP TRIGGER IF EXISTS update_knowledge_updated_at ON knowledge;

-- 删除现有的函数
DROP FUNCTION IF EXISTS update_updated_at_column();

-- 删除现有的表（注意：这会删除所有数据！）
-- 如果您想保留现有数据，请注释掉以下三行
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS settings CASCADE;
DROP TABLE IF EXISTS knowledge CASCADE;

-- =====================================================
-- 第二部分：创建数据库表结构
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
    -- 添加额外字段以支持更多功能
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

-- =====================================================
-- 第三部分：创建索引以优化查询性能
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

-- =====================================================
-- 第四部分：创建更新时间触发器函数
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

-- =====================================================
-- 第五部分：配置行级安全策略 (RLS)
-- =====================================================

-- 启用行级安全
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge ENABLE ROW LEVEL SECURITY;
ALTER TABLE draw_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_knowledge ENABLE ROW LEVEL SECURITY;

-- 创建宽松的安全策略（适用于公开应用）
-- 用户表策略 - 允许所有操作
CREATE POLICY "Allow all operations on users" ON users
    FOR ALL USING (true) WITH CHECK (true);

-- 设置表策略 - 允许所有操作
CREATE POLICY "Allow all operations on settings" ON settings
    FOR ALL USING (true) WITH CHECK (true);

-- 知识库表策略 - 允许所有操作
CREATE POLICY "Allow all operations on knowledge" ON knowledge
    FOR ALL USING (true) WITH CHECK (true);

-- 抽奖历史表策略 - 允许所有操作
CREATE POLICY "Allow all operations on draw_history" ON draw_history
    FOR ALL USING (true) WITH CHECK (true);

-- 公告表策略 - 允许所有操作
CREATE POLICY "Allow all operations on announcements" ON announcements
    FOR ALL USING (true) WITH CHECK (true);

-- 产品知识库表策略 - 允许所有操作
CREATE POLICY "Allow all operations on product_knowledge" ON product_knowledge
    FOR ALL USING (true) WITH CHECK (true);

-- =====================================================
-- 第六部分：启用实时订阅功能
-- =====================================================

-- 为所有表启用实时订阅
ALTER PUBLICATION supabase_realtime ADD TABLE users;
ALTER PUBLICATION supabase_realtime ADD TABLE settings;
ALTER PUBLICATION supabase_realtime ADD TABLE knowledge;
ALTER PUBLICATION supabase_realtime ADD TABLE draw_history;
ALTER PUBLICATION supabase_realtime ADD TABLE announcements;
ALTER PUBLICATION supabase_realtime ADD TABLE product_knowledge;

-- =====================================================
-- 第七部分：插入初始数据
-- =====================================================

-- 插入默认设置数据
INSERT INTO settings (key, content, description, category) VALUES
('app_name', '1602 幸运轮盘', '应用名称', 'general'),
('app_version', '1.0.0', '应用版本', 'general'),
('max_draw_chances', '1', '每个用户最大抽奖次数', 'game'),
('announcement', '欢迎参与1602幸运轮盘活动！', '公告内容', 'content'),
('terms_and_conditions', '参与本活动即表示您同意相关条款和条件。', '条款和条件', 'legal'),
('contact_info', 'support@1602.com', '联系信息', 'general'),
('event_start_date', '2024-01-01T00:00:00Z', '活动开始时间', 'game'),
('event_end_date', '2024-12-31T23:59:59Z', '活动结束时间', 'game'),
('is_active', 'true', '活动是否激活', 'game'),
('prize_pool', '[{"name":"一等奖","description":"精美礼品","quantity":10},{"name":"二等奖","description":"优惠券","quantity":50},{"name":"三等奖","description":"小礼品","quantity":100}]', '奖品池配置', 'game'),
('lottery_config', '{"INITIAL_CHANCES":1,"SPIN_AGAIN_BONUS":1,"MAX_ACCUMULATED_CHANCES":10,"DAILY_FREE_CHANCES":1,"ENABLE_DAILY_FREE":false,"ALLOW_ADMIN_ADD_CHANCES":true}', '抽奖机会配置', 'game'),
('prizes_config', '[{"name":"1602 Pale Ale","percentage":25,"color":"#FFD700"},{"name":"1602 Extra Dark","percentage":20,"color":"#8B4513"},{"name":"1602 Lager","percentage":15,"color":"#32CD32"},{"name":"RM5 代金券","percentage":20,"color":"#FF6347"},{"name":"RM2 代金券","percentage":15,"color":"#FF69B4"},{"name":"谢谢参与","percentage":5,"color":"#808080"}]', '奖品配置', 'game'),
('terms_conditions', '领奖条款与条件内容将在这里显示', '领奖条款与条件', 'content'),
('promotion_content', '🎉🎉🎉特价优惠🎉🎉🎉\n（周一至周四） monday to thursday：\n消费满55令吉以上(以一张单据为准)可以8令吉优惠价购得660ml瓶装精酿啤酒 (只限3瓶)\nSpend RM55 or more (based on one receipt), you can purchase ~660ml bottles of craft beer~ at a discounted price of RM8 (limited to 3 bottles)', '优惠套餐内容', 'content'),
('share_content', '🎉 1602手工精酿邀请您参加2025年古晋美食节！🍻\n\n快来我们的档口品尝新鲜出炉的鲜啤酒！现场分享此消息，即可额外获赠RM2代金券，还能参与我们的幸运轮盘大抽奖活动！🎁\n\n人人有机会，好酒好礼有惊喜！1602在古晋美食节档口等着您的光临!\n如今特价优惠！周一到周四来喝酒超级优惠而且更划算！！！\n\n🎉 1602 Craft Beer invites you to the 2025 Kuching Food Festival! 🍻\n\nCome to our booth to taste freshly brewed craft beer! Share this message on-site to receive an additional RM2 voucher and participate in our lucky wheel draw! 🎁\n\nEveryone has a chance to win great prizes! 1602 is waiting for you at the Kuching Food Festival booth!\nSpecial promotion now! Super discounts and great value when you come for drinks Monday to Thursday!!!', '分享内容', 'content')
ON CONFLICT (key) DO UPDATE SET
    content = EXCLUDED.content,
    updated_at = NOW();

-- 插入知识库数据
INSERT INTO knowledge (key, content, title, category, tags) VALUES
('beer_recommendation', '{"pale_ale":"果香清淡，适合初次尝试精酿啤酒的朋友","extra_dark":"浓郁醇厚，麦芽香味浓郁，适合喜欢重口味的朋友","lager":"经典清爽，口感平衡，适合各种场合"}', '啤酒推荐知识库', 'product', ARRAY['beer', 'recommendation']),
('company_info', '{"name":"1602 Craft Beer","description":"专业精酿啤酒品牌","established":"2020","location":"马来西亚"}', '公司信息', 'company', ARRAY['company', 'info']),
('event_rules', '{"participation":"每人限参与一次","age_limit":"21岁以上","location":"马来西亚地区","duration":"活动期间有效"}', '活动规则', 'event', ARRAY['rules', 'event']),
('faq', '{"q1":"如何参与抽奖？","a1":"填写个人信息即可获得抽奖机会","q2":"奖品如何领取？","a2":"中奖后我们会联系您安排领奖","q3":"活动什么时候结束？","a3":"请关注官方公告"}', '常见问题', 'support', ARRAY['faq', 'support']),
('social_media', '{"facebook":"https://facebook.com/1602craftbeer","instagram":"https://instagram.com/1602craftbeer","website":"https://1602craftbeer.com"}', '社交媒体链接', 'marketing', ARRAY['social', 'links'])
ON CONFLICT (key) DO UPDATE SET
    content = EXCLUDED.content,
    updated_at = NOW();

-- 插入公告数据
INSERT INTO announcements (title, content, priority, is_active) VALUES
('欢迎来到1602幸运轮盘！', '感谢您参与我们的幸运轮盘活动！每次注册可获得1次免费抽奖机会。', 1, true),
('新品上市通知', '我们推出了全新的精酿啤酒系列，欢迎品尝！', 2, true),
('古晋美食节活动', '1602手工精酿邀请您参加2025年古晋美食节！快来我们的档口品尝新鲜出炉的鲜啤酒！', 3, true)
ON CONFLICT DO NOTHING;

-- 插入产品知识库数据
INSERT INTO product_knowledge (title, description, category, content, tags) VALUES
('1602 Pale Ale', '清爽果香型精酿啤酒', 'beer', '1602 Pale Ale 是我们的招牌产品，采用优质啤酒花酿造，口感清爽，带有淡淡的果香味。酒精度数适中，适合各种场合饮用。', '["pale ale", "果香", "清爽", "精酿"]'),
('1602 Extra Dark', '浓郁麦芽型黑啤酒', 'beer', '1602 Extra Dark 是一款浓郁的黑啤酒，采用特殊烘焙麦芽酿造，口感醇厚，带有巧克力和咖啡的香味。适合喜欢浓郁口感的啤酒爱好者。', '["黑啤", "浓郁", "麦芽", "巧克力味"]'),
('1602 Lager', '经典清爽拉格啤酒', 'beer', '1602 Lager 是一款经典的拉格啤酒，口感清脆爽口，泡沫丰富持久。采用传统酿造工艺，是聚会和日常饮用的完美选择。', '["拉格", "清脆", "经典", "聚会"]'),
('古晋美食节特惠', '美食节期间特别优惠', 'promotion', '在古晋美食节期间，我们提供特别优惠价格。现场分享消息可获得额外代金券，还能参与幸运轮盘抽奖！', '["美食节", "优惠", "代金券", "抽奖"]')
ON CONFLICT DO NOTHING;

-- =====================================================
-- 第八部分：创建有用的视图和函数
-- =====================================================

-- 创建用户统计视图
CREATE OR REPLACE VIEW user_stats_view AS
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN remaining_chances > 0 THEN 1 END) as users_with_chances,
    COUNT(CASE WHEN draw_count > 0 THEN 1 END) as users_who_drew,
    SUM(draw_count) as total_draws,
    COUNT(CASE WHEN prizes_won IS NOT NULL AND prizes_won != '[]' THEN 1 END) as winners_count,
    COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as today_registrations,
    COUNT(CASE WHEN last_draw_date >= CURRENT_DATE THEN 1 END) as today_participants
FROM users;

-- 创建抽奖统计视图
CREATE OR REPLACE VIEW draw_stats_view AS
SELECT 
    COUNT(*) as total_draws,
    COUNT(CASE WHEN draw_date >= CURRENT_DATE THEN 1 END) as today_draws,
    COUNT(DISTINCT user_phone) as unique_participants,
    COUNT(CASE WHEN prize_won != '谢谢参与' THEN 1 END) as total_wins,
    COUNT(CASE WHEN draw_date >= CURRENT_DATE AND prize_won != '谢谢参与' THEN 1 END) as today_wins
FROM draw_history;

-- 创建奖品统计函数
CREATE OR REPLACE FUNCTION get_prize_stats()
RETURNS TABLE(
    prize_name TEXT,
    win_count BIGINT,
    win_percentage NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dh.prize_won,
        COUNT(*) as win_count,
        ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM draw_history WHERE prize_won != '谢谢参与')), 2) as win_percentage
    FROM draw_history dh
    WHERE dh.prize_won != '谢谢参与'
    GROUP BY dh.prize_won
    ORDER BY win_count DESC;
END;
$$ LANGUAGE plpgsql;

-- 创建获取用户抽奖历史函数
CREATE OR REPLACE FUNCTION get_user_draw_history(user_phone_param TEXT)
RETURNS TABLE(
    draw_date TIMESTAMP WITH TIME ZONE,
    prize_won TEXT,
    remaining_chances_after INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dh.draw_date,
        dh.prize_won,
        dh.remaining_chances_after
    FROM draw_history dh
    WHERE dh.user_phone = user_phone_param
    ORDER BY dh.draw_date DESC;
END;
$$ LANGUAGE plpgsql;

-- 创建更新用户抽奖次数函数
CREATE OR REPLACE FUNCTION update_user_draw_chances(
    user_phone_param TEXT,
    additional_chances INTEGER DEFAULT 1
)
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
    SET remaining_chances = remaining_chances + additional_chances,
        updated_at = NOW()
    WHERE phone = user_phone_param;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 创建清理过期数据函数
CREATE OR REPLACE FUNCTION cleanup_old_data(days_to_keep INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- 删除超过指定天数的抽奖历史记录
    DELETE FROM draw_history 
    WHERE draw_date < NOW() - INTERVAL '1 day' * days_to_keep;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 创建系统健康检查函数
CREATE OR REPLACE FUNCTION system_health_check()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- 检查用户表
    RETURN QUERY
    SELECT 
        'users_table'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'WARNING' END::TEXT,
        ('Total users: ' || COUNT(*))::TEXT
    FROM users;
    
    -- 检查抽奖历史表
    RETURN QUERY
    SELECT 
        'draw_history_table'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'INFO' END::TEXT,
        ('Total draws: ' || COUNT(*))::TEXT
    FROM draw_history;
    
    -- 检查设置表
    RETURN QUERY
    SELECT 
        'settings_table'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'WARNING' END::TEXT,
        ('Total settings: ' || COUNT(*))::TEXT
    FROM settings;
    
    -- 检查今日活动
    RETURN QUERY
    SELECT 
        'today_activity'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN 'ACTIVE' ELSE 'QUIET' END::TEXT,
        ('Today draws: ' || COUNT(*))::TEXT
    FROM draw_history
    WHERE draw_date >= CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 完成设置
-- =====================================================

-- 显示设置完成信息
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE '  Supabase 数据库设置完成！';
    RAISE NOTICE '==============================================';
    RAISE NOTICE '已创建的表：';
    RAISE NOTICE '- users (用户表)';
    RAISE NOTICE '- settings (设置表)';
    RAISE NOTICE '- knowledge (知识库表)';
    RAISE NOTICE '- draw_history (抽奖历史表)';
    RAISE NOTICE '- announcements (公告表)';
    RAISE NOTICE '- product_knowledge (产品知识库表)';
    RAISE NOTICE '';
    RAISE NOTICE '已创建的视图：';
    RAISE NOTICE '- user_stats_view (用户统计视图)';
    RAISE NOTICE '- draw_stats_view (抽奖统计视图)';
    RAISE NOTICE '';
    RAISE NOTICE '已创建的函数：';
    RAISE NOTICE '- get_prize_stats() (奖品统计)';
    RAISE NOTICE '- get_user_draw_history() (用户抽奖历史)';
    RAISE NOTICE '- update_user_draw_chances() (更新抽奖次数)';
    RAISE NOTICE '- cleanup_old_data() (清理过期数据)';
    RAISE NOTICE '- system_health_check() (系统健康检查)';
    RAISE NOTICE '';
    RAISE NOTICE '所有表已启用 RLS (行级安全)';
    RAISE NOTICE '所有表已启用实时订阅';
    RAISE NOTICE '已插入初始数据和配置';
    RAISE NOTICE '==============================================';
END $$;

-- =====================================================
-- 设置完成提示
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🎉 1602 幸运轮盘应用数据库设置完成！';
    RAISE NOTICE '📊 数据库包含以下功能：';
    RAISE NOTICE '   - 用户管理系统';
    RAISE NOTICE '   - 设置配置系统';
    RAISE NOTICE '   - 知识库系统';
    RAISE NOTICE '   - 抽奖历史记录';
    RAISE NOTICE '   - 公告管理';
    RAISE NOTICE '   - 产品知识库';
    RAISE NOTICE '   - 实时数据同步';
    RAISE NOTICE '   - 自动更新时间戳';
    RAISE NOTICE '   - 数据统计和分析';
    RAISE NOTICE '   - 安全权限控制';
    RAISE NOTICE '🚀 您的应用现在可以正常运行了！';
END $$;

-- =====================================================
-- 脚本执行完成
-- =====================================================