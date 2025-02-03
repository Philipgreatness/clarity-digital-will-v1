;; Digital Will Contract with Multiple Beneficiaries
(define-map wills
    { owner: principal }
    {
        beneficiaries: (list 10 {beneficiary: principal, share: uint}),
        total-amount: uint,
        last-active: uint,
        inheritance-delay: uint
    }
)

(define-map beneficiary-claims
    { beneficiary: principal, owner: principal }
    { claimed: bool }
)

(define-constant err-not-owner (err u100))
(define-constant err-already-claimed (err u101))
(define-constant err-no-will (err u102))
(define-constant err-delay-not-met (err u103))
(define-constant err-owner-still-active (err u104))
(define-constant err-invalid-shares (err u105))
(define-constant err-too-many-beneficiaries (err u106))
(define-constant err-duplicate-beneficiary (err u107))

;; Create or update will with multiple beneficiaries
(define-public (set-will (beneficiaries (list 10 {beneficiary: principal, share: uint})) (total-amount uint) (inheritance-delay uint))
    (let
        ((total-shares (fold + (map get-share beneficiaries) u0))
         (unique-beneficiaries (len (get-unique-beneficiaries beneficiaries))))
        (asserts! (is-eq total-shares u100) err-invalid-shares)
        (asserts! (is-eq (len beneficiaries) unique-beneficiaries) err-duplicate-beneficiary)
        (begin
            (map-set wills
                { owner: tx-sender }
                {
                    beneficiaries: beneficiaries,
                    total-amount: total-amount,
                    last-active: block-height,
                    inheritance-delay: inheritance-delay
                }
            )
            (ok true)
        )
    )
)

;; Helper function to get share amount
(define-private (get-share (entry {beneficiary: principal, share: uint}))
    (get share entry)
)

;; Helper function to get unique beneficiaries
(define-private (get-unique-beneficiaries (beneficiaries (list 10 {beneficiary: principal, share: uint})))
    (len (fold unique-principals (map get-beneficiary beneficiaries) (list 100 principal)))
)

(define-private (get-beneficiary (entry {beneficiary: principal, share: uint}))
    (get beneficiary entry)
)

(define-private (unique-principals (principal principal) (acc (list 100 principal)))
    (if (is-some (index-of acc principal))
        acc
        (unwrap-panic (as-max-len? (append acc principal) u100))
    )
)

;; Record activity to prevent premature execution
(define-public (record-activity)
    (let (
        (will (unwrap! (get-will tx-sender) err-no-will))
    )
    (begin
        (map-set wills
            { owner: tx-sender }
            (merge will { last-active: block-height })
        )
        (ok true)
    ))
)

;; Claim inheritance for a beneficiary
(define-public (claim-inheritance (owner principal))
    (let (
        (will (unwrap! (get-will owner) err-no-will))
        (claim-status (default-to { claimed: false } (map-get? beneficiary-claims { beneficiary: tx-sender, owner: owner })))
        (beneficiary-info (unwrap! (get-beneficiary-info (get beneficiaries will) tx-sender) err-not-owner))
    )
    (asserts! (not (get claimed claim-status)) err-already-claimed)
    (asserts! (>= (- block-height (get last-active will)) (get inheritance-delay will)) err-delay-not-met)
    (begin
        (try! (stx-transfer? (calculate-share (get total-amount will) (get share beneficiary-info)) owner tx-sender))
        (map-set beneficiary-claims { beneficiary: tx-sender, owner: owner } { claimed: true })
        (ok true)
    ))
)

;; Helper function to find beneficiary info
(define-private (get-beneficiary-info (beneficiaries (list 10 {beneficiary: principal, share: uint})) (check-beneficiary principal))
    (unwrap-panic (element-at beneficiaries (find-beneficiary-index beneficiaries check-beneficiary)))
)

(define-private (find-beneficiary-index (beneficiaries (list 10 {beneficiary: principal, share: uint})) (check-beneficiary principal))
    (index-of beneficiaries check-beneficiary find-beneficiary)
)

(define-private (find-beneficiary (entry {beneficiary: principal, share: uint}) (check-beneficiary principal))
    (is-eq (get beneficiary entry) check-beneficiary)
)

;; Calculate share amount
(define-private (calculate-share (total uint) (percentage uint))
    (/ (* total percentage) u100)
)

;; Read only functions
(define-read-only (get-will (owner principal))
    (map-get? wills { owner: owner })
)

(define-read-only (get-claim-status (beneficiary principal) (owner principal))
    (default-to { claimed: false }
        (map-get? beneficiary-claims { beneficiary: beneficiary, owner: owner })
    )
)
