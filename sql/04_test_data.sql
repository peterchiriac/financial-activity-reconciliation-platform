-- =========================================================
-- Matched Betting Analytics Platform
-- Temporary test data
--
-- This script ends with ROLLBACK, so the test records will
-- disappear after the script has finished.
-- =========================================================

BEGIN;


-- ---------------------------------------------------------
-- TEST PLATFORMS
-- ---------------------------------------------------------

INSERT INTO platforms (
    platform_name,
    platform_type,
    default_commission_rate
)
VALUES
    ('Test Bank', 'BANK', 0),
    ('Test Bookmaker', 'BOOKMAKER', 0),
    ('Test Exchange', 'EXCHANGE', 0.02)
ON CONFLICT (platform_name) DO NOTHING;


-- ---------------------------------------------------------
-- TEST CASH MOVEMENTS
-- ---------------------------------------------------------

INSERT INTO transactions (
    platform_id,
    transaction_type,
    amount,
    notes
)
SELECT
    platform_id,
    'OPENING_BALANCE',
    1000.00,
    'Temporary opening balance'
FROM platforms
WHERE platform_name = 'Test Bank';


-- £50 leaves the bank.

INSERT INTO transactions (
    platform_id,
    transaction_type,
    amount,
    transfer_reference,
    notes
)
SELECT
    platform_id,
    'WITHDRAWAL',
    -50.00,
    'TEST-TRANSFER-001',
    'Transfer from bank to bookmaker'
FROM platforms
WHERE platform_name = 'Test Bank';


-- The same £50 enters the bookmaker.

INSERT INTO transactions (
    platform_id,
    transaction_type,
    amount,
    transfer_reference,
    notes
)
SELECT
    platform_id,
    'DEPOSIT',
    50.00,
    'TEST-TRANSFER-001',
    'Transfer from bank to bookmaker'
FROM platforms
WHERE platform_name = 'Test Bookmaker';


-- £10 qualifying stake.

INSERT INTO transactions (
    platform_id,
    transaction_type,
    amount,
    notes
)
SELECT
    platform_id,
    'STAKE',
    -10.00,
    'Temporary qualifying stake'
FROM platforms
WHERE platform_name = 'Test Bookmaker';


-- £15 bookmaker payout.

INSERT INTO transactions (
    platform_id,
    transaction_type,
    amount,
    notes
)
SELECT
    platform_id,
    'PAYOUT',
    15.00,
    'Temporary winning payout'
FROM platforms
WHERE platform_name = 'Test Bookmaker';


-- ---------------------------------------------------------
-- INSPECT THE RESULT
-- ---------------------------------------------------------

SELECT *
FROM platform_cash_balances
ORDER BY platform_name;

SELECT *
FROM total_assets;


-- Change ROLLBACK to COMMIT only when you deliberately wish
-- to retain the inserted data.

ROLLBACK;