(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-already-voted (err u106))

(define-data-var next-story-id uint u1)
(define-data-var truth-token-price uint u1000000)
(define-data-var reputation-threshold uint u70)

(define-map stories
  { story-id: uint }
  {
    author: principal,
    content-hash: (buff 32),
    timestamp: uint,
    is-anonymous: bool,
    access-price: uint,
    total-stake-believe: uint,
    total-stake-dispute: uint,
    is-active: bool
  }
)

(define-map story-permissions
  { story-id: uint, viewer: principal }
  { granted: bool, granted-at: uint }
)

(define-map stakes
  { story-id: uint, staker: principal }
  { amount: uint, position: bool, staked-at: uint }
)

(define-map user-balances
  { user: principal }
  { balance: uint }
)

(define-map user-reputation
  { user: principal }
  {
    correct-stakes: uint,
    total-stakes: uint,
    reputation-score: uint,
    last-updated: uint
  }
)

(define-read-only (get-story (story-id uint))
  (map-get? stories { story-id: story-id })
)

(define-read-only (get-permission (story-id uint) (viewer principal))
  (map-get? story-permissions { story-id: story-id, viewer: viewer })
)

(define-read-only (get-stake (story-id uint) (staker principal))
  (map-get? stakes { story-id: story-id, staker: staker })
)

(define-read-only (get-user-balance (user principal))
  (default-to u0 (get balance (map-get? user-balances { user: user })))
)

(define-read-only (get-next-story-id)
  (var-get next-story-id)
)

(define-read-only (get-truth-token-price)
  (var-get truth-token-price)
)

(define-read-only (get-user-reputation (user principal))
  (default-to 
    { correct-stakes: u0, total-stakes: u0, reputation-score: u50, last-updated: u0 }
    (map-get? user-reputation { user: user })
  )
)

(define-read-only (is-reputable-user (user principal))
  (>= (get reputation-score (get-user-reputation user)) (var-get reputation-threshold))
)

(define-read-only (can-view-story (story-id uint) (viewer principal))
  (let ((story (unwrap! (get-story story-id) false)))
    (if (is-eq (get author story) viewer)
      true
      (if (get is-anonymous story)
        (is-some (get-permission story-id viewer))
        true
      )
    )
  )
)

(define-read-only (get-story-stats (story-id uint))
  (let ((story (unwrap! (get-story story-id) (err err-not-found))))
    (ok {
      total-stake-believe: (get total-stake-believe story),
      total-stake-dispute: (get total-stake-dispute story),
      credibility-score: (if (> (+ (get total-stake-believe story) (get total-stake-dispute story)) u0)
        (/ (* (get total-stake-believe story) u100) (+ (get total-stake-believe story) (get total-stake-dispute story)))
        u50
      )
    })
  )
)

(define-public (register-story (content-hash (buff 32)) (is-anonymous bool) (access-price uint))
  (let ((story-id (var-get next-story-id)))
    (asserts! (> (len content-hash) u0) (err err-invalid-amount))
    (map-set stories
      { story-id: story-id }
      {
        author: tx-sender,
        content-hash: content-hash,
        timestamp: stacks-block-height,
        is-anonymous: is-anonymous,
        access-price: access-price,
        total-stake-believe: u0,
        total-stake-dispute: u0,
        is-active: true
      }
    )
    (var-set next-story-id (+ story-id u1))
    (ok story-id)
  )
)

(define-public (grant-access (story-id uint) (viewer principal))
  (let ((story (unwrap! (get-story story-id) (err err-not-found))))
    (asserts! (is-eq (get author story) tx-sender) (err err-unauthorized))
    (asserts! (get is-anonymous story) (err err-unauthorized))
    (map-set story-permissions
      { story-id: story-id, viewer: viewer }
      { granted: true, granted-at: stacks-block-height }
    )
    (ok true)
  )
)

(define-public (revoke-access (story-id uint) (viewer principal))
  (let ((story (unwrap! (get-story story-id) (err err-not-found))))
    (asserts! (is-eq (get author story) tx-sender) (err err-unauthorized))
    (map-delete story-permissions { story-id: story-id, viewer: viewer })
    (ok true)
  )
)

(define-public (buy-truth-tokens (amount uint))
  (let ((cost (* amount (var-get truth-token-price))))
    (asserts! (> amount u0) (err err-invalid-amount))
    (unwrap! (stx-transfer? cost tx-sender contract-owner) (err err-insufficient-funds))
    (map-set user-balances
      { user: tx-sender }
      { balance: (+ (get-user-balance tx-sender) amount) }
    )
    (ok amount)
  )
)

