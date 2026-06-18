# Assignment D3-V1: Warehouse Robotics – Single Robot Pick-and-Deliver


### Classical PDDL Model
- **Domain:** `codes/classical/domain-warehouse.pddl`
- **Problem 1:** `codes/classical/problem-1-single-package.pddl`
- **Problem 2:** `codes/classical/problem-2-sequential-delivery.pddl`

### PDDL+ Extension (with Continuous Processes & Events)
- **Domain:** `codes/pddl-plus/domain-warehouse-plus.pddl`
- **Problem Plus 1:** `codes/pddl-plus/problem-plus-1-simple-delivery.pddl`
- **Problem Plus 2:** `codes/pddl-plus/problem-plus-2-complex-balanced.pddl`
- **Problem Plus 3:** `codes/pddl-plus/problem-plus-3-missed-deadline.pddl`

** All files have been tested and run without errors in ENHSP-20.**

---

## Overview

This project models a mobile robot operating in a warehouse environment. The robot is tasked with navigating a predefined graph of locations to pick up packages from storage aisles and deliver them to a shipping dock. The robot is strictly constrained by a single-package carrying capacity.

The project contains two parts:
- A **Classical PDDL model** for discrete navigation, picking, and dropping.
- A **PDDL+ extension** that introduces continuous numeric variables to model travel distances, continuous transportation time, and strict delivery deadlines.

The main objective is to show how limited carrying capacity and time-dependent delivery constraints influence planning feasibility.

---

## Project Structure

```text
warehouse_robotics_d3v1/
├── codes/
│   ├── classical/
│   │   ├── domain-warehouse.pddl
│   │   ├── problem-1-single-package.pddl
│   │   └── problem-2-sequential-delivery.pddl
│   │
│   └── pddl-plus/
│       ├── domain-warehouse-plus.pddl
│       ├── problem-plus-1-simple-delivery.pddl
│       ├── problem-plus-2-complex-balanced.pddl
│       └── problem-plus-3-missed-deadline.pddl
│
├── outputs/
│   ├── pddl_1_single_package.txt
│   ├── pddl_2_sequential_delivery.txt
│   ├── pddl_plus_1_simple.txt
│   ├── pddl_plus_2_complex.txt
│   └── pddl_plus_3_unsolvable.txt
│
├── Report/
│   └── report.pdf
│
├── slides/
│   └── presentation.pdf
│
└── README.md
```

---

## Classical PDDL Model

The classical domain models four primary actions:

- `move`
- `pick`
- `drop-intermediate`
- `deliver-package`

The robot's physical constraints are managed through discrete predicates:

```lisp
(hand-empty ?r - robot)
(holding ?r - robot ?p - package)
```

The robot can only pick up a package if its hand is empty, forcing a strictly sequential operation for multiple deliveries.

### Classical Problem 1 – Single Package

`problem-1-single-package.pddl` contains one robot, a small warehouse graph, and a single package. It validates the basic operational sequence of moving to an aisle, picking a package, and delivering it to shipping.

### Classical Problem 2 – Sequential Delivery

`problem-2-sequential-delivery.pddl` contains multiple packages stored in different locations. The planner must find a valid sequence of back-and-forth trips to clear the warehouse, proving that the single-capacity constraint correctly influences the plan.

---

## PDDL+ Extension

The PDDL+ domain replaces instantaneous movement with continuous time-based transportation.

### Continuous Transportation

Movement is split into `start-move` and `end-move`. While moving, a continuous process decreases the distance to the target location based on elapsed time:

```lisp
(:process robot-transit
    :precondition (and (is-moving ?r) (> (distance-left ?r) 0))
    :effect (decrease (distance-left ?r) (* #t 1))
)
```

### Continuous Package Aging

Every package has a strictly enforced delivery deadline. While a package is undelivered, its lifespan continuously ticks down:

```lisp
(:process package-aging
    :precondition (and (not (delivered ?p)) (> (time-remaining ?p) 0))
    :effect (decrease (time-remaining ?p) (* #t 1))
)
```

### Deadline Breach Event

If a package's time reaches zero before it is officially delivered, an automatic event violently alters the state, marking the package as dead and permanently rendering the `deliver-package` action impossible:

