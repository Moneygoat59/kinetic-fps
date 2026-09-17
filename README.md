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

## Sector 00: The Proving Grounds (Mega-Level)

A massive **600m x 600m** interconnected brutalist testing complex designed for extreme traversal and high-velocity momentum:

- **Sector 00 // The Core Citadel**: Central transit hub featuring a 75-meter brutalist spire with an interior vertical **Hyper-Lift** launching players 50m straight through the roof to the top observation deck and 360° grapple anchors.
- **Sector 01 // Stratosphere Slingshot Arcs**: A bottomless void canyon crossed by 5 suspended mega-cranes and glowing tether beacons (35-42m reach spacing) for continuous aerial pendulum slingshots across a 300m gap.
- **Sector 02 // Velocity Chute Canyon**: A 300-meter winding downhill mountain slide with steep 35° drops, low concrete crouch-slide bulkheads, boost ramps, and a ski-jump lip catapulting players across the eastern trench.
- **Sector 03 // Industrial Foundry & Basin**: Sunken excavation combat pit featuring warehouse rooftops, shipping container stacks, patrolling walking Mechs, target dummies, and high-yield ejector jump pads.
- **Sector 04 // Mach-Speed Bhop Highway**: A 350-meter elevated 4-lane straightaway suspended on massive pillars, built for uninterrupted air-strafing bunnyhops with 50-60+ m/s uncapped acceleration and speed arches.
- **Sector 05 // Orbital Catapult Gantry**: High-yield launch platform catapulting players 75+ meters into the stratosphere toward mid-air tether beacons.
- **Sector 06 // Perimeter Skyway Ring**: Elevated 1.5km ring highway looping around the entire megastructure.
- **Dynamic Checkpoint & HUD System**: Tracks current sector, speedometer milestones (32 m/s, 45 m/s, 60+ m/s), session top speeds, void fall recovery, and enemy wave respawning (`[R]`).

---

## Vine Mechanics & Slingshot Tuning (Balanced Momentum & Vertical Pop)

1. **Balanced Reach & Responsive Tethering**:
   - Reach set to **42.0 m** (down from 54 m, up from 34 m), giving plenty of room to catch overhead cranes and high spires without sniping skyboxes.
   - Spring stiffness set to `20.0` and latch boost to `3.2 m/s` for a tactile, responsive swing that pulls with weight.
2. **Dynamic Vertical Pop & Ceiling Control**:
   - **Upward Launch Pop**: Vertical ceiling raised to **$24.5\text{ m/s}$**, providing a generous aerial lift (~$12.5\text{--}14\text{ m}$) to easily vault cranes, clear bridges, and scale high structures.
   - **Tactical Winch (`Space`)**: Holding `Space` while grappling reels you in slowly towards the anchor point, lifting off the ground and reeling upward.
   - **Catapult Launch (`Shift`)**: Tapping `Shift` during a swing catapults you off the vine with a forward boost and punchy **$+4.5\text{ m/s}$** vertical pop.
   - **Natural Arc Release**: Releasing `RMB` naturally detaches while preserving your swing's momentum up to $24.5\text{ m/s}$.
   - **Cloud-Rocket Prevention**: Only extreme runaway vertical velocity ($> 24.5\text{ m/s}$) is converted into forward momentum, preventing players from rocketing into outer space while preserving vertical freedom.

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

## PS1 Foliage & Industrial World Decoration System

The Mega-Level complex now features an automated **World Decorator** ([`scripts/world_decorator.gd`](file:///C:/Users/Isaac/kinetic-fps/scripts/world_decorator.gd)) that populates **205+ curated low-poly 3D models**:
- **Authentic PS1 Aesthetics**: Rendered with [`shaders/ps1_model.gdshader`](file:///C:/Users/Isaac/kinetic-fps/shaders/ps1_model.gdshader) featuring screen-space vertex snapping (`jitter_resolution = 180`), unlit/matte shading (`specular_disabled`), and nearest-neighbor texture filtering.
- **Solid & Grapple-able**: Every tree, rock, crate, and pipe has a generated static collider (`PropCollider`), allowing players to tether, vine-swing, and slingshot off them!
- **Environmental Theming by Sector**:
  - **Sector 00 // Citadel Gardens**: Overgrown plaza planters with high spruce pines, wild ferns, low crags, and steam conduit pipe runs.
  - **Sector 01 // Void Canyon Pines**: Wind-whipped evergreens and boulder crags perched precariously over the 300m void chasm beneath the mega-cranes.
  - **Sector 02 // Velocity Chute Forest**: Dense pine forest lining the mountain slide retaining walls; duck under overhead industrial pipe arches at 35+ m/s!
  - **Sector 03 // Industrial Foundry**: Heavy factory machinery, robotic arms, storage hoppers, stacked cargo crates for combat cover, and toxic trench weeds.
  - **Sector 04 // Bhop Highway**: Highway hazard cones and striped barricades lining the 350m high-speed air-strafe runway.

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
| **Vine Swing** | **Hold `RMB`** | Shoots an elastic green bio-vine. Swings you in a pendulum arc with sag & wobble! |
| **Vine Winch** | **Hold `Space`** | Slowly reels you in towards anchor, lifting off the ground with ratchet audio |
| **Catapult Launch** | **`Shift`** | Launches forward off the vine with +4.5 m/s upward vertical pop |
| **Smooth Detach** | **Release `RMB`** | Silently releases tether while preserving swing momentum |
| **Vine Steering / Pumping** | `W` `A` `S` `D` *(in air)* | Directional torque to pump swing arcs without altering rope length |
| **Strafe Jump / Bhop** | `Space` *(on floor)* | Turn mouse smoothly while holding strafe keys to gain uncapped air velocity |
| **Momentum Slide** | `Ctrl` or `C` | Low friction slide; crouches camera and launches down slopes |
| **Kinetic Dash** | `Shift` or `Q` *(not grappling)* | Instant directional burst with camera kick |
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