(define-public (stake-on-story (story-id uint) (amount uint) (believe bool))
  (let (
    (story (unwrap! (get-story story-id) (err err-not-found)))
    (current-balance (get-user-balance tx-sender))
    (existing-stake (get-stake story-id tx-sender))
  )
    (asserts! (get is-active story) (err err-unauthorized))
    (asserts! (>= current-balance amount) (err err-insufficient-funds))
    (asserts! (> amount u0) (err err-invalid-amount))
    (asserts! (is-none existing-stake) (err err-already-voted))
    
    (map-set user-balances
      { user: tx-sender }
      { balance: (- current-balance amount) }
    )
    
    (map-set stakes
      { story-id: story-id, staker: tx-sender }
      { amount: amount, position: believe, staked-at: stacks-block-height }
    )
    
    (if believe
      (map-set stories
        { story-id: story-id }
        (merge story { total-stake-believe: (+ (get total-stake-believe story) amount) })
      )
      (map-set stories
        { story-id: story-id }
        (merge story { total-stake-dispute: (+ (get total-stake-dispute story) amount) })
      )
    )
    
    (unwrap! (update-reputation-on-stake tx-sender) (err err-unauthorized))
    (ok true)
  )
)

(define-public (withdraw-stake (story-id uint))
  (let (
    (story (unwrap! (get-story story-id) (err err-not-found)))
    (stake-info (unwrap! (get-stake story-id tx-sender) (err err-not-found)))
    (stake-amount (get amount stake-info))
    (stake-position (get position stake-info))
    (current-balance (get-user-balance tx-sender))
  )
    (map-delete stakes { story-id: story-id, staker: tx-sender })
    
    (map-set user-balances
      { user: tx-sender }
      { balance: (+ current-balance stake-amount) }
    )
    
    (if stake-position
      (map-set stories
        { story-id: story-id }
        (merge story { total-stake-believe: (- (get total-stake-believe story) stake-amount) })
      )
      (map-set stories
        { story-id: story-id }
        (merge story { total-stake-dispute: (- (get total-stake-dispute story) stake-amount) })
      )
    )
    
    (ok stake-amount)
  )
)

(define-public (deactivate-story (story-id uint))
  (let ((story (unwrap! (get-story story-id) (err err-not-found))))
    (asserts! (is-eq (get author story) tx-sender) (err err-unauthorized))
    (map-set stories
      { story-id: story-id }
      (merge story { is-active: false })
    )
    (ok true)
  )
)

(define-public (update-reputation-on-stake (user principal))
  (let (
    (current-rep (get-user-reputation user))
    (new-total (+ (get total-stakes current-rep) u1))
  )
    (map-set user-reputation
      { user: user }
      {
        correct-stakes: (get correct-stakes current-rep),
        total-stakes: new-total,
        reputation-score: (if (> new-total u0)
          (/ (* (get correct-stakes current-rep) u100) new-total)
          u50
        ),
        last-updated: stacks-block-height
      }
    )
    (ok true)
  )
)

(define-public (update-reputation-on-resolution (story-id uint))
  (let (
    (story (unwrap! (get-story story-id) (err err-not-found)))
    (winning-side (> (get total-stake-believe story) (get total-stake-dispute story)))
  )
    (asserts! (is-eq (get author story) tx-sender) (err err-unauthorized))
    (ok (update-staker-reputations story-id winning-side))
  )
)

(define-private (update-staker-reputations (story-id uint) (winning-side bool))
  true
)

(define-public (claim-reputation-bonus (story-id uint))
  (let (
    (story (unwrap! (get-story story-id) (err err-not-found)))
    (stake-info (unwrap! (get-stake story-id tx-sender) (err err-not-found)))
    (user-rep (get-user-reputation tx-sender))
    (was-correct (is-eq (get position stake-info) (> (get total-stake-believe story) (get total-stake-dispute story))))
  )
    (asserts! (not (get is-active story)) (err err-unauthorized))
    (if was-correct
      (let ((new-correct (+ (get correct-stakes user-rep) u1)))
        (map-set user-reputation
          { user: tx-sender }
          {
            correct-stakes: new-correct,
            total-stakes: (get total-stakes user-rep),
            reputation-score: (if (> (get total-stakes user-rep) u0)
              (/ (* new-correct u100) (get total-stakes user-rep))
              u50
            ),
            last-updated: stacks-block-height
          }
        )
        (ok true)
      )
      (ok false)
    )
  )
)

(define-public (set-reputation-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-owner-only))
    (asserts! (<= new-threshold u100) (err err-invalid-amount))
    (var-set reputation-threshold new-threshold)
    (ok true)
  )
)

(define-public (set-truth-token-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-owner-only))
    (var-set truth-token-price new-price)
    (ok true)
  )
)
