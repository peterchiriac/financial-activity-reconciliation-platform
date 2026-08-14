-- =========================================================
-- Matched Betting Analytics Platform
-- Operational and analytical queries
-- =========================================================


-- ---------------------------------------------------------
-- FINANCIAL X-RAY
-- ---------------------------------------------------------

SELECT *
FROM total_assets;


-- ---------------------------------------------------------
-- MONEY BY PLATFORM
-- ---------------------------------------------------------

SELECT
    platform_name,
    platform_type,
    cash_balance,
    promotional_face_value,
    total_reported_value
FROM platform_overview
ORDER BY total_reported_value DESC;


-- ---------------------------------------------------------
-- TRANSACTION HISTORY
-- ---------------------------------------------------------

SELECT
    t.transaction_id,
    t.occurred_at,
    p.platform_name,
    t.transaction_type,
    t.amount,
    t.external_reference,
    t.notes
FROM transactions AS t
JOIN platforms AS p
    ON p.platform_id = t.platform_id
ORDER BY
    t.occurred_at DESC,
    t.transaction_id DESC;


-- ---------------------------------------------------------
-- OPEN BETS
-- ---------------------------------------------------------

SELECT
    b.bet_id,
    p.platform_name,
    b.bet_side,
    b.bet_type,
    b.stake,
    b.decimal_odds,
    b.liability,
    b.placed_at
FROM bets AS b
JOIN platforms AS p
    ON p.platform_id = b.platform_id
WHERE b.bet_status = 'OPEN'
ORDER BY b.placed_at;


-- ---------------------------------------------------------
-- OPEN BET EXPOSURE
-- ---------------------------------------------------------

SELECT *
FROM open_bet_exposure;


-- ---------------------------------------------------------
-- ACTIVE REWARDS
-- ---------------------------------------------------------

SELECT
    p.platform_name,
    pr.promotion_name,
    r.reward_id,
    r.reward_type,
    r.face_value,
    r.reward_status,
    r.credited_at,
    r.expires_at
FROM rewards AS r
JOIN promotions AS pr
    ON pr.promotion_id = r.promotion_id
JOIN platforms AS p
    ON p.platform_id = pr.platform_id
WHERE r.reward_status IN ('EXPECTED', 'CREDITED')
ORDER BY
    r.expires_at NULLS LAST,
    p.platform_name;


-- ---------------------------------------------------------
-- COMPLETED MATCHES AND EVENTS
-- ---------------------------------------------------------

SELECT
    bl.event_name,
    bl.sport,
    bl.competition,
    bl.event_start_at,
    bl.selection_name,
    bl.market_name,
    bl.leg_status,
    b.bet_id,
    b.bet_status
FROM bet_legs AS bl
JOIN bets AS b
    ON b.bet_id = bl.bet_id
WHERE bl.leg_status <> 'OPEN'
ORDER BY bl.event_start_at DESC;


-- ---------------------------------------------------------
-- NUMBER OF BETS BY PLATFORM
-- ---------------------------------------------------------

SELECT
    p.platform_name,
    COUNT(*) AS total_bets,
    COUNT(*) FILTER (
        WHERE b.bet_status = 'OPEN'
    ) AS open_bets,
    COUNT(*) FILTER (
        WHERE b.bet_status = 'WON'
    ) AS won_bets,
    COUNT(*) FILTER (
        WHERE b.bet_status = 'LOST'
    ) AS lost_bets
FROM bets AS b
JOIN platforms AS p
    ON p.platform_id = b.platform_id
GROUP BY p.platform_name
ORDER BY total_bets DESC;


-- ---------------------------------------------------------
-- CASH MOVEMENT BY PLATFORM
-- ---------------------------------------------------------

SELECT
    p.platform_name,

    SUM(t.amount) FILTER (
        WHERE t.transaction_type = 'DEPOSIT'
    ) AS deposits,

    SUM(t.amount) FILTER (
        WHERE t.transaction_type = 'WITHDRAWAL'
    ) AS withdrawals,

    SUM(t.amount) FILTER (
        WHERE t.transaction_type = 'STAKE'
    ) AS stakes,

    SUM(t.amount) FILTER (
        WHERE t.transaction_type = 'PAYOUT'
    ) AS payouts,

    SUM(t.amount) AS current_cash_balance

FROM transactions AS t
JOIN platforms AS p
    ON p.platform_id = t.platform_id
GROUP BY p.platform_name
ORDER BY p.platform_name;


-- ---------------------------------------------------------
-- MONTHLY CASH MOVEMENT
-- This is not yet the same thing as true monthly profit.
-- ---------------------------------------------------------

SELECT
    DATE_TRUNC('month', occurred_at)::DATE
        AS month,

    SUM(amount)::NUMERIC(12,2)
        AS net_cash_movement

FROM transactions
GROUP BY DATE_TRUNC('month', occurred_at)
ORDER BY month;