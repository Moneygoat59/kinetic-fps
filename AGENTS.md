# KINETIC // Project Engineering & Architecture Rules

All agents and developers operating in this repository must strictly adhere to the following 4 core engineering rules.

---

## 1. Performance & The 16.6ms Frame Budget (60 FPS)

### 1.1 Zero Allocations in the Hot Path
- **Rule:** Never instantiate objects, allocate arrays, or clone structures inside `_process()`, `_physics_process()`, tick routines, or render loops (`new`, `[...arr]`, `.map()`, `.filter()`, `Array()`, `Dictionary()`, etc.).
- **Remedy:** Pre-allocate static/scratch variables outside the loop or reuse pre-existing object pools. Mutate in-place where safe.

### 1.2 No Dynamic Queries Every Frame
- **Rule:** Never execute scene-tree traversals, component lookups, or global registry searches (e.g. `get_node()`, `find_child()`, `find_node()`, `get_first_node_in_group()`, `FindObjectsOfType()`) on frame ticks.
- **Remedy:** Cache object and node references during initialization (`_ready()`, `_enter_tree()`, spawn).

### 1.3 Algorithmic Bounds
- **Rule:** Flag any nested $O(n^2)$ entity comparisons (e.g. all-vs-all collision distance checks).
- **Remedy:** Implement spatial partitioning, grid hashing, or layer-based broad-phase filtering once entity counts exceed trivial numbers (>50).

---

## 2. State Integrity & Edge-Case Defense

### 2.1 Ban Boolean Flags for States
- **Rule:** Never implement character or game state using multiple loose booleans (e.g. `is_sliding`, `is_grappling`, `is_dead`, `is_jumping`, `is_attacking`).
- **Remedy:** Implement strict, single-state enums or explicit Finite State Machines (FSMs). A character or entity can only exist in one primary state at a time (e.g. `IDLE`, `RUN`, `AIR`, `SLIDE`, `GRAPPLE`, `DEAD`).

### 2.2 Frame-Simultaneous Input Handling
- **Rule:** Explicitly validate and handle opposing or conflicting inputs that arrive on the exact same frame (e.g. Move Left + Move Right; Jump + Slide; Grapple + Dash; Pause + Death).
- **Remedy:** Enforce a deterministic resolution hierarchy (cancel out, prioritize newest timestamp, or map to a distinct neutral fallback).

### 2.3 Early Guard Clauses
- **Rule:** Every public method or state transition must check prerequisites, bounds, and entity life at the top of the function and return early if inputs are invalid or entity state disallows the action.

---

## 3. Architecture & Blast-Radius Control

### 3.1 Strict Modularity (<150 Lines per File)
- **Rule:** Separate concerns completely. Never produce monolithic controller files that handle inputs, animation, physics, and audio in one block.
- **Subsystem Decoupling:**
  - **InputController:** Maps raw inputs to high-level game actions / wishes.
  - **Motor / Kinematics:** Applies acceleration, friction, gravity, and velocity limits.
  - **Health / Stats:** Pure data layer.
  - **Presenter / View:** Visual effects, audio synthesis, camera juice, and UI updates.

### 3.2 Event-Driven Communication (Signals / Bus)
- **Rule:** Systems must not reach directly into unrelated systems' private internals (e.g. player setting HUD labels, enemies directly mutating player internals).
- **Remedy:** Components emit signals/events (e.g. `health_changed(hp, max_hp)`, `velocity_changed(vel)`, `state_changed(old_state, new_state)`). UI, audio, and game managers listen to events passively.

---

## 4. Code Review & Debugging Protocol

When evaluating or fixing existing code:
1. **Explain the Failure Mechanism First:** Never emit a blind rewrite. Identify the exact line, frame sequence, or variable mutation causing the defect.
2. **Minimal Delta:** Modify only the broken logic. Do not restructure, rename, or reformat unrelated functions or working systems unless explicitly requested.
3. **Audit Against Edge Cases:**
   - What occurs if delta time ($dt$) spikes ($> 0.1\text{s}$) or drops to zero ($0\text{s}$)?
   - Can numerical values produce `NaN`, `Infinity`, or division by zero?
   - What happens if an entity is freed/destroyed mid-animation or mid-callback (`await timer`)?
