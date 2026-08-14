-- =========================================================
-- Matched Betting Analytics Platform
-- Version 1: Core operational schema
-- =========================================================


-- 1. PLATFORMS
-- Stores bookmakers, exchanges, bank account, and wallets.

CREATE TABLE platforms (
    platform_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    platform_name VARCHAR(100) NOT NULL
        UNIQUE,

    platform_type VARCHAR(20) NOT NULL
    CHECK (
        platform_type IN (
            'BOOKMAKER',
            'EXCHANGE',
            'BANK',
            'WALLET'
        )
    ),

    default_commission_rate NUMERIC(5,4) NOT NULL DEFAULT 0
        CHECK (
            default_commission_rate >= 0
            AND default_commission_rate <= 1
        ),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- 2. PROMOTIONS
-- Stores bookmaker offers and their qualification requirements.

CREATE TABLE promotions (
    promotion_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    platform_id INTEGER NOT NULL
        REFERENCES platforms(platform_id),

    promotion_name VARCHAR(150) NOT NULL,

    promo_code VARCHAR(50),

    qualifying_stake NUMERIC(10,2)
        CHECK (qualifying_stake > 0),

    minimum_odds NUMERIC(10,3)
        CHECK (minimum_odds > 1),

    minimum_selections INTEGER
        CHECK (minimum_selections >= 1),

    reward_value NUMERIC(10,2)
        CHECK (reward_value > 0),

    reward_type VARCHAR(30)
        CHECK (
            reward_type IN (
                'FREE_BET',
                'CASH',
                'BONUS',
                'OTHER'
            )
        ),

    promotion_status VARCHAR(30) NOT NULL DEFAULT 'AVAILABLE'
        CHECK (
            promotion_status IN (
                'AVAILABLE',
                'QUALIFYING_BET_PLACED',
                'REWARD_CREDITED',
                'COMPLETED',
                'EXPIRED',
                'CANCELLED'
            )
        ),

    expires_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- 3. BETS
-- Stores both bookmaker back bets and exchange lay bets.

CREATE TABLE bets (
    bet_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    platform_id INTEGER NOT NULL
        REFERENCES platforms(platform_id),

    promotion_id INTEGER
        REFERENCES promotions(promotion_id),

    related_bet_id INTEGER
        REFERENCES bets(bet_id),
        
    stake_type VARCHAR(20) NOT NULL DEFAULT 'CASH'
    	CHECK (
    		stake_type IN (
    			'CASH',
    			'FREE_BET',
    			'BONUS_CASH'
    		)
    	),

    bet_side VARCHAR(10) NOT NULL
        CHECK (bet_side IN ('BACK', 'LAY')),

    bet_type VARCHAR(30) NOT NULL
        CHECK (
            bet_type IN (
                'SINGLE',
                'ACCUMULATOR',
                'BET_BUILDER'
            )
        ),

    stake NUMERIC(10,2) NOT NULL
        CHECK (stake > 0),

    decimal_odds NUMERIC(10,3) NOT NULL
        CHECK (decimal_odds > 1),

    liability NUMERIC(10,2)
        CHECK (liability >= 0),

    commission_rate NUMERIC(5,4) NOT NULL DEFAULT 0
        CHECK (
            commission_rate >= 0
            AND commission_rate <= 1
        ),

    bet_status VARCHAR(20) NOT NULL DEFAULT 'OPEN'
        CHECK (
            bet_status IN (
                'OPEN',
                'WON',
                'LOST',
                'VOID',
                'CASHED_OUT'
            )
        ),

    cash_return NUMERIC(10,2)
        CHECK (cash_return >= 0),

    placed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    settled_at TIMESTAMPTZ,

    related_bet_leg_id INTEGER,

    notes TEXT,

    CHECK (
        (bet_side = 'BACK' AND liability IS NULL)
        OR
        (bet_side = 'LAY' AND liability IS NOT NULL)
    )
);


-- 4. BET LEGS
-- Stores the individual selections contained within each bet.

CREATE TABLE bet_legs (
    bet_leg_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    bet_id INTEGER NOT NULL
        REFERENCES bets(bet_id)
        ON DELETE CASCADE,

    leg_number INTEGER NOT NULL
        CHECK (leg_number >= 1),

    sport VARCHAR(50) NOT NULL,

    competition VARCHAR(150),

    event_name VARCHAR(200) NOT NULL,

    selection_name VARCHAR(150) NOT NULL,

    market_name VARCHAR(100) NOT NULL,

    selection_odds NUMERIC(10,3)
        CHECK (selection_odds > 1),

    event_start_at TIMESTAMPTZ,

    leg_status VARCHAR(20) NOT NULL DEFAULT 'OPEN'
        CHECK (
            leg_status IN (
                'OPEN',
                'WON',
                'LOST',
                'VOID'
            )
        ),

    UNIQUE (bet_id, leg_number)
);


ALTER TABLE bets
ADD CONSTRAINT fk_bets_related_leg
FOREIGN KEY (related_bet_leg_id)
REFERENCES bet_legs(bet_leg_id);

-- 5. REWARDS
-- Stores free bets, cash rewards and other promotional benefits.

CREATE TABLE rewards (
    reward_id INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    promotion_id INTEGER NOT NULL
        REFERENCES promotions(promotion_id),

    qualifying_bet_id INTEGER
        REFERENCES bets(bet_id),
     
    used_bet_id INTEGER
    	REFERENCES bets(bet_id),

    reward_type VARCHAR(30) NOT NULL
        CHECK (
            reward_type IN (
                'FREE_BET',
                'CASH',
                'BONUS',
                'OTHER'
            )
        ),

    face_value NUMERIC(10,2) NOT NULL
        CHECK (face_value > 0),

    reward_status VARCHAR(30) NOT NULL DEFAULT 'EXPECTED'
        CHECK (
            reward_status IN (
                'EXPECTED',
                'CREDITED',
                'USED',
                'EXPIRED',
                'REVOKED'
            )
        ),

    credited_at TIMESTAMPTZ,

    expires_at TIMESTAMPTZ,

    converted_cash_value NUMERIC(10,2)
        CHECK (converted_cash_value >= 0),

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 6. TRANSACTIONS
-- Records every movement that changes a cash balance.
--
-- Positive amount: money entering an account.
-- Negative amount: money leaving an account.
-- =========================================================

CREATE TABLE transactions (
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
                'TRANSFER_IN',
                'TRANSFER_OUT',
                'DEPOSIT',
                'WITHDRAWAL',
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