\encoding UTF-8
SET client_encoding TO 'UTF8';

-- 120件の日本語サンプルアンケートを追加するSQL
-- survey_form.php で作成される survey_spec の構造に合わせています。
-- 実行前に users テーブルにサンプル作成者が存在するようにします。

INSERT INTO users (user_id, account_name, password_hash, created_at, updated_at)
VALUES (1, 'sample_creator', 'sample_hash_placeholder', NOW(), NOW())
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO surveys (
    creator_id,
    question_key,
    result_key,
    title,
    survey_spec,
    start_at,
    end_at,
    created_at,
    updated_at,
    is_notified
)
SELECT
    1,
    'sample-q-' || LPAD(gs.i::text, 3, '0'),
    'sample-r-' || LPAD(gs.i::text, 3, '0'),
    CASE gs.i % 8
        WHEN 0 THEN '地域イベント参加満足度アンケート ' || gs.i || '号'
        WHEN 1 THEN '学内サービス改善意識調査 ' || gs.i || '号'
        WHEN 2 THEN '新商品に関する利用感想調査 ' || gs.i || '号'
        WHEN 3 THEN '職場環境改善に関するアンケート ' || gs.i || '号'
        WHEN 4 THEN '地域コミュニティ活動のニーズ調査 ' || gs.i || '号'
        WHEN 5 THEN 'オンライン講座の満足度確認 ' || gs.i || '号'
        WHEN 6 THEN '健康管理サービス利用実態調査 ' || gs.i || '号'
        ELSE '地域情報共有に関する意見収集 ' || gs.i || '号'
    END,
    jsonb_build_object(
        'description',
        'ページネーション確認用の日本語サンプルアンケートです。',
        'Survey_tag',
        jsonb_build_array(
            CASE gs.i % 4
                WHEN 0 THEN 'サンプル'
                WHEN 1 THEN '日本語'
                WHEN 2 THEN 'ページネーション'
                ELSE '確認用'
            END,
            CASE (gs.i + 1) % 3
                WHEN 0 THEN 'アンケート'
                WHEN 1 THEN '調査'
                ELSE 'テストデータ'
            END,
            'survey-' || gs.i::text
        ),
        'questions',
        jsonb_build_array(
            jsonb_build_object(
                'label', 'このアンケートに満足していますか？',
                'type', 'single',
                'options', jsonb_build_array('とても満足', '満足', '普通', '不満'),
                'result_display', 'bar'
            ),
            jsonb_build_object(
                'label', '今後も利用したいですか？',
                'type', 'single',
                'options', jsonb_build_array('はい', 'いいえ', 'わからない'),
                'result_display', 'band'
            ),
            jsonb_build_object(
                'label', '改善してほしい点を教えてください。',
                'type', 'text',
                'options', jsonb_build_array(),
                'result_display', 'text'
            )
        )
    ),
    NOW() - (gs.i * INTERVAL '1 day'),
    NOW() + (gs.i * INTERVAL '1 day'),
    NOW(),
    NOW(),
    FALSE
FROM generate_series(1, 120) AS gs(i)
ON CONFLICT (question_key) DO NOTHING;

-- 各アンケートに 100 件のサンプル回答を追加する
-- question.php / question_complete.php で保存される answer_data の形式に合わせる
INSERT INTO responses (survey_id, user_id, answer_data, answered_at)
SELECT
    s.survey_id,
    NULL,
    jsonb_build_object(
        'q0',
        CASE (s.survey_id + gs.i) % 4
            WHEN 0 THEN 'とても満足'
            WHEN 1 THEN '満足'
            WHEN 2 THEN '普通'
            ELSE '不満'
        END,
        'q1',
        CASE (s.survey_id + gs.i) % 3
            WHEN 0 THEN 'はい'
            WHEN 1 THEN 'いいえ'
            ELSE 'わからない'
        END,
        'q2',
        'サンプル回答 ' || gs.i || '件目 - ' || s.title
    ),
    NOW() - (gs.i * INTERVAL '2 hours') - ((s.survey_id % 10) * INTERVAL '5 minutes')
FROM surveys s
INNER JOIN (SELECT question_key FROM surveys WHERE question_key LIKE 'sample-q-%') AS sample
    ON sample.question_key = s.question_key
CROSS JOIN generate_series(1, 100) AS gs(i);
