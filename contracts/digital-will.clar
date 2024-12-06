;; Digital Will Contract
(define-map wills
    { owner: principal }
    {
        beneficiary: principal,
        amount: uint,
        last-active: uint,
        inheritance-delay: uint
    }
)

(define-map beneficiary-claims
    { beneficiary: principal }
    { claimed: bool }
)

(define-constant err-not-owner (err u100))
(define-constant err-already-claimed (err u101))
(define-constant err-no-will (err u102))
(define-constant err-delay-not-met (err u103))
(define-constant err-owner-still-active (err u104))

;; Create or update will
(define-public (set-will (beneficiary principal) (amount uint) (inheritance-delay uint))
    (begin
        (map-set wills
            { owner: tx-sender }
            {
                beneficiary: beneficiary,
                amount: amount,
                last-active: block-height,
                inheritance-delay: inheritance-delay
            }
        )
        (ok true)
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

;; Claim inheritance
(define-public (claim-inheritance (owner principal))
    (let (
        (will (unwrap! (get-will owner) err-no-will))
        (claim-status (default-to { claimed: false } (map-get? beneficiary-claims { beneficiary: tx-sender })))
    )
    (asserts! (is-eq (get beneficiary will) tx-sender) err-not-owner)
    (asserts! (not (get claimed claim-status)) err-already-claimed)
    (asserts! (>= (- block-height (get last-active will)) (get inheritance-delay will)) err-delay-not-met)
    (begin
        (try! (stx-transfer? (get amount will) owner tx-sender))
        (map-set beneficiary-claims { beneficiary: tx-sender } { claimed: true })
        (ok true)
    ))
)

;; Read only functions
(define-read-only (get-will (owner principal))
    (map-get? wills { owner: owner })
)

(define-read-only (get-claim-status (beneficiary principal))
    (default-to { claimed: false }
        (map-get? beneficiary-claims { beneficiary: beneficiary })
    )
)
