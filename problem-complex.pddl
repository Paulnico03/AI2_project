(define (problem complex-delivery)
    (:domain warehouse-single-robot)
    (:objects 
        robby - robot
        pkg1 pkg2 pkg3 - package
        dock aisle-A aisle-B shipping - location
    )
    
    (:init
        ;; Graph Topology (Two-way paths)
        (connected dock aisle-A)
        (connected aisle-A dock)
        
        (connected dock aisle-B)
        (connected aisle-B dock)
        
        (connected aisle-A shipping)
        (connected shipping aisle-A)
        
        (connected aisle-B shipping)
        (connected shipping aisle-B)
        
        ;; Initial Robot State
        (at-robot robby dock)
        (hand-empty robby)
        
        ;; Initial Package States
        (at-package pkg1 aisle-A)
        (at-package pkg2 aisle-A)
        (at-package pkg3 aisle-B)
    )
    
    (:goal
        (and
            ;; All packages must end up at shipping
            (at-package pkg1 shipping)
            (at-package pkg2 shipping)
            (at-package pkg3 shipping)
        )
    )
)