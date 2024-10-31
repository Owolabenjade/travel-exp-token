;; Experience Token Economy Smart Contract
;; A fungible token system for the travel industry

;; Constants
(define-constant contract-owner tx-sender)
(define-constant token-name "Experience Token")
(define-constant token-symbol "EXP")
(define-constant token-decimals u6)
(define-constant err-owner-only (err u100))
(define-constant err-not-enough-balance (err u101))
(define-constant err-not-enough-stake (err u102))
(define-constant err-invalid-partner (err u103))
(define-constant err-already-voted (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-invalid-recipient (err u106))
(define-constant err-invalid-points (err u107))
(define-constant err-overflow (err u108))
(define-constant minimum-stake-amount u1000)
(define-constant reward-cooldown-period u144) ;; ~24 hours in blocks
(define-constant maximum-supply u1000000000000) ;; 1 trillion tokens
(define-constant maximum-multiplier u1000) ;; 10x multiplier max

;; Data Variables
(define-data-var total-supply uint u0)
(define-data-var exchange-rate uint u100) ;; 1 STX = 100 EXP tokens
(define-data-var season-multiplier uint u100) ;; Base multiplier (100 = 1x)

;; Data Maps
(define-map balances principal uint)
(define-map stakes { staker: principal } { amount: uint, timestamp: uint })
(define-map partners principal bool)
(define-map partner-votes { partner: principal } { votes: uint })
(define-map last-reward-claim principal uint)
(define-map user-travel-points principal uint)

;; SFT Definition
(define-fungible-token exp-token)

;; Helper Functions
(define-private (check-amount (amount uint))
    (and (> amount u0) 
         (< (+ amount (var-get total-supply)) maximum-supply)))

(define-private (check-recipient (recipient principal))
    (not (is-eq recipient (as-contract tx-sender))))

(define-private (check-points (points uint))
    (and (> points u0) (< points u1000000))) ;; Reasonable points limit

(define-private (check-multiplier (multiplier uint))
    (and (>= multiplier u1) (<= multiplier maximum-multiplier)))

;; Read-only functions
(define-read-only (get-name)
    (ok token-name))

(define-read-only (get-symbol)
    (ok token-symbol))

(define-read-only (get-decimals)
    (ok token-decimals))

(define-read-only (get-balance (account principal))
    (ok (default-to u0 (map-get? balances account))))

(define-read-only (get-total-supply)
    (ok (var-get total-supply)))

(define-read-only (get-stake-amount (staker principal))
    (ok (default-to 
        { amount: u0, timestamp: u0 } 
        (map-get? stakes { staker: staker }))))

(define-read-only (is-partner (account principal))
    (default-to false (map-get? partners account)))

;; Token Management Functions
(define-public (mint (amount uint) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (check-amount amount) err-invalid-amount)
        (asserts! (check-recipient recipient) err-invalid-recipient)
        (try! (ft-mint? exp-token amount recipient))
        (var-set total-supply (+ (var-get total-supply) amount))
        (ok true)))

(define-public (burn (amount uint))
    (begin
        (asserts! (check-amount amount) err-invalid-amount)
        (asserts! (<= amount (var-get total-supply)) err-invalid-amount)
        (try! (ft-burn? exp-token amount tx-sender))
        (var-set total-supply (- (var-get total-supply) amount))
        (ok true)))

;; Travel Activity and Rewards
(define-public (earn-from-activity (points uint))
    (let ((current-points (default-to u0 (map-get? user-travel-points tx-sender)))
          (multiplier (var-get season-multiplier)))
        (begin
            (asserts! (check-points points) err-invalid-points)
            (asserts! (check-multiplier multiplier) err-invalid-amount)
            (let ((season-adjusted-points (/ (* points multiplier) u100)))
                (asserts! (check-amount season-adjusted-points) err-overflow)
                (map-set user-travel-points 
                    tx-sender 
                    (+ current-points season-adjusted-points))
                (try! (mint season-adjusted-points tx-sender))
                (ok true)))))

(define-public (book-experience (partner principal) (cost uint))
    (begin
        (asserts! (is-partner partner) err-invalid-partner)
        (asserts! (check-amount cost) err-invalid-amount)
        (try! (ft-transfer? exp-token cost tx-sender partner))
        (ok true)))

;; Staking System
(define-public (stake (amount uint))
    (let ((current-stake (get-stake-info tx-sender)))
        (begin
            (asserts! (check-amount amount) err-invalid-amount)
            (asserts! (>= amount minimum-stake-amount) err-not-enough-stake)
            (try! (ft-transfer? exp-token amount tx-sender (as-contract tx-sender)))
            (map-set stakes 
                { staker: tx-sender }
                { amount: (+ amount (get amount current-stake)),
                  timestamp: block-height })
            (ok true))))

(define-public (unstake (amount uint))
    (let ((current-stake (get-stake-info tx-sender)))
        (begin
            (asserts! (check-amount amount) err-invalid-amount)
            (asserts! (>= (get amount current-stake) amount) err-not-enough-stake)
            (try! (as-contract (ft-transfer? exp-token amount (as-contract tx-sender) tx-sender)))
            (map-set stakes
                { staker: tx-sender }
                { amount: (- (get amount current-stake) amount),
                  timestamp: block-height })
            (ok true))))

;; Partner Management and Voting
(define-public (propose-partner (new-partner principal))
    (begin
        (asserts! (check-recipient new-partner) err-invalid-recipient)
        (asserts! (is-some (map-get? stakes { staker: tx-sender })) err-not-enough-stake)
        (map-set partner-votes 
            { partner: new-partner }
            { votes: u0 })
        (ok true)))

(define-public (vote-for-partner (partner principal))
    (let ((stake-info (get-stake-info tx-sender))
          (current-votes (default-to 
            { votes: u0 }
            (map-get? partner-votes { partner: partner }))))
        (begin
            (asserts! (check-recipient partner) err-invalid-recipient)
            (asserts! (>= (get amount stake-info) minimum-stake-amount) err-not-enough-stake)
            (map-set partner-votes
                { partner: partner }
                { votes: (+ (get votes current-votes) (get amount stake-info)) })
            (ok true))))

(define-public (add-partner (partner principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (check-recipient partner) err-invalid-recipient)
        (map-set partners partner true)
        (ok true)))

;; Seasonal Adjustments
(define-public (set-season-multiplier (multiplier uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (check-multiplier multiplier) err-invalid-amount)
        (var-set season-multiplier multiplier)
        (ok true)))

;; Helper Functions
(define-private (get-stake-info (staker principal))
    (default-to 
        { amount: u0, timestamp: u0 }
        (map-get? stakes { staker: staker })))

;; Initialize Contract
(begin
    (try! (ft-mint? exp-token u1000000000 contract-owner))
    (var-set total-supply u1000000000))