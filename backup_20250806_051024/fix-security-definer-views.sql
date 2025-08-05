-- =====================================================
-- 安全修复脚本 - 修复 SECURITY DEFINER 视图问题
-- =====================================================
-- 
-- 问题：Supabase Security Advisor 报告视图使用了 SECURITY DEFINER 属性
-- 风险：这些视图会使用创建者的权限执行，可能绕过 RLS 策略
-- 解决方案：将视图改为 SECURITY INVOKER 模式，使用调用者的权限
--
-- 参考文档：https://supabase.com/docs/guides/database/database-linter?lint=0010_security_definer_view
-- =====================================================

-- 开始修复
DO $$
BEGIN
    RAISE NOTICE '🔒 开始修复 SECURITY DEFINER 视图安全问题...';
END $$;

-- 1. 删除现有的 SECURITY DEFINER 视图
DROP VIEW IF EXISTS public.user_stats_view CASCADE;
DROP VIEW IF EXISTS public.draw_stats_view CASCADE;

RAISE NOTICE '🗑️ 已删除现有的 SECURITY DEFINER 视图';

-- 2. 重新创建 user_stats_view 视图（使用 SECURITY INVOKER）
CREATE VIEW public.user_stats_view 
WITH (security_invoker=on) AS
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_users,
    COUNT(CASE WHEN remaining_chances > 0 THEN 1 END) as users_with_chances,
    AVG(remaining_chances) as avg_chances,
    MAX(created_at) as latest_registration,
    COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as today_registrations
FROM users;

RAISE NOTICE '✅ user_stats_view 已重新创建（SECURITY INVOKER 模式）';

-- 3. 重新创建 draw_stats_view 视图（使用 SECURITY INVOKER）
CREATE VIEW public.draw_stats_view 
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

RAISE NOTICE '✅ draw_stats_view 已重新创建（SECURITY INVOKER 模式）';

-- =====================================================
-- 验证修复结果
-- =====================================================

-- 检查视图是否正确创建
DO $$
DECLARE
    user_view_exists BOOLEAN;
    draw_view_exists BOOLEAN;
    user_view_security TEXT;
    draw_view_security TEXT;
BEGIN
    -- 检查视图是否存在
    SELECT EXISTS(
        SELECT 1 FROM information_schema.views 
        WHERE table_schema = 'public' AND table_name = 'user_stats_view'
    ) INTO user_view_exists;
    
    SELECT EXISTS(
        SELECT 1 FROM information_schema.views 
        WHERE table_schema = 'public' AND table_name = 'draw_stats_view'
    ) INTO draw_view_exists;
    
    -- 检查安全模式（PostgreSQL 14+ 支持）
    BEGIN
        SELECT 
            CASE 
                WHEN view_definition LIKE '%security_invoker%' THEN 'SECURITY INVOKER'
                ELSE 'SECURITY DEFINER (默认)'
            END
        INTO user_view_security
        FROM information_schema.views 
        WHERE table_schema = 'public' AND table_name = 'user_stats_view';
    EXCEPTION WHEN OTHERS THEN
        user_view_security := '无法检测';
    END;
    
    BEGIN
        SELECT 
            CASE 
                WHEN view_definition LIKE '%security_invoker%' THEN 'SECURITY INVOKER'
                ELSE 'SECURITY DEFINER (默认)'
            END
        INTO draw_view_security
        FROM information_schema.views 
        WHERE table_schema = 'public' AND table_name = 'draw_stats_view';
    EXCEPTION WHEN OTHERS THEN
        draw_view_security := '无法检测';
    END;
    
    -- 输出验证结果
    RAISE NOTICE '📊 修复验证结果：';
    RAISE NOTICE '  - user_stats_view 存在: %', CASE WHEN user_view_exists THEN '✅ 是' ELSE '❌ 否' END;
    RAISE NOTICE '  - draw_stats_view 存在: %', CASE WHEN draw_view_exists THEN '✅ 是' ELSE '❌ 否' END;
    RAISE NOTICE '  - user_stats_view 安全模式: %', user_view_security;
    RAISE NOTICE '  - draw_stats_view 安全模式: %', draw_view_security;
    
    IF user_view_exists AND draw_view_exists THEN
        RAISE NOTICE '🎉 安全修复完成！所有视图已成功重新创建为 SECURITY INVOKER 模式';
    ELSE
        RAISE NOTICE '⚠️ 部分视图创建失败，请检查错误信息';
    END IF;
END $$;

-- =====================================================
-- 测试视图功能
-- =====================================================

-- 测试用户统计视图
SELECT '测试 user_stats_view' as test_name;
SELECT * FROM public.user_stats_view LIMIT 1;

-- 测试抽奖统计视图
SELECT '测试 draw_stats_view' as test_name;
SELECT * FROM public.draw_stats_view LIMIT 1;

-- =====================================================
-- 安全说明和建议
-- =====================================================

/*
🔒 安全修复说明：

1. SECURITY DEFINER vs SECURITY INVOKER：
   - SECURITY DEFINER：使用视图创建者的权限执行（默认，有安全风险）
   - SECURITY INVOKER：使用调用者的权限执行（推荐，更安全）

2. 修复后的好处：
   - 遵循最小权限原则
   - 尊重 RLS（行级安全）策略
   - 防止权限提升攻击
   - 符合 Supabase 安全最佳实践

3. 注意事项：
   - 确保调用者有足够权限访问底层表
   - 如果需要特殊权限，考虑使用函数而不是视图
   - 定期运行 Supabase Security Advisor 检查

4. 验证修复：
   - 在 Supabase Dashboard 中重新运行 Security Advisor
   - 确认不再有 security_definer_view 错误
   - 测试应用功能是否正常

📚 更多信息：
https://supabase.com/docs/guides/database/database-linter?lint=0010_security_definer_view
*/

SELECT 
    '🔒 安全修复完成' as status,
    '视图已从 SECURITY DEFINER 改为 SECURITY INVOKER 模式' as message,
    '请在 Supabase Security Advisor 中验证修复结果' as next_step,
    NOW() as fixed_at;