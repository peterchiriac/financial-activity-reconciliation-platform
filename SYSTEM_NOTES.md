## 1. Purpose of each table

- **platforms** – Stores every platform the system interacts with (bookmakers, exchanges, and bank accounts).

- **promotions** – Stores bookmaker promotions and their current status.

- **bets** – Stores every back and lay bet placed.

- **bet_legs** – Stores the individual legs of accumulator bets.

- **rewards** – Stores rewards earned from promotions (e.g. free bets).

- **transactions** – Stores money transfers between platforms and accounts (deposits, withdrawals, transfers, adjustments).

## 2. Business rules

### Bets

- Every bet belongs to one platform.
- A bet is either a BACK or a LAY bet.
- A bet is either CASH or FREE_BET.
- Only accumulator bets have entries in `bet_legs`.

### Lay bets

- `stake` is the lay stake.
- `liability` is the maximum amount that can be lost.

### Rewards

- Rewards are earned through promotions.
- Rewards can be used on future bets.

### Cash

- `cash_return` is the cash credited back to the platform after settlement.
- Deposits and withdrawals belong in `transactions`.
- Free bets belong in `rewards`, not `transactions`.



## 3. Recording workflow

1. Create the platform (once).
2. Create the promotion.
3. Record the qualifying bet.
4. Record any accumulator legs (if applicable).
5. Record the corresponding lay bet(s).
6. Update the bet settlement.
7. Record the reward.
8. Record the reward bet.
9. Record any reward lay bet(s).
10. Update the promotion status.


## 4. Open questions

- Should `placed_at` allow `NULL`?
- Should exchange partial fills be recorded individually?
- Should `transactions` ever include bet settlements?
- How should multiple lay bets on the same accumulator leg be represented?
- Should bookmaker reference IDs be stored?
- Should exchange reference IDs be stored?
- Should deposits and withdrawals be imported automatically?