```lisp
(:event deadline-breach
    :precondition (and
        (not (delivered ?p))
        (<= (time-remaining ?p) 0)
        (not (missed-deadline ?p))
    )
    :effect (missed-deadline ?p)
)
```

**Key Design Decision:** The precondition `(not (missed-deadline ?p))` prevents the event from firing infinitely. This was crucial to avoid an infinite loop in ENHSP's heuristic evaluation, where delete relaxation would otherwise assume the package still deliverable.

---

## PDDL+ Problem Instances

### Problem Plus 1 – Simple Delivery

A minimal working example testing the continuous time mechanics on a single package.

**Expected result:** `Problem Solved`

### Problem Plus 2 – Complex Balanced

A scaled-up scenario featuring three packages with independent aging clocks. The physical distances and deadlines are carefully balanced to keep the branching factor mathematically manageable for the heuristic engine while still demanding an optimized route.

**Expected result:** `Problem Solved`

### Problem Plus 3 – Missed Deadline (Unsolvable)

A scenario explicitly designed to fail. The travel time required to reach the package and deliver it strictly exceeds the package's initial lifespan. The event triggers before delivery is possible.

**Expected result:** `Problem unsolvable`

---

## Requirements

This project was developed and tested using:

- Ubuntu (WSL)
- Java 21
- ENHSP-20 Planner

The ENHSP executable is expected at:

```text
~/enhsp/ENHSP-Public/enhsp-dist/enhsp.jar
```

---

## Running the Planner & Saving Output

The complete output produced by ENHSP is redirected to text files in the `outputs` directory using the `>` operator. Because PDDL+ utilizes continuous numeric fluents, the `-planner opt-hrmax` flag is used for the complex continuous models.

### Example 1: Classical Sequential Problem

```bash
java -jar ~/enhsp/ENHSP-Public/enhsp-dist/enhsp.jar \
  -o codes/classical/domain-warehouse.pddl \
  -f codes/classical/problem-2-sequential-delivery.pddl \
  -planner opt-hrmax \
  > outputs/pddl_2_sequential_delivery.txt
```

### Example 2: PDDL+ Complex Problem

```bash
java -jar ~/enhsp/ENHSP-Public/enhsp-dist/enhsp.jar \
  -o codes/pddl-plus/domain-warehouse-plus.pddl \
  -f codes/pddl-plus/problem-plus-2-complex-balanced.pddl \
  -planner opt-hrmax \
  > outputs/pddl_plus_2_complex.txt
```

The raw output contains:

- parser messages;
- grounding information;
- search statistics;
- the generated plan;
- the solved or unsolvable result.

---

## Results Summary

| Problem | Model | Result | Search Time |
|---|---|---|---|
| Problem 1 | Classical | Solved | ~0.01s |
| Problem 2 | Classical | Solved | ~0.05s |
| Problem Plus 1 | PDDL+ | Solved | ~0.06s |
| Problem Plus 2 | PDDL+ | Solved | ~1.00s |
| Problem Plus 3 | PDDL+ | Unsolvable | ~0.00s |

---

## Plan Walkthrough Example

### Classical Problem 2 Output

```
Found Plan:
0.0:  (move  robby dock     aisle-A)
1.0:  (pick  robby pkg1     aisle-A)
2.0:  (move  robby aisle-A  shipping)
3.0:  (drop  robby pkg1     shipping)
4.0:  (move  robby shipping aisle-B)
5.0:  (pick  robby pkg3     aisle-B)
6.0:  (move  robby aisle-B  shipping)
7.0:  (drop  robby pkg3     shipping)
8.0:  (move  robby shipping aisle-A)
9.0:  (pick  robby pkg2     aisle-A)
10.0: (move  robby aisle-A  shipping)
11.0: (drop  robby pkg2     shipping)

Plan-Length: 12
Planning Time: 27 msec
Expanded Nodes: 15
```

**Observation:** The plan clearly demonstrates the back-and-forth pattern enforced by the single-capacity constraint. Each package delivery is followed by a return trip to retrieve the next one.

### PDDL+ Problem 2 Output (excerpt)

