(define (problem simple-delivery)
    (:domain warehouse-single-robot)
    (:objects 
        robby - robot
        pkg1 - package
        dock aisle-A shipping - location
    )
    
    (:init
        ;; Graph Topology
        (connected dock aisle-A)
        (connected aisle-A dock)
        (connected aisle-A shipping)
        (connected shipping aisle-A)
        
        ;; Initial States
        (at-robot robby dock)
        (hand-empty robby)
        (at-package pkg1 aisle-A)
    )
    
    (:goal
        (and
            (at-package pkg1 shipping)
        )
    )
)