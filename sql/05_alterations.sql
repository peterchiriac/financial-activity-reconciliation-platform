-- =========================================================
-- Matched Betting Analytics Platform
-- Schema alterations and migrations
-- =========================================================


-- ---------------------------------------------------------
-- MIGRATION 001
-- Permit bank accounts and digital wallets in platforms.
-- ---------------------------------------------------------

ALTER TABLE platforms
DROP CONSTRAINT IF EXISTS platforms_platform_type_check;

ALTER TABLE platforms
ADD CONSTRAINT platforms_platform_type_check
CHECK (
    platform_type IN (
        'BOOKMAKER',
        'EXCHANGE',
        'BANK',
        'WALLET'
    )
);


-- ---------------------------------------------------------
-- MIGRATION 002
-- Add the financial transaction ledger.
-- ---------------------------------------------------------

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    platform_id INTEGER NOT NULL
        REFERENCES platforms(platform_id),

    bet_id INTEGER
        REFERENCES bets(bet_id),

    promotion_id INTEGER
        REFERENCES promotions(promotion_id),

    reward_id INTEGER
        REFERENCES rewards(reward_id),

    transaction_type VARCHAR(30) NOT NULL
        CHECK (
            transaction_type IN (
                'OPENING_BALANCE',
                'DEPOSIT',
                'WITHDRAWAL',
                'STAKE',
                'PAYOUT',
                'COMMISSION',
                'CASH_REWARD',
                'REFUND',
                'ADJUSTMENT'
            )
        ),

    amount NUMERIC(12,2) NOT NULL
        CHECK (amount <> 0),

    external_reference VARCHAR(150),

    transfer_reference VARCHAR(100),

    occurred_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);


-- ---------------------------------------------------------
-- MIGRATION 003
-- Add indexes for commonly joined and filtered columns.
-- ---------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_promotions_platform_id
    ON promotions(platform_id);

CREATE INDEX IF NOT EXISTS idx_bets_platform_id
    ON bets(platform_id);

CREATE INDEX IF NOT EXISTS idx_bets_promotion_id
    ON bets(promotion_id);

CREATE INDEX IF NOT EXISTS idx_bets_status
    ON bets(bet_status);

CREATE INDEX IF NOT EXISTS idx_bet_legs_bet_id
    ON bet_legs(bet_id);

CREATE INDEX IF NOT EXISTS idx_rewards_promotion_id
    ON rewards(promotion_id);

CREATE INDEX IF NOT EXISTS idx_rewards_status
    ON rewards(reward_status);

CREATE INDEX IF NOT EXISTS idx_transactions_platform_id
    ON transactions(platform_id);

CREATE INDEX IF NOT EXISTS idx_transactions_bet_id
    ON transactions(bet_id);

CREATE INDEX IF NOT EXISTS idx_transactions_occurred_at
    ON transactions(occurred_at);

-- =========================================================
-- MIGRATION 004
-- Expand transaction types to distinguish transfers.
-- =========================================================

ALTER TABLE transactions
DROP CONSTRAINT IF EXISTS transactions_transaction_type_check;

ALTER TABLE transactions
ADD CONSTRAINT transactions_transaction_type_check
CHECK (
    transaction_type IN (
        'OPENING_BALANCE',
        'DEPOSIT',
        'WITHDRAWAL',
        'TRANSFER_IN',
        'TRANSFER_OUT',
        'STAKE',
        'PAYOUT',
        'COMMISSION',
        'CASH_REWARD',
        'REFUND',
        'ADJUSTMENT'
    )
);

-- =========================================================
-- MIGRATION 005
-- Record which bet used a reward.
-- =========================================================

ALTER TABLE rewards
ADD COLUMN used_bet_id INTEGER
REFERENCES bets(bet_id);