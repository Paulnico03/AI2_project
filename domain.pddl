(define (domain warehouse-single-robot)
    (:requirements :strips :typing)
    (:types robot package location)

    (:predicates
        (at-robot ?r - robot ?l - location)
        (at-package ?p - package ?l - location)
        (connected ?l1 - location ?l2 - location)
        (holding ?r - robot ?p - package)
        (hand-empty ?r - robot)
    )

    ;; Explicit navigation between connected nodes
    (:action move
        :parameters (?r - robot ?from - location ?to - location)
        :precondition (and 
            (at-robot ?r ?from)
            (connected ?from ?to)
        )
        :effect (and 
            (not (at-robot ?r ?from))
            (at-robot ?r ?to)
        )
    )

    ;; Pick action enforcing the single-capacity constraint
    (:action pick
        :parameters (?r - robot ?p - package ?l - location)
        :precondition (and 
            (at-robot ?r ?l)
            (at-package ?p ?l)
            (hand-empty ?r)
        )
        :effect (and 
            (not (at-package ?p ?l))
            (not (hand-empty ?r))
            (holding ?r ?p)
        )
    )

    ;; Drop action to deliver the package
    (:action drop
        :parameters (?r - robot ?p - package ?l - location)
        :precondition (and 
            (at-robot ?r ?l)
            (holding ?r ?p)
        )
        :effect (and 
            (not (holding ?r ?p))
            (hand-empty ?r)
            (at-package ?p ?l)
        )
    )
)