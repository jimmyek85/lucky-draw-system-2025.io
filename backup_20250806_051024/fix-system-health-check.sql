-- =====================================================
-- 修复系统健康检查函数
-- =====================================================

-- 删除现有的系统健康检查函数
DROP FUNCTION IF EXISTS system_health_check();

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
        'users_table'::TEXT as check_name,
        CASE 
            WHEN (SELECT COUNT(*) FROM users) > 0 THEN 'OK'
            ELSE 'WARNING'
        END::TEXT as status,
        ('Total users: ' || (SELECT COUNT(*) FROM users))::TEXT as details;
    
    -- 检查抽奖历史表
    RETURN QUERY
    SELECT 
        'draw_history_table'::TEXT as check_name,
        CASE 
            WHEN (SELECT COUNT(*) FROM draw_history) > 0 THEN 'OK'
            ELSE 'INFO'
        END::TEXT as status,
        ('Total draws: ' || (SELECT COUNT(*) FROM draw_history))::TEXT as details;
    
    -- 检查设置表
    RETURN QUERY
    SELECT 
        'settings_table'::TEXT as check_name,
        CASE 
            WHEN (SELECT COUNT(*) FROM settings) > 0 THEN 'OK'
            ELSE 'WARNING'
        END::TEXT as status,
        ('Total settings: ' || (SELECT COUNT(*) FROM settings))::TEXT as details;
    
    -- 检查知识库表
    RETURN QUERY
    SELECT 
        'knowledge_table'::TEXT as check_name,
        CASE 
            WHEN (SELECT COUNT(*) FROM knowledge) > 0 THEN 'OK'
            ELSE 'INFO'
        END::TEXT as status,
        ('Total knowledge items: ' || (SELECT COUNT(*) FROM knowledge))::TEXT as details;
    
    -- 检查公告表
    RETURN QUERY
    SELECT 
        'announcements_table'::TEXT as check_name,
        CASE 
            WHEN (SELECT COUNT(*) FROM announcements) > 0 THEN 'OK'
            ELSE 'INFO'
        END::TEXT as status,
        ('Total announcements: ' || (SELECT COUNT(*) FROM announcements))::TEXT as details;
    
    -- 检查产品知识库表
    RETURN QUERY
    SELECT 
        'product_knowledge_table'::TEXT as check_name,
        CASE 
            WHEN (SELECT COUNT(*) FROM product_knowledge) > 0 THEN 'OK'
            ELSE 'INFO'
        END::TEXT as status,
        ('Total products: ' || (SELECT COUNT(*) FROM product_knowledge))::TEXT as details;
    
    -- 检查今日活动
    RETURN QUERY
    SELECT 
        'today_activity'::TEXT as check_name,
        CASE 
            WHEN (SELECT COUNT(*) FROM draw_history WHERE draw_date >= CURRENT_DATE) > 0 THEN 'ACTIVE'
            ELSE 'QUIET'
        END::TEXT as status,
        ('Today draws: ' || (SELECT COUNT(*) FROM draw_history WHERE draw_date >= CURRENT_DATE))::TEXT as details;
    
    -- 检查用户统计视图
    RETURN QUERY
    SELECT 
        'user_stats_view'::TEXT as check_name,
        CASE 
            WHEN (SELECT COUNT(*) FROM user_stats_view) >= 0 THEN 'OK'
            ELSE 'ERROR'
        END::TEXT as status,
        'User statistics view accessible'::TEXT as details;
    
    -- 检查抽奖统计视图
    RETURN QUERY
    SELECT 
        'draw_stats_view'::TEXT as check_name,
        CASE 
            WHEN (SELECT COUNT(*) FROM draw_stats_view) >= 0 THEN 'OK'
            ELSE 'ERROR'
        END::TEXT as status,
        'Draw statistics view accessible'::TEXT as details;
    
    -- 检查数据库连接
    RETURN QUERY
    SELECT 
        'database_connection'::TEXT as check_name,
        'OK'::TEXT as status,
        ('Connected at: ' || NOW()::TEXT)::TEXT as details;

END;
$$ LANGUAGE plpgsql;

-- 测试系统健康检查函数
SELECT '🧪 测试系统健康检查函数...' as test_info;

-- 执行健康检查并显示结果
SELECT 
    '✅ 健康检查结果:' as result_header;

SELECT 
    check_name as 检查项目,
    status as 状态,
    details as 详细信息
FROM system_health_check()
ORDER BY 
    CASE status
        WHEN 'OK' THEN 1
        WHEN 'ACTIVE' THEN 2
        WHEN 'INFO' THEN 3
        WHEN 'WARNING' THEN 4
        WHEN 'QUIET' THEN 5
        ELSE 6
    END;

-- 验证函数返回格式
SELECT '🔍 验证函数返回格式...' as verification_info;

DO $$
DECLARE
    health_record RECORD;
    record_count INTEGER := 0;
BEGIN
    FOR health_record IN SELECT * FROM system_health_check() LOOP
        record_count := record_count + 1;
        RAISE NOTICE '记录 %: 检查项=%, 状态=%, 详情=%', 
            record_count, 
            health_record.check_name, 
            health_record.status, 
            health_record.details;
    END LOOP;
    
    RAISE NOTICE '✅ 健康检查函数返回了 % 条记录', record_count;
    
    IF record_count > 0 THEN
        RAISE NOTICE '✅ 函数工作正常，返回格式正确';
    ELSE
        RAISE NOTICE '❌ 函数没有返回任何记录';
    END IF;
END $$;

-- 显示修复完成信息
SELECT '🎉 系统健康检查函数修复完成！' as completion_message;