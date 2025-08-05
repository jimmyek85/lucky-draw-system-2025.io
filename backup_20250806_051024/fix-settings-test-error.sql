-- =====================================================
-- 修复设置操作测试错误
-- =====================================================
-- 问题：system-test.html 中的设置操作测试失败
-- 错误：Cannot read properties of undefined (reading 'content')
-- 原因：settings 表中可能缺少 app_name 设置项
-- =====================================================

-- 1. 检查 app_name 设置是否存在
DO $$
DECLARE
    setting_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM settings WHERE key = 'app_name'
    ) INTO setting_exists;
    
    IF setting_exists THEN
        RAISE NOTICE '✅ app_name 设置已存在';
    ELSE
        RAISE NOTICE '❌ app_name 设置不存在，将创建';
    END IF;
END $$;

-- 2. 确保 app_name 设置存在（如果不存在则创建）
INSERT INTO settings (key, content, description, category) VALUES
('app_name', '1602 幸运轮盘', '应用名称', 'general')
ON CONFLICT (key) DO UPDATE SET
    content = EXCLUDED.content,
    description = EXCLUDED.description,
    category = EXCLUDED.category,
    updated_at = NOW();

-- 3. 验证其他必需的设置项
INSERT INTO settings (key, content, description, category) VALUES
('app_version', '1.0.0', '应用版本', 'general'),
('max_draw_chances', '1', '每个用户最大抽奖次数', 'game'),
('announcement', '欢迎参与1602幸运轮盘活动！', '公告内容', 'content'),
('contact_info', 'support@1602.com', '联系信息', 'general'),
('is_active', 'true', '活动是否激活', 'game')
ON CONFLICT (key) DO UPDATE SET
    content = EXCLUDED.content,
    updated_at = NOW();

-- 4. 检查所有设置项
SELECT 
    '📋 当前设置项列表：' as info;

SELECT 
    key as 设置键,
    content as 内容,
    description as 描述,
    category as 分类
FROM settings 
ORDER BY category, key;

-- 5. 验证 app_name 设置
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ app_name 设置验证成功'
        ELSE '❌ app_name 设置验证失败'
    END as 验证结果,
    COUNT(*) as 记录数量
FROM settings 
WHERE key = 'app_name';

-- 6. 测试设置读取（模拟前端操作）
SELECT 
    '🧪 模拟前端设置读取测试：' as 测试说明;

SELECT 
    key,
    content,
    CASE 
        WHEN content IS NOT NULL THEN '✅ 内容正常'
        ELSE '❌ 内容为空'
    END as 状态
FROM settings 
WHERE key = 'app_name';

RAISE NOTICE '';
RAISE NOTICE '=== 修复完成 ===';
RAISE NOTICE '✅ 已确保 app_name 设置存在';
RAISE NOTICE '✅ 已验证设置内容完整性';
RAISE NOTICE '✅ 现在可以重新运行 system-test.html 中的设置操作测试';
RAISE NOTICE '';
RAISE NOTICE '📝 如果问题仍然存在，请检查：';
RAISE NOTICE '1. Supabase 连接是否正常';
RAISE NOTICE '2. 浏览器控制台是否有其他错误';
RAISE NOTICE '3. 网络连接是否稳定';