# TravelXP - Travel Experience Token Economy

TravelXP introduces EXP tokens (Experience Tokens) that serve as the backbone of a travel rewards and booking system. The ecosystem allows travelers to earn tokens through activities, book experiences, and participate in community governance through staking.

## Use Case Scenario

Consider "World Explorers Travel Agency" implementing TravelXP:

1. A traveler books a 7-day tour to Japan through the agency
2. For each activity completed:
   - Mount Fuji hiking tour → Earns 100 EXP
   - Tea ceremony participation → Earns 50 EXP
   - Kyoto temple visit → Earns 75 EXP

3. The earned tokens can be:
   - Used to book future experiences
   - Staked for travel insurance benefits
   - Used to vote on new travel partners

During peak season, the multiplier increases, making activities more rewarding.

## Features

### Token Management
- Minting and burning capabilities
- Maximum supply of 1 trillion tokens
- Exchange rate management (1 STX = 100 EXP)

### Travel Activities & Rewards
- Earn tokens through verified travel activities
- Dynamic seasonal multipliers
- Points-to-token conversion system

### Booking System
- Book experiences using EXP tokens
- Partner verification system
- Direct token transfers for bookings

### Staking Mechanism
- Minimum stake: 1000 EXP
- Travel insurance benefits
- Staking required for governance participation

### Partner System
- Community-driven partner additions
- Voting weight based on stake amount
- Partner verification by contract owner

### Seasonal Adjustments
- Dynamic pricing through multipliers
- Maximum 10x multiplier
- Owner-controlled adjustments

## Functions

### Public Functions
```clarity
(mint (amount uint) (recipient principal))
(burn (amount uint))
(earn-from-activity (points uint))
(book-experience (partner principal) (cost uint))
(stake (amount uint))
(unstake (amount uint))
(propose-partner (new-partner principal))
(vote-for-partner (partner principal))
(add-partner (partner principal))
(set-season-multiplier (multiplier uint))
```

### Read-Only Functions
```clarity
(get-name)
(get-symbol)
(get-decimals)
(get-balance (account principal))
(get-total-supply)
(get-stake-amount (staker principal))
(is-partner (account principal))
```

## Error Codes

- `err-owner-only (100)`: Only contract owner can perform this action
- `err-not-enough-balance (101)`: Insufficient token balance
- `err-not-enough-stake (102)`: Stake amount below minimum requirement
- `err-invalid-partner (103)`: Partner not verified
- `err-already-voted (104)`: Already voted for this proposal
- `err-invalid-amount (105)`: Invalid token amount
- `err-invalid-recipient (106)`: Invalid recipient address
- `err-invalid-points (107)`: Invalid points amount
- `err-overflow (108)`: Arithmetic overflow error

## Security Features

- Input validation for all public functions
- Overflow protection for mathematical operations
- Principal validation for all transfers
- Maximum supply and multiplier limits
- Stake-based voting weight
- Owner-only administrative functions

## Getting Started

1. Deploy the contract to Stacks blockchain
2. Initialize with base exchange rate and seasonal multiplier
3. Add initial verified partners
4. Set appropriate minimum stake amounts
5. Begin user onboarding

## Integration Example

```clarity
;; Mint initial tokens to travel agency
(contract-call? .travel-xp-economy mint u1000000 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)

;; Add new partner
(contract-call? .travel-xp-economy add-partner 'SP2X0MC9YQRQJ85F3JY0H6RJ6YXRQQXN7AR0XCVFN)

;; User books experience
(contract-call? .travel-xp-economy book-experience 'SP2X0MC9YQRQJ85F3JY0H6RJ6YXRQQXN7AR0XCVFN u100)
```