-- =========================================================
-- Matched Betting Analytics Platform
-- Reporting views
-- =========================================================


-- ---------------------------------------------------------
-- 1. CASH BALANCE BY PLATFORM
-- Calculates the present cash balance of every platform.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW platform_cash_balances AS

SELECT
    p.platform_id,
    p.platform_name,
    p.platform_type,
    COALESCE(SUM(t.amount), 0.00)::NUMERIC(12,2)
        AS cash_balance
FROM platforms AS p
LEFT JOIN transactions AS t
    ON t.platform_id = p.platform_id
GROUP BY
    p.platform_id,
    p.platform_name,
    p.platform_type;


-- ---------------------------------------------------------
-- 2. PROMOTIONAL ASSETS
-- Shows rewards that have been credited but not yet used.
-- Face value is kept separate from cash value.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW active_promotional_assets AS

SELECT
    p.platform_id,
    p.platform_name,
    r.reward_type,
    COUNT(*) AS reward_count,
    SUM(r.face_value)::NUMERIC(12,2)
        AS promotional_face_value,
    MIN(r.expires_at) AS nearest_expiry
FROM rewards AS r
JOIN promotions AS pr
    ON pr.promotion_id = r.promotion_id
JOIN platforms AS p
    ON p.platform_id = pr.platform_id
WHERE r.reward_status = 'CREDITED'
GROUP BY
    p.platform_id,
    p.platform_name,
    r.reward_type;


-- ---------------------------------------------------------
-- 3. EXPECTED REWARDS
-- Rewards earned or anticipated but not yet credited.
-- These are shown separately because they are not yet assets.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW expected_rewards AS

SELECT
    p.platform_id,
    p.platform_name,
    COUNT(*) AS expected_reward_count,
    SUM(r.face_value)::NUMERIC(12,2)
        AS expected_face_value,
    MIN(r.expires_at) AS nearest_expiry
FROM rewards AS r
JOIN promotions AS pr
    ON pr.promotion_id = r.promotion_id
JOIN platforms AS p
    ON p.platform_id = pr.platform_id
WHERE r.reward_status = 'EXPECTED'
GROUP BY
    p.platform_id,
    p.platform_name;


-- ---------------------------------------------------------
-- 4. OPEN BET EXPOSURE
-- Shows stakes and lay liabilities tied up in open bets.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW open_bet_exposure AS

SELECT
    COUNT(*) AS open_bet_count,

    COALESCE(
        SUM(stake) FILTER (
            WHERE bet_side = 'BACK'
        ),
        0.00
    )::NUMERIC(12,2) AS open_back_stakes,

    COALESCE(
        SUM(liability) FILTER (
            WHERE bet_side = 'LAY'
        ),
        0.00
    )::NUMERIC(12,2) AS open_lay_liability

FROM bets
WHERE bet_status = 'OPEN';


-- ---------------------------------------------------------
-- 5. TOTAL ASSETS
-- One-row financial summary of the entire operation.
--
-- Promotional face value is deliberately separated from
-- cash because a £10 free bet is not equivalent to £10 cash.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW total_assets AS

SELECT
    cash.cash_assets,

    promo.active_promotional_face_value,

    expected.expected_reward_face_value,

    exposure.open_back_stakes,

    exposure.open_lay_liability,

    (
        cash.cash_assets
        + promo.active_promotional_face_value
    )::NUMERIC(12,2) AS cash_plus_promotional_face_value

FROM (
    SELECT
        COALESCE(SUM(cash_balance), 0.00)::NUMERIC(12,2)
            AS cash_assets
    FROM platform_cash_balances
) AS cash

CROSS JOIN (
    SELECT
        COALESCE(
            SUM(promotional_face_value),
            0.00
        )::NUMERIC(12,2)
            AS active_promotional_face_value
    FROM active_promotional_assets
) AS promo

CROSS JOIN (
    SELECT
        COALESCE(
            SUM(expected_face_value),
            0.00
        )::NUMERIC(12,2)
            AS expected_reward_face_value
    FROM expected_rewards
) AS expected

CROSS JOIN open_bet_exposure AS exposure;


-- ---------------------------------------------------------
-- 6. PLATFORM OVERVIEW
-- Combines cash and active promotional value by platform.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW platform_overview AS

SELECT
    pcb.platform_id,
    pcb.platform_name,
    pcb.platform_type,
    pcb.cash_balance,

    COALESCE(
        promo.promotional_face_value,
        0.00
    )::NUMERIC(12,2) AS promotional_face_value,

    (
        pcb.cash_balance
        + COALESCE(promo.promotional_face_value, 0.00)
    )::NUMERIC(12,2) AS total_reported_value

FROM platform_cash_balances AS pcb

LEFT JOIN (
    SELECT
        platform_id,
        SUM(promotional_face_value)
            AS promotional_face_value
    FROM active_promotional_assets
    GROUP BY platform_id
) AS promo
    ON promo.platform_id = pcb.platform_id;