-- =====================================================
-- 修复抽奖统计视图 - 解决列名错误问题
-- =====================================================

-- 问题：draw_stats_view 中使用了错误的列名 created_at，应该是 draw_date
-- 解决方案：重新创建正确的抽奖统计视图

-- 1. 删除现有的错误视图
DROP VIEW IF EXISTS draw_stats_view;

-- 2. 创建正确的抽奖统计视图
CREATE OR REPLACE VIEW draw_stats_view AS 
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

-- 3. 验证视图创建成功
SELECT 'draw_stats_view 创建成功' as status;

-- 4. 测试视图查询
SELECT 
    '视图测试结果:' as test_type,
    total_draws,
    unique_participants,
    winning_draws,
    today_draws,
    latest_draw,
    win_rate
FROM draw_stats_view;

-- 5. 检查 draw_history 表结构（用于确认列名）
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'draw_history' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 6. 显示修复完成信息
SELECT 
    '修复完成' as status,
    'draw_stats_view 已使用正确的列名 draw_date 重新创建' as message,
    NOW() as fixed_at;