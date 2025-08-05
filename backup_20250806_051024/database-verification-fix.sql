-- =====================================================
-- 数据库验证和修复脚本
-- 请在 Supabase SQL Editor 中分步执行
-- =====================================================

-- 第一步：检查现有表结构
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'settings', 'knowledge', 'draw_history', 'announcements', 'product_knowledge')
ORDER BY table_name;

-- 第二步：检查现有视图
SELECT 
    table_name as view_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'VIEW'
AND table_name IN ('user_stats_view', 'draw_stats_view')
ORDER BY table_name;

-- 第三步：检查现有函数
SELECT 
    routine_name as function_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_prize_stats', 'get_user_draw_history', 'update_user_draw_chances', 'cleanup_old_data', 'system_health_check')
ORDER BY routine_name;

-- =====================================================
-- 修复部分：重新创建缺失的视图和函数
-- =====================================================

-- 删除可能存在的旧视图和函数
DROP VIEW IF EXISTS user_stats_view CASCADE;
DROP VIEW IF EXISTS draw_stats_view CASCADE;
DROP FUNCTION IF EXISTS get_prize_stats() CASCADE;
DROP FUNCTION IF EXISTS get_user_draw_history(TEXT) CASCADE;
DROP FUNCTION IF EXISTS update_user_draw_chances(TEXT, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS cleanup_old_data(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS system_health_check() CASCADE;

-- 重新创建用户统计视图
CREATE OR REPLACE VIEW user_stats_view AS
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN remaining_chances > 0 THEN 1 END) as users_with_chances,
    COUNT(CASE WHEN draw_count > 0 THEN 1 END) as users_who_drew,
    COALESCE(SUM(draw_count), 0) as total_draws,
    COUNT(CASE WHEN prizes_won IS NOT NULL AND prizes_won != '[]' THEN 1 END) as winners_count,
    COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as today_registrations,
    COUNT(CASE WHEN last_draw_date >= CURRENT_DATE THEN 1 END) as today_participants
FROM users;

-- 重新创建抽奖统计视图
CREATE OR REPLACE VIEW draw_stats_view AS
SELECT 
    COUNT(*) as total_draws,
    COUNT(CASE WHEN draw_date >= CURRENT_DATE THEN 1 END) as today_draws,
    COUNT(DISTINCT user_phone) as unique_participants,
    COUNT(CASE WHEN prize_won != '谢谢参与' THEN 1 END) as total_wins,
    COUNT(CASE WHEN draw_date >= CURRENT_DATE AND prize_won != '谢谢参与' THEN 1 END) as today_wins
FROM draw_history;

-- 重新创建奖品统计函数
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
        CASE 
            WHEN (SELECT COUNT(*) FROM draw_history WHERE prize_won != '谢谢参与') > 0 
            THEN ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM draw_history WHERE prize_won != '谢谢参与')), 2)
            ELSE 0
        END as win_percentage
    FROM draw_history dh
    WHERE dh.prize_won != '谢谢参与'
    GROUP BY dh.prize_won
    ORDER BY win_count DESC;
END;
$$ LANGUAGE plpgsql;

-- 重新创建获取用户抽奖历史函数
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

-- 重新创建更新用户抽奖次数函数
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

-- 重新创建清理过期数据函数
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

-- 重新创建系统健康检查函数
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
-- 验证修复结果
-- =====================================================

-- 测试用户统计视图
SELECT '用户统计视图测试' as test_name;
SELECT * FROM user_stats_view;

-- 测试抽奖统计视图
SELECT '抽奖统计视图测试' as test_name;
SELECT * FROM draw_stats_view;

-- 测试系统健康检查函数
SELECT '系统健康检查函数测试' as test_name;
SELECT * FROM system_health_check();

-- 测试奖品统计函数
SELECT '奖品统计函数测试' as test_name;
SELECT * FROM get_prize_stats();

-- =====================================================
-- 检查设置表数据
-- =====================================================

-- 验证设置表中的关键配置
SELECT 
    key,
    CASE 
        WHEN LENGTH(content) > 50 THEN LEFT(content, 50) || '...'
        ELSE content
    END as content_preview,
    category
FROM settings 
WHERE key IN ('app_name', 'lottery_config', 'prizes_config', 'max_draw_chances')
ORDER BY key;

-- =====================================================
-- 完成提示
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE '  数据库验证和修复完成！';
    RAISE NOTICE '==============================================';
    RAISE NOTICE '如果上面的测试都成功执行，说明数据库已修复';
    RAISE NOTICE '请检查前端应用是否能正常连接和使用';
    RAISE NOTICE '==============================================';
END $$;