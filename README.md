# KINETIC (Retro Movement FPS Prototype)

A fast-paced, high-mobility retro FPS built in **Godot 4.3 (GDScript)** inspired by *Quake*, *Cruelty Squad*, and *Ultrakill*.

## Quick Start

- **Play the game:**
  ```bash
  ~/kinetic-fps/run_game.sh
  # or: godot --path ~/kinetic-fps
  ```
- **Open in Godot Editor:**
  ```bash
  ~/kinetic-fps/open_editor.sh
  # or: godot -e --path ~/kinetic-fps
  ```

---

## Vine Mechanics & Slingshot Tuning (Options 1 & 3)

1. **Physics-True Catapult & Soft Cap (Option 1)**:
   - Release speed is determined by the **physical velocity of your pendulum arc** + a punchy forward impulse (+7.0 m/s).
   - Max launch speed is soft-capped at **36 m/s**.
   - **Aerodynamic Drag Taper**: Above 28 m/s in the air, wind resistance smoothly glides your velocity down into a controllable trajectory instead of launching you into orbit.
2. **"Over-Strained" Vine Snap (Option 3)**:
   - Tougher vine durability: strain only begins accumulating during true runaway hyper-speeds (**>33 m/s**) or extreme over-stretching (>25%).
   - **Visuals**: The vine visibly shifts from toxic neon green to straining orange, and then violent warning red as it rapidly vibrates.
   - **Audio**: A rising groaning pitch warns you the vine is reaching its breaking point.
   - **The Snap**: If strained to 100%, the vine violently snaps (*TWANG!*), shedding 40% of your forward speed and dropping you straight down with a brief cooldown.
   - **Sweet Spot**: Timing your release right before maximum strain yields the cleanest, highest-momentum slingshot!

---

## The Obstacle Course Trial

Step through the **Green Start Gate** to start the stopwatch!

1. **The Velocity Chute (Slide & Duck)**:
   - Steep downhill acceleration ramp with low concrete bulkheads.
   - You **must** hold `Ctrl` or `C` to crouch-slide underneath them at 35+ m/s or crash!
2. **The Bhop S-Chasm (Bunnyhop Runway)**:
   - A bottomless void pit with staggered floating pillars.
   - Requires air-strafing and timing consecutive jumps (`Space`) to leap the gaps without losing momentum.
3. **The Industrial Crane Canyon (Vine Swing Chain)**:
   - A massive gorge with 3 suspended yellow overhead cranes.
   - Aim up and hold `RMB` to latch your vine (59.5m reach), swing through the bottom of the arc, and tap `Space` before the strain breaks to slingshot crane to crane!
4. **The Security Lock Blast Gate**:
   - A heavy hydraulic blast door blocks the corridor.
   - Shoot the 2 glowing red reactor orbs with your blaster (`LMB`) to retract the gate!
5. **The Orbital Jump Pad & Spire Catapult**:
   - Super jump pad launches you 30m straight up.
   - Latch onto the high ceiling spire in midair to fling yourself into the final stretch!
6. **The Finish Gate & Teleport Loop**:
   - Cross the golden finish line to stop the timer and record your personal best!
   - Step onto the green teleport pad to instantly return to the start line and beat your record.

---

## Explosive Grenade Weapon (`G` / `2`)

A two-stage cooked fragmentation grenade explosive:
1. **Equip**: Press `G` (or `2`) to switch from Blaster to Grenade.
2. **Stage 1 (Click 1 - Pull Pin)**: Click `LMB` once to yank the pin out.
   - Distinct metallic clink sound.
   - Pin ring pops off in your hand.
   - Sparks crackle and a 3.5-second fuse countdown starts!
3. **Stage 2 (Click 2 - Throw)**: Click `LMB` again to chuck the grenade forward.
   - Inherits 60% of player movement momentum + 25 m/s forward throw + slight upward arc.
   - Physics-driven bouncing with metallic clatter on impacts.
   - Detonates on fuse expiry!
4. **The Explosion**:
   - Expanding fiery shockwave with intense dynamic lighting and synthesized bass boom.
   - Deals 120 radial damage with distance falloff to target dummies and security blast gates.
   - Massive physics impulse: launches props and sends the player flying into rocket jumps!
5. **Cook Hazard**: If you hold the grenade until the 3.5s fuse expires, it detonates directly in your hand!

---

## Controls

| Action | Controls | Mechanic Feel |
| :--- | :--- | :--- |
| **Shitty Vine Swing** | **Hold `RMB`** | Shoots an elastic green bio-vine. Swings you in a pendulum arc with sag & wobble! |
| **Slingshot Release** | **Release `RMB` / `Space`** | Releases momentum in a physics-governed catapult arc |
| **Vine Pumping** | `W` `A` `S` `D` *(in air)* | Adds tangential torque to build swing speed |
| **Strafe Jump / Bhop** | `Space` | Turn mouse smoothly while holding strafe keys to gain uncapped air velocity |
| **Momentum Slide** | `Ctrl` or `C` | Low friction slide; crouches camera and launches down slopes |
| **Kinetic Dash** | `Shift` or `Q` | Instant directional burst with camera kick |
| **Equip Grenade** | `G` or `2` | Switch to cooked explosive grenade |
| **Equip Blaster** | `1` | Switch back to primary blaster |
| **Pull Pin (Grenade)** | `LMB` *(1st click)* | Pulls pin, ignites fuse (3.5s cook timer) |
| **Throw Grenade** | `LMB` *(2nd click)* | Hurls primed grenade along camera vector |
| **Fire Blaster** | `LMB` *(Blaster)* | Hitscan blaster with recoil, muzzle flash, and spark impacts |
| **Checkpoint Respawn** | `R` | Instantly reset to your last reached checkpoint |
| **Full Run Restart** | `Shift + R` | Reset timer and teleport back to the start line |
| **Interact / Read Lore** | `E` | Open interactive retro terminals |
| **Toggle Fullscreen** | `F11` / `Alt+Enter` | Seamlessly switch between windowed and fullscreen |
| **Toggle Cursor** | `Esc` | Release / capture mouse |

