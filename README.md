# Assignment D3-V1: Warehouse Robotics – Single Robot Pick-and-Deliver

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
├── pddl/
│   ├── domain-warehouse.pddl
│   ├── problem-1-single-package.pddl
│   └── problem-2-sequential-delivery.pddl
│
├── pddl-plus/
│   ├── domain-warehouse-plus.pddl
│   ├── problem-plus-1-simple-delivery.pddl
│   ├── problem-plus-2-complex-balanced.pddl
│   └── problem-plus-3-missed-deadline.pddl
│
├── plans/
│   ├── pddl_1_single_package.txt
│   ├── pddl_2_sequential_delivery.txt
│   ├── pddl_plus_1_simple.txt
│   ├── pddl_plus_2_complex.txt
│   └── pddl_plus_3_unsolvable.txt
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

The complete output produced by ENHSP is redirected to text files in the `plans` directory using the `>` operator. Because PDDL+ utilizes continuous numeric fluents, the `-planner opt-hrmax` flag is used for the complex continuous models.

### Example 1: Classical Sequential Problem

```bash
java -jar ~/enhsp/ENHSP-Public/enhsp-dist/enhsp.jar \
  -o pddl/domain-warehouse.pddl \
  -f pddl/problem-2-sequential-delivery.pddl \
  -planner opt-hrmax \
  > plans/pddl_2_sequential_delivery.txt
```

### Example 2: PDDL+ Complex Problem

```bash
java -jar ~/enhsp/ENHSP-Public/enhsp-dist/enhsp.jar \
  -o pddl-plus/domain-warehouse-plus.pddl \
  -f pddl-plus/problem-plus-2-complex-balanced.pddl \
  -planner opt-hrmax \
  > plans/pddl_plus_2_complex.txt
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

## Discussion & Analysis

### 1. Scalability from Single to Multiple Packages

During testing, we discovered that scaling from a single package to multiple packages in a continuous time environment drastically inflates the state space. Because each package has an independent, continuously ticking deadline, the branching factor grows exponentially. To achieve scalability in `problem-plus-2`, we had to carefully balance the physical distance metrics and deadline allowances to ensure the heuristic engine could effectively prune dead-end timelines.

### 2. Limitations of Purely Sequential Planning

The strict single-package capacity constraint forces highly inefficient sequential planning. Every successful delivery requires an "empty-handed" return trip to the storage aisles. Because the robot cannot batch deliveries (e.g., picking up `pkg1` and `pkg2` simultaneously if they share a route), the total makespan is artificially extended. In a real-world scenario, this limitation would severely cap the warehouse's throughput.

### 3. Heuristic Blind Spots & Delete Relaxation

To prove that timing influences delivery feasibility, we introduced `problem-plus-3-missed-deadline.pddl`. During development, we observed that ENHSP is highly susceptible to "delete relaxation" in its heuristic estimates. By temporarily ignoring the negative `(not (missed-deadline))` precondition, the heuristic initially assumes a dead package is still deliverable. We solved this by explicitly embedding the failure condition into the `(:goal)` block. Once updated, the heuristic accurately evaluated the dead-end and immediately terminated the search, successfully proving the deadline constraint restricts the state space.

---

## Conclusion

The project demonstrates how symbolic planning can represent:

- limited single-package carrying capacity;
- discrete pick-and-deliver operations;
- continuous travel time across warehouse distances;
- continuous package aging with strict deadlines;
- automatic deadline-breach events causing mission failure.

The classical PDDL problems focus on capacity-constrained sequential planning, while the PDDL+ problems show how continuous time and autonomous deadline events can make a delivery mission either feasible or impossible.