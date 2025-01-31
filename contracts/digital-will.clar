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

;; Create or update will with multiple beneficiaries
(define-public (set-will (beneficiaries (list 10 {beneficiary: principal, share: uint})) (total-amount uint) (inheritance-delay uint))
    (let
        ((total-shares (fold + (map get-share beneficiaries) u0)))
        (asserts! (is-eq total-shares u100) err-invalid-shares)
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
    (filter find-beneficiary beneficiaries)
)

(define-private (find-beneficiary (entry {beneficiary: principal, share: uint}))
    (is-eq (get beneficiary entry) tx-sender)
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
