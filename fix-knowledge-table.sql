-- =====================================================
-- 知识库表结构修复脚本
-- 修复 knowledge 表以支持产品知识管理功能
-- =====================================================

-- 添加缺失的字段到 knowledge 表
ALTER TABLE knowledge 
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS features TEXT[],
ADD COLUMN IF NOT EXISTS price TEXT,
ADD COLUMN IF NOT EXISTS image_urls TEXT[],
ADD COLUMN IF NOT EXISTS document_urls JSONB DEFAULT '[]'::jsonb;

-- 创建索引以优化查询性能
CREATE INDEX IF NOT EXISTS idx_knowledge_description ON knowledge(description);
CREATE INDEX IF NOT EXISTS idx_knowledge_price ON knowledge(price);
CREATE INDEX IF NOT EXISTS idx_knowledge_features ON knowledge USING GIN(features);
CREATE INDEX IF NOT EXISTS idx_knowledge_image_urls ON knowledge USING GIN(image_urls);

-- 更新现有数据的结构（如果需要）
UPDATE knowledge 
SET 
    description = COALESCE(description, ''),
    features = COALESCE(features, ARRAY[]::TEXT[]),
    image_urls = COALESCE(image_urls, ARRAY[]::TEXT[]),
    document_urls = COALESCE(document_urls, '[]'::jsonb)
WHERE description IS NULL 
   OR features IS NULL 
   OR image_urls IS NULL 
   OR document_urls IS NULL;

-- 验证表结构
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'knowledge' 
ORDER BY ordinal_position;