-- =====================================================
-- 快速修复脚本 - 解决视图和函数缺失问题
-- =====================================================

-- 1. 检查基础表是否存在
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        RAISE EXCEPTION '错误: users 表不存在，请先执行基础表创建脚本';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'draw_history') THEN
        RAISE EXCEPTION '错误: draw_history 表不存在，请先执行基础表创建脚本';
    END IF;
    
    RAISE NOTICE '✅ 基础表检查通过';
END $$;

-- 2. 删除现有视图和函数（避免冲突）
DROP VIEW IF EXISTS user_stats_view CASCADE;
DROP VIEW IF EXISTS draw_stats_view CASCADE;
DROP FUNCTION IF EXISTS system_health_check() CASCADE;
DROP FUNCTION IF EXISTS get_prize_stats() CASCADE;
DROP FUNCTION IF EXISTS get_user_draw_history(TEXT) CASCADE;
DROP FUNCTION IF EXISTS update_user_draw_chances(TEXT, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS cleanup_old_data() CASCADE;

RAISE NOTICE '🗑️ 清理现有对象完成';

-- 3. 创建用户统计视图（使用 SECURITY INVOKER 模式）
CREATE OR REPLACE VIEW user_stats_view 
WITH (security_invoker=on) AS
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_users,
    COUNT(CASE WHEN remaining_chances > 0 THEN 1 END) as users_with_chances,
    AVG(remaining_chances) as avg_chances,
    MAX(created_at) as latest_registration,
    COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as today_registrations
FROM users;

RAISE NOTICE '✅ user_stats_view 创建完成';

-- 4. 创建抽奖统计视图（使用 SECURITY INVOKER 模式）
CREATE OR REPLACE VIEW draw_stats_view 
WITH (security_invoker=on) AS
SELECT 
    COUNT(*) as total_draws,
    COUNT(DISTINCT user_phone) as unique_participants,
    COUNT(CASE WHEN prize_won != '谢谢参与' THEN 1 END) as winning_draws,
    COUNT(CASE WHEN draw_date >= CURRENT_DATE THEN 1 END) as today_draws,
    MAX(draw_date) as latest_draw,
    ROUND(
        COUNT(CASE WHEN prize_won != '谢谢参与' THEN 1 END)::DECIMAL / 
        NULLIF(COUNT(*), 0) * 100, 2
    ) as win_rate
FROM draw_history;

RAISE NOTICE '✅ draw_stats_view 创建完成';

-- 5. 创建系统健康检查函数
CREATE OR REPLACE FUNCTION system_health_check()
RETURNS JSON AS $$
DECLARE
    result JSON;
    user_count INTEGER;
    draw_count INTEGER;
    settings_count INTEGER;
BEGIN
    -- 检查各表的记录数
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO draw_count FROM draw_history;
    SELECT COUNT(*) INTO settings_count FROM settings;
    
    -- 构建结果
    result := json_build_object(
        'status', 'healthy',
        'timestamp', NOW(),
        'database', json_build_object(
            'users_count', user_count,
            'draws_count', draw_count,
            'settings_count', settings_count
        ),
        'tables', json_build_object(
            'users', CASE WHEN user_count >= 0 THEN 'ok' ELSE 'error' END,
            'draw_history', CASE WHEN draw_count >= 0 THEN 'ok' ELSE 'error' END,
            'settings', CASE WHEN settings_count > 0 THEN 'ok' ELSE 'warning' END
        )
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

RAISE NOTICE '✅ system_health_check 函数创建完成';

-- 6. 创建获取奖品统计函数
CREATE OR REPLACE FUNCTION get_prize_stats()
RETURNS TABLE(
    prize_name TEXT,
    total_count BIGINT,
    win_rate DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dh.prize_name,
        COUNT(*) as total_count,
        ROUND(COUNT(*)::DECIMAL / (SELECT COUNT(*) FROM draw_history) * 100, 2) as win_rate
    FROM draw_history dh
    GROUP BY dh.prize_name
    ORDER BY total_count DESC;
END;
$$ LANGUAGE plpgsql;

RAISE NOTICE '✅ get_prize_stats 函数创建完成';

-- 7. 创建获取用户抽奖历史函数
CREATE OR REPLACE FUNCTION get_user_draw_history(user_phone_param TEXT)
RETURNS TABLE(
    id BIGINT,
    prize_name TEXT,
    created_at TIMESTAMPTZ,
    is_winner BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dh.id,
        dh.prize_name,
        dh.created_at,
        (dh.prize_name != '谢谢参与') as is_winner
    FROM draw_history dh
    WHERE dh.user_phone = user_phone_param
    ORDER BY dh.created_at DESC
    LIMIT 50;
END;
$$ LANGUAGE plpgsql;

RAISE NOTICE '✅ get_user_draw_history 函数创建完成';

-- 8. 创建更新用户抽奖次数函数
CREATE OR REPLACE FUNCTION update_user_draw_chances(
    user_phone_param TEXT,
    change_amount INTEGER
)
RETURNS JSON AS $$
DECLARE
    current_chances INTEGER;
    new_chances INTEGER;
    result JSON;
BEGIN
    -- 获取当前抽奖次数
    SELECT remaining_chances INTO current_chances
    FROM users
    WHERE phone = user_phone_param;
    
    IF current_chances IS NULL THEN
        result := json_build_object(
            'success', false,
            'message', '用户不存在',
            'current_chances', 0,
            'new_chances', 0
        );
        RETURN result;
    END IF;
    
    -- 计算新的抽奖次数
    new_chances := current_chances + change_amount;
    
    -- 确保不为负数
    IF new_chances < 0 THEN
        new_chances := 0;
    END IF;
    
    -- 更新数据库
    UPDATE users 
    SET remaining_chances = new_chances,
        updated_at = NOW()
    WHERE phone = user_phone_param;
    
    result := json_build_object(
        'success', true,
        'message', '更新成功',
        'current_chances', current_chances,
        'new_chances', new_chances,
        'change_amount', change_amount
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

RAISE NOTICE '✅ update_user_draw_chances 函数创建完成';

-- 9. 创建清理过期数据函数
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS JSON AS $$
DECLARE
    deleted_count INTEGER;
    result JSON;
BEGIN
    -- 删除30天前的抽奖记录（保留中奖记录）
    DELETE FROM draw_history 
    WHERE draw_date < NOW() - INTERVAL '30 days'
    AND prize_won = '谢谢参与';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    result := json_build_object(
        'success', true,
        'message', '清理完成',
        'deleted_records', deleted_count,
        'cleanup_date', NOW()
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

RAISE NOTICE '✅ cleanup_old_data 函数创建完成';

-- 10. 验证创建结果
DO $$
DECLARE
    view_count INTEGER;
    function_count INTEGER;
BEGIN
    -- 检查视图
    SELECT COUNT(*) INTO view_count
    FROM information_schema.views 
    WHERE table_name IN ('user_stats_view', 'draw_stats_view');
    
    -- 检查函数
    SELECT COUNT(*) INTO function_count
    FROM information_schema.routines 
    WHERE routine_name IN (
        'system_health_check',
        'get_prize_stats',
        'get_user_draw_history',
        'update_user_draw_chances',
        'cleanup_old_data'
    );
    
    RAISE NOTICE '📊 创建结果验证:';
    RAISE NOTICE '   - 视图数量: %', view_count;
    RAISE NOTICE '   - 函数数量: %', function_count;
    
    IF view_count = 2 AND function_count = 5 THEN
        RAISE NOTICE '🎉 所有对象创建成功！';
    ELSE
        RAISE NOTICE '⚠️ 部分对象创建失败，请检查错误信息';
    END IF;
END $$;

-- 11. 测试视图和函数
DO $$
DECLARE
    test_result JSON;
BEGIN
    RAISE NOTICE '🧪 开始功能测试...';
    
    -- 测试用户统计视图
    PERFORM * FROM user_stats_view LIMIT 1;
    RAISE NOTICE '✅ user_stats_view 测试通过';
    
    -- 测试抽奖统计视图
    PERFORM * FROM draw_stats_view LIMIT 1;
    RAISE NOTICE '✅ draw_stats_view 测试通过';
    
    -- 测试系统健康检查函数
    SELECT system_health_check() INTO test_result;
    RAISE NOTICE '✅ system_health_check 测试通过';
    
    -- 测试奖品统计函数
    PERFORM * FROM get_prize_stats() LIMIT 1;
    RAISE NOTICE '✅ get_prize_stats 测试通过';
    
    RAISE NOTICE '🎉 所有功能测试通过！';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ 测试失败: %', SQLERRM;
END $$;

-- 完成信息
SELECT 
    '🎉 快速修复完成！' as status,
    '请刷新 system-test.html 页面重新测试' as next_step,
    NOW() as completion_time;