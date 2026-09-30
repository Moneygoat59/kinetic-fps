# KINETIC // Project Engineering & Architecture Rules

All agents and developers operating in this repository must follow these engineering rules. `tools\check.ps1` enforces the
mechanical ones (syntax, file size); the rest are for review.

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

### 2.1 Enum States, Not Boolean Flags
- **Rule:** Mutually exclusive modes of a character, device or game flow are one enum / FSM, never several loose booleans (e.g. `is_sliding`, `is_grappling`, `is_dead`). An entity is in exactly one primary state at a time (e.g. `IDLE`, `RUN`, `AIR`, `DEAD`; a terminal's `LOCKED`, `READY`, `WRITING`, `SET`).
- **Test:** if two flags must never both be true, they are one state: make an enum.
- **Allowed:** independent facts that can combine freely stay booleans (a relay can be both `is_active` and `is_cleared`).

### 2.2 Frame-Simultaneous Input Handling
- **Rule:** Code that reads player input resolves conflicting inputs on the same frame deterministically (e.g. Move Left + Move Right cancel; Interact + Pause: pause wins; two interactables offering [E]: the strongest offer wins, as `InteractPrompt` does).
- **Scope:** movement is walk-only; the old vine / bhop / dash conflicts only matter in the legacy Sector 00 code.

### 2.3 Early Guard Clauses
- **Rule:** Every public method or state transition must check prerequisites, bounds, and entity life at the top of the function and return early if inputs are invalid or entity state disallows the action.
- **Scope:** private helpers called only from already-guarded code may trust their caller; do not stack defensive checks.

---

## 3. Architecture & Blast-Radius Control

### 3.1 Modularity and File Size (soft 150 lines, hard 250)
- **Rule:** Separate concerns completely. Never produce monolithic controller files that handle inputs, animation, physics, and audio in one block.
- **Soft limit, 150 lines** (every line, as `check.ps1` counts): past it, ask whether the file does more than one thing. If it does, split it by responsibility (a presenter, a sub-FSM, a data helper). If it does one thing, a longer file is fine.
- **Hard limit, 250 lines:** `check.ps1` fails. Split before going over.
- **Never compress to fit:** no `;`-chained statements, no merging distinct functions, no deleting blank lines or comments to get under a number. One statement per line in new and edited code; when you rewrite a function that chains statements, unchain it.
- **Grandfathered** (legacy, over 250 lines, listed in `check.ps1`): `small_bunker.gd`, `megalevel_manager.gd`, `mech_enemy.gd`, `world_decorator.gd`, `drone_enemy.gd`. Substantive work in one of them starts by splitting it.
- **Subsystem Decoupling:**
  - **InputController:** Maps raw inputs to high-level game actions / wishes.
  - **Motor / Kinematics:** Applies acceleration, friction, gravity, and velocity limits.
  - **Health / Stats:** Pure data layer.
  - **Presenter / View:** Visual effects, audio synthesis, camera juice, and UI updates.

### 3.2 Event-Driven Communication (Signals / Bus)
- **Rule:** Systems must not reach directly into unrelated systems' private internals (e.g. player setting HUD labels, enemies directly mutating player internals).
- **Remedy:** Components emit signals/events (e.g. `health_changed(hp, max_hp)`, `velocity_changed(vel)`, `state_changed(old_state, new_state)`). UI, audio, and game managers listen to events passively.
- **Exception:** dev tools (`scripts/dev/`) and test hooks (`tools/exec/`) may call private methods and read internals to set up state or assert on it. Game code may not.

---

## 4. Code Review & Debugging Protocol

When evaluating or fixing existing code:
1. **Explain the Failure Mechanism First:** Never emit a blind rewrite. Identify the exact line, frame sequence, or variable mutation causing the defect.
2. **Minimal Delta (fixes):** A bug fix modifies only the broken logic. Do not restructure, rename, or reformat unrelated functions or working systems unless explicitly requested.
   **Features** may restructure the code they touch when the design needs it (CLAUDE.md: extend existing modules rather than copy them), but not code they do not touch.
3. **Audit Against Edge Cases:**
   - What occurs if delta time ($dt$) spikes ($> 0.1\text{s}$) or drops to zero ($0\text{s}$)?
   - Can numerical values produce `NaN`, `Infinity`, or division by zero?
   - What happens if an entity is freed/destroyed mid-animation or mid-callback (`await timer`)?

---

## 5. Verification

The world is procedural, so look at it and run it; do not reason about whether it works. Tools: `tools/README.md`.
1. **Every change:** `tools\check.ps1` (syntax of every script, file size).
2. **Scene or gameplay code:** `tools\smoke.ps1` (loads the forest headless, reports errors and frame times).
3. **Anything visible:** render it with `tools\capture.ps1` and read the PNG. Look before and after.
4. **Gameplay flows** (progression, interactions, state machines): a `tools/exec/check_*.gd` hook that drives the flow and prints `CHECK ok|FAIL` lines. Add one for a new flow. `tools\test.ps1` runs check, smoke and every hook in one go; run it before calling a gameplay change done.
5. **Report honestly:** say what was verified and how, and what was not (e.g. "not playtested by hand", "sound not auditioned").
