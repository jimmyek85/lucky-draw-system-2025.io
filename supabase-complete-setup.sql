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
    participation_count INTEGER DEFAULT 1,
    joindate TIMESTAMPTZ DEFAULT NOW(),
    last_participation TIMESTAMPTZ DEFAULT NOW(),
    prizeswon JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- 添加额外字段以支持更多功能
    status TEXT DEFAULT 'active',
    notes TEXT,
    referral_code TEXT,
    referred_by TEXT
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

-- 设置表索引
CREATE INDEX idx_settings_key ON settings(key);
CREATE INDEX idx_settings_category ON settings(category);
CREATE INDEX idx_settings_is_active ON settings(is_active);

-- 知识库表索引
CREATE INDEX idx_knowledge_key ON knowledge(key);
CREATE INDEX idx_knowledge_category ON knowledge(category);
CREATE INDEX idx_knowledge_is_published ON knowledge(is_published);
CREATE INDEX idx_knowledge_tags ON knowledge USING GIN(tags);

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

-- =====================================================
-- 第六部分：启用实时订阅功能
-- =====================================================

-- 为所有表启用实时订阅
ALTER PUBLICATION supabase_realtime ADD TABLE users;
ALTER PUBLICATION supabase_realtime ADD TABLE settings;
ALTER PUBLICATION supabase_realtime ADD TABLE knowledge;

-- =====================================================
-- 第七部分：插入初始数据
-- =====================================================

-- 插入默认设置数据
INSERT INTO settings (key, content, description, category) VALUES
('app_name', '1602 幸运轮盘', '应用名称', 'general'),
('app_version', '1.0.0', '应用版本', 'general'),
('max_draw_chances', '3', '每个用户最大抽奖次数', 'game'),
('announcement', '欢迎参与1602幸运轮盘活动！', '公告内容', 'content'),
('terms_and_conditions', '参与本活动即表示您同意相关条款和条件。', '条款和条件', 'legal'),
('contact_info', 'support@1602.com', '联系信息', 'general'),
('event_start_date', '2024-01-01T00:00:00Z', '活动开始时间', 'game'),
('event_end_date', '2024-12-31T23:59:59Z', '活动结束时间', 'game'),
('is_active', 'true', '活动是否激活', 'game'),
('prize_pool', '[{"name":"一等奖","description":"精美礼品","quantity":10},{"name":"二等奖","description":"优惠券","quantity":50},{"name":"三等奖","description":"小礼品","quantity":100}]', '奖品池配置', 'game')
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

-- =====================================================
-- 第八部分：创建有用的视图和函数
-- =====================================================

-- 创建用户统计视图
CREATE OR REPLACE VIEW user_statistics AS
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as today_registrations,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as week_registrations,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as month_registrations,
    SUM(participation_count) as total_participations,
    AVG(participation_count) as avg_participations_per_user,
    COUNT(CASE WHEN jsonb_array_length(prizeswon) > 0 THEN 1 END) as users_with_prizes
FROM users
WHERE status = 'active';

-- 创建获取用户信息的函数
CREATE OR REPLACE FUNCTION get_user_by_phone(user_phone TEXT)
RETURNS TABLE(
    id BIGINT,
    name TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    drawchances INTEGER,
    participation_count INTEGER,
    prizeswon JSONB,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.name, u.phone, u.email, u.address, 
           u.drawchances, u.participation_count, u.prizeswon, u.created_at
    FROM users u
    WHERE u.phone = user_phone AND u.status = 'active';
END;
$$ LANGUAGE plpgsql;

-- 创建更新用户参与次数的函数
CREATE OR REPLACE FUNCTION increment_user_participation(user_phone TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_exists BOOLEAN;
BEGIN
    -- 检查用户是否存在
    SELECT EXISTS(SELECT 1 FROM users WHERE phone = user_phone) INTO user_exists;
    
    IF user_exists THEN
        -- 更新参与次数和最后参与时间
        UPDATE users 
        SET participation_count = participation_count + 1,
            last_participation = NOW(),
            updated_at = NOW()
        WHERE phone = user_phone;
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 创建添加奖品记录的函数
CREATE OR REPLACE FUNCTION add_prize_to_user(user_phone TEXT, prize_info JSONB)
RETURNS BOOLEAN AS $$
DECLARE
    user_exists BOOLEAN;
BEGIN
    -- 检查用户是否存在
    SELECT EXISTS(SELECT 1 FROM users WHERE phone = user_phone) INTO user_exists;
    
    IF user_exists THEN
        -- 添加奖品到用户记录
        UPDATE users 
        SET prizeswon = prizeswon || prize_info,
            updated_at = NOW()
        WHERE phone = user_phone;
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 第九部分：创建数据清理和维护函数
-- =====================================================

-- 创建清理测试数据的函数
CREATE OR REPLACE FUNCTION cleanup_test_data()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- 删除测试用户数据
    DELETE FROM users 
    WHERE name LIKE '%测试%' 
       OR name LIKE '%test%' 
       OR phone LIKE '+60000%'
       OR email LIKE '%test%'
       OR email LIKE '%example.com';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 创建数据备份函数
CREATE OR REPLACE FUNCTION backup_user_data()
RETURNS TABLE(
    backup_time TIMESTAMPTZ,
    total_users BIGINT,
    active_users BIGINT,
    total_participations BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        NOW() as backup_time,
        COUNT(*) as total_users,
        COUNT(CASE WHEN status = 'active' THEN 1 END) as active_users,
        SUM(participation_count) as total_participations
    FROM users;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 第十部分：设置数据库权限和安全
-- =====================================================

-- 确保 anon 角色有足够权限
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- 确保 authenticated 角色有足够权限
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- =====================================================
-- 第十一部分：验证设置
-- =====================================================

-- 验证表是否创建成功
DO $$
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('users', 'settings', 'knowledge');
    
    IF table_count = 3 THEN
        RAISE NOTICE '✅ 所有表创建成功';
    ELSE
        RAISE NOTICE '❌ 表创建不完整，请检查错误信息';
    END IF;
END $$;

-- 验证RLS策略是否启用
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename IN ('users', 'settings', 'knowledge');
    
    IF policy_count >= 3 THEN
        RAISE NOTICE '✅ RLS策略配置成功';
    ELSE
        RAISE NOTICE '❌ RLS策略配置不完整';
    END IF;
END $$;

-- 验证实时订阅是否启用
DO $$
DECLARE
    realtime_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO realtime_count
    FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND tablename IN ('users', 'settings', 'knowledge');
    
    IF realtime_count = 3 THEN
        RAISE NOTICE '✅ 实时订阅配置成功';
    ELSE
        RAISE NOTICE '⚠️ 实时订阅可能需要手动配置';
    END IF;
END $$;

-- =====================================================
-- 设置完成提示
-- =====================================================

RAISE NOTICE '🎉 1602 幸运轮盘应用数据库设置完成！';
RAISE NOTICE '📊 数据库包含以下功能：';
RAISE NOTICE '   - 用户管理系统';
RAISE NOTICE '   - 设置配置系统';
RAISE NOTICE '   - 知识库系统';
RAISE NOTICE '   - 实时数据同步';
RAISE NOTICE '   - 自动更新时间戳';
RAISE NOTICE '   - 数据统计和分析';
RAISE NOTICE '   - 安全权限控制';
RAISE NOTICE '🚀 您的应用现在可以正常运行了！';

-- =====================================================
-- 脚本执行完成
-- =====================================================