;; Governance DAO Contract (Clarity v2)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ADMIN + GOVERNANCE CONFIG
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-data-var admin principal tx-sender)

(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-PROPOSAL-NOT-FOUND u101)
(define-constant ERR-ALREADY-VOTED u102)
(define-constant ERR-INVALID-PROPOSAL u103)
(define-constant ERR-EXECUTION-NOT-ALLOWED u104)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA STRUCTURES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-map proposals
  uint
  {
    proposer: principal,
    description: (string-ascii 256),
    votes-for: uint,
    votes-against: uint,
    executed: bool,
    end-block: uint
  })

(define-map votes (tuple (proposal-id uint) (voter principal)) bool)

(define-data-var proposal-counter uint u0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PRIVATE FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-private (only-admin)
  (is-eq tx-sender (var-get admin)))

(define-private (get-proposal (id uint))
  (map-get? proposals id))

(define-private (has-voted? (proposal-id uint) (voter principal))
  (default-to false (map-get? votes { proposal-id: proposal-id, voter: voter })))

(define-private (is-open (end-block uint))
  (< block-height end-block))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PUBLIC FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (create-proposal (description (string-ascii 256)) (duration uint))
  (let ((id (+ u1 (var-get proposal-counter)))
        (end (+ block-height duration)))
    (begin
      (var-set proposal-counter id)
      (map-set proposals id {
        proposer: tx-sender,
        description: description,
        votes-for: u0,
        votes-against: u0,
        executed: false,
        end-block: end
      })
      (ok id))))

(define-public (vote (proposal-id uint) (support bool))
  (let ((prop (get-proposal proposal-id)))
    (if (is-some prop)
        (let ((proposal (unwrap! prop (err ERR-PROPOSAL-NOT-FOUND))))
          (begin
            (asserts! (is-open (get end-block proposal)) (err ERR-EXECUTION-NOT-ALLOWED))
            (asserts! (not (has-voted? proposal-id tx-sender)) (err ERR-ALREADY-VOTED))
            (map-set votes { proposal-id: proposal-id, voter: tx-sender } true)
            (map-set proposals proposal-id
              {
                proposer: (get proposer proposal),
                description: (get description proposal),
                votes-for: (if support (+ u1 (get votes-for proposal)) (get votes-for proposal)),
                votes-against: (if (not support) (+ u1 (get votes-against proposal)) (get votes-against proposal)),
                executed: (get executed proposal),
                end-block: (get end-block proposal)
              })
            (ok true)))
        (err ERR-PROPOSAL-NOT-FOUND))))

(define-public (execute-proposal (proposal-id uint))
  (let ((prop (get-proposal proposal-id)))
    (if (is-some prop)
        (let ((proposal (unwrap! prop (err ERR-PROPOSAL-NOT-FOUND))))
          (begin
            (asserts! (not (get executed proposal)) (err ERR-EXECUTION-NOT-ALLOWED))
            (asserts! (>= (get votes-for proposal) (get votes-against proposal)) (err ERR-EXECUTION-NOT-ALLOWED))
            (map-set proposals proposal-id
              {
                proposer: (get proposer proposal),
                description: (get description proposal),
                votes-for: (get votes-for proposal),
                votes-against: (get votes-against proposal),
                executed: true,
                end-block: (get end-block proposal)
              })
            (ok true)))
        (err ERR-PROPOSAL-NOT-FOUND))))

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (only-admin) (err ERR-NOT-AUTHORIZED))
    (var-set admin new-admin)
    (ok true)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; READ-ONLY FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-read-only (get-proposal-data (id uint))
  (get-proposal id))

(define-read-only (has-voted (proposal-id uint) (voter principal))
  (has-voted? proposal-id voter))

(define-read-only (get-admin)
  (var-get admin))