```
Found Plan:
0:    (start-move      robby dock     aisle-A)
0:    -----waiting---- [2.0]
2.0:  (end-move        robby dock     aisle-A)
2.0:  (pick            robby pkg2     aisle-A)
2.0:  (start-move      robby aisle-A  shipping)
2.0:  -----waiting---- [4.0]
4.0:  (end-move        robby aisle-A  shipping)
4.0:  (deliver-package robby pkg2     shipping)
...
14.0: (deliver-package robby pkg1     shipping)

Elapsed Time: 14.0
Plan-Length: 32
Expanded Nodes: 23731
```

**Observation:** The continuous processes allow the planner to reason about travel time and deadline pressure. The explicit waiting blocks show where continuous time was consumed. All packages were delivered well within their deadlines (30, 45, 60 time units).

Complete output files are available in the `outputs/` folder.

---

## Discussion & Analysis

### 1. Scalability from Single to Multiple Packages

During testing, we discovered that scaling from a single package to multiple packages in a continuous time environment drastically inflates the state space. Because each package has an independent, continuously ticking deadline, the branching factor grows exponentially. To achieve scalability in `problem-plus-2`, we had to carefully balance the physical distance metrics and deadline allowances to ensure the heuristic engine could effectively prune dead-end timelines.

For example:
- Problem Plus 1: 14 expanded nodes
- Problem Plus 2: 23,731 expanded nodes (1700× increase for 3× packages)

### 2. Limitations of Purely Sequential Planning

The strict single-package capacity constraint forces highly inefficient sequential planning. Every successful delivery requires an "empty-handed" return trip to the storage aisles. Because the robot cannot batch deliveries (e.g., picking up `pkg1` and `pkg2` simultaneously if they share a route), the total makespan is artificially extended. In a real-world scenario, this limitation would severely cap the warehouse's throughput.

### 3. Heuristic Blind Spots & Delete Relaxation

To prove that timing influences delivery feasibility, we introduced `problem-plus-3-missed-deadline.pddl`. During development, we observed that ENHSP is highly susceptible to "delete relaxation" in its heuristic estimates. By temporarily ignoring the negative `(not (missed-deadline))` precondition, the heuristic initially assumes a dead package is still deliverable. 

**Solution:** We explicitly embedded the failure condition into the `(:goal)` block:
```lisp
(:goal
    (and
        (delivered pkg1)
        (not (missed-deadline pkg1))
    )
)
```

Once updated, the heuristic accurately evaluated the dead-end and immediately terminated the search, successfully proving the deadline constraint restricts the state space (5 expanded nodes, problem correctly marked unsolvable).

---

## Model Limitations

The current model does not represent:

- Multi-gripper or multi-package carrying capacity
- Realistic file systems or memory management
- Probabilistic delivery times or stochastic elements
- Multiple cooperating robots
- Terrain difficulty or battery constraints
- Low-level motion planning or geometric paths
- Partial data quality or data corruption

Movement is instantaneous in the classical PDDL formulation. In the PDDL+ extension, travel time is modelled as a continuous linear function, which is a simplification of real-world physics.

---

## Conclusion

The project demonstrates how symbolic and hybrid planning can represent a constrained warehouse-robotics scenario. The classical PDDL model showed how a simple capacity predicate (`hand-empty`) is sufficient to force structured sequential plans. The PDDL+ extension demonstrated how continuous processes and automatic events can model travel time and delivery deadlines in a clean and declarative way.

Key takeaways:
- Limited carrying capacity dramatically increases plan complexity and makespan.
- Continuous time and per-object deadlines introduce exponential state-space growth.
- Heuristic design choices (e.g., delete relaxation) can obscure infeasibility; explicit failure conditions are essential.
- The model provides a sound foundation for extensions: multi-package gripping, multiple robots, stochastic travel times, and low-level motion integration.

---


**Author:** Paolo Nicolini (s5698969)  
**Course:** Artificial Intelligence for Robotics II (104731)  
**Professors:** Fulvio Mastrogiovanni, Omar Kashmar  
**University:** Università degli Studi di Genova  
**Date:** 19 May 2026