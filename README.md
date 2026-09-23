Financial Activity & Reconciliation Platform

A PostgreSQL relational data system for modelling transactions, betting positions, promotional assets, liabilities and account balances across multiple financial platforms.

The project uses matched betting as its business domain, creating a non-trivial accounting problem involving cash movements, linked financial positions, promotional assets with distinct lifecycles, settlement events and reconciliation across independent platforms.

Why I Built It

Matched betting activity quickly becomes difficult to reconcile when spread across multiple bookmakers, exchanges and funding accounts.

A single promotional cycle can involve:

* capital moving between accounts
* a qualifying position
* an offsetting exchange position
* a promotional reward being generated
* the reward being used in a subsequent position
* further hedging activity
* settlement across different platforms
* cash eventually being withdrawn or redeployed

Tracking only account balances loses the relationships between these events.

I built this project to explore how a relational database could represent the underlying system while preserving enough history to reconstruct balances, investigate discrepancies and analyse profitability.

System Design

The database separates different business concepts rather than storing activity in a single flat structure.

The principal entities include:

platforms

Represents bookmakers, betting exchanges, bank accounts and wallets through which financial activity flows.

promotions

Represents promotional offers and their qualification requirements, status and expected reward.

This allows an offer to move through a defined lifecycle from availability through qualification, reward crediting and completion.

bets

Stores financial positions placed with bookmakers and exchanges.

The model distinguishes BACK and LAY positions and records stake, odds, liability, commission, settlement state, cash return and relevant timestamps.

bet_legs

Separates individual selections from the parent bet, allowing multi-selection positions such as accumulators to be represented without duplicating the parent transaction.

rewards

Represents promotional assets separately from both cash and bets.

A reward can be linked to the qualifying activity that generated it and the subsequent activity through which it was converted, providing traceability across the promotional lifecycle.

transactions

Functions as the system’s cash ledger.

Deposits, withdrawals and transfers are preserved as individual financial events rather than repeatedly overwriting an account balance.

This allows balances to be reconstructed from historical activity and provides an audit trail for reconciliation.

Relational Modelling

One of the main challenges in the project has been representing relationships between positions placed on independent platforms.

A bookmaker BACK position may be offset by an exchange LAY position, while more complex strategies can introduce relationships that are not naturally represented by a simple one-to-one link.

The schema has therefore evolved as additional real activity exposed limitations in earlier modelling assumptions.

This has made the project an ongoing exercise in relational modelling: identifying entities, determining appropriate relationships and cardinalities, and refactoring the schema when the real-world process no longer fits the original abstraction.

Promotional Lifecycle

The system preserves the relationship between promotional qualification and eventual value extraction:

Promotion
    ↓
Qualifying Activity
    ↓
  Reward
    ↓
Reward Usage
    ↓
Cash Value

This makes it possible to distinguish promotional face value from realised cash value and analyse the complete lifecycle rather than treating rewards as ordinary deposits.

Reconciliation and Derived Data

Rather than storing every calculated metric directly in the base tables, PostgreSQL views provide reusable analytical layers over the underlying records.

v_bet_reconciliation

Calculates the financial result of settled positions while accounting for differences between:

* cash-backed bookmaker positions
* promotional/free-bet positions
* exchange wins
* exchange losses and liabilities
* commission

This produces a consistent derived net_result without duplicating calculated profit in the base data.

v_platform_transaction_flows

Aggregates ledger activity into money in, money out and net transaction flow by platform.

platform_cash_balances

Combines transaction history with settled position results to reconstruct platform-level cash balances.

platform_overview

Combines cash balances with active promotional assets to provide a broader operational view of value held across platforms.

v_bankroll_summary

Produces portfolio-level measures including external capital, current cash, reserved liabilities, net profit and return on investment.

Data Integrity

Business rules are enforced in PostgreSQL wherever practical rather than relying solely on application behaviour.

The schema uses:

* primary and foreign keys
* controlled status values
* CHECK constraints
* positive stake and odds requirements
* liability validation
* referential integrity between related entities
* unique leg numbering within bets

For example, LAY positions require a liability while BACK positions must not contain one.

These constraints prevent several classes of invalid record from entering the system.

Accounting Approach

The project follows a ledger-oriented approach.

Financial movements are stored as immutable transaction records rather than maintaining a manually updated balance field.

Current balances can therefore be derived from:

transaction history
        +
settled position P&L
        ↓
reconstructed balance

This provides a clearer audit trail and makes discrepancies easier to investigate.

What I Learned

The project began as a practical tracking tool but developed into a broader exercise in database design.

Working with real activity exposed modelling problems that were not obvious when designing the initial schema. In particular, relationships that initially appeared one-to-one became more complex as additional cases were encountered.

This required revisiting earlier assumptions, migrating existing data and separating concepts that had initially been combined.

The project has strengthened my understanding of:

* relational data modelling
* schema evolution
* referential integrity
* financial reconciliation
* derived versus stored data
* data quality and validation
* designing around real business processes rather than idealised datasets

Current Status

The PostgreSQL system currently supports:

* financial transaction tracking
* position and settlement recording
* promotional lifecycle tracking
* reward tracking
* cross-platform reconciliation
* platform balance reconstruction
* liability and exposure reporting
* portfolio-level profitability analysis

Some historical records were reconstructed manually from account histories, so certain historical timestamps and relationships remain incomplete.

Data ingestion and reconciliation are currently primarily manual.

Next Steps

The current database provides the foundation for moving from manual recording toward an automated data pipeline.

Planned areas for development include:

* Python-based data ingestion
* repeatable and idempotent loading processes
* automated data-quality checks
* automated reconciliation
* logging and error handling
* testing
* analytical dashboards
* orchestration of recurring workflows

These additions would extend the project from a relational accounting system toward a small end-to-end data engineering pipeline.

Technology

Current

* PostgreSQL
* SQL
* relational data modelling
* PostgreSQL views
* constraints and referential integrity
* Git / GitHub

Planned

* Python
* automated ingestion
* testing
* orchestration
* analytical visualisation
