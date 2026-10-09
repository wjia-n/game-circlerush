# Circle Rush — RULES

_Authoritative source of truth. If implementation conflicts with this document, fix the implementation._

## 1. Objective
Pilot a ship orbiting a planet. Asteroids streak in from the edges. Survive as long as you can (Endless) or survive the clock (Rush 60 / Blitz 30). One asteroid hit ends the run.

## 2. Setup
- The arena is a unit circle. The planet sits at the center (radius 0.20).
- Two orbit lanes: **inner** (radius 0.34) and **outer** (radius 0.66), drawn as brass rings.
- The ship starts on the inner lane, orbiting at a constant angular speed in one fixed direction; the direction never reverses.
- The run begins in phase `idle` ("Tap to launch!"). The first tap starts a 3-step countdown ("READY… SET… RUSH!"), then play begins.

## 3. Turn order
There are no turns — this is a real-time arcade game. The engine runs a fixed 60 fps simulation loop; the only player input is a tap.

## 4. Legal moves
- **Tap while `playing`**: hop to the other orbit lane. The ship springs smoothly to the new radius (no teleport).
- **Tap while `idle`**: launch the run (starts countdown).
- Pausing is always legal via the pause button or the device back button.

## 5. Illegal moves
- Tapping during `countdown`, `crashing`, or `over` does nothing.
- Tapping while paused does nothing (the pause overlay consumes input).
- There is no double-hop: each tap toggles the lane exactly once.

## 6. Captures
Not applicable — there are no captures. Asteroids are hazards, not targets.

## 7. Special rules
- **Near miss (graze):** an asteroid that passes within the ship's hit radius + 0.14 arena units without touching it is marked *grazed*. When it leaves the arena, the player scores **+10** (timed modes only; Endless scores pure survival time), plays a ping, and shows a floating "+10".
- **Milestones:** in Endless, every 15 seconds survived shows a floating "15s! / 30s! / …" banner with a chime.
- **Timed-mode warnings:** at 3, 2, 1 seconds remaining a beep plays.
- **Win bonus:** surviving the full 60s (Rush 60) or 30s (Blitz 30) grants **+100** and the victory screen.

## 8. Scoring
- **Endless Orbit:** score = whole seconds survived.
- **Rush 60 / Blitz 30:** score = whole seconds survived + 10 × near misses (+100 win bonus on full survival).
- Score is recomputed every frame from engine state — never accumulated silently; every point comes with a visible event (floater) or is the live survival clock.

## 9. Winning conditions
- Rush 60 / Blitz 30: the clock reaches zero without a crash → **Victory** (+100 bonus, win fanfare).
- Endless: there is no victory — only a new personal best.

## 10. Draw conditions
Not applicable — single-player arcade.

## 11. AI strategy
Not applicable — no opponents. Difficulty comes from tuned parameters:
- **Drifter (easy):** slow orbit, slow sparse rocks.
- **Voyager (medium):** the classic rush.
- **Cometchaser (hard, Pro):** fast orbit, dense fast rocks.
- **Nova (extreme, Pro):** relentless.
All four scale further with survival time (orbit speed, spawn rate, rock speed and size ramp up). Blitz 30 multiplies rock speed ×1.3 and density ×1.33.

## 12. Edge cases
- Crash during the final second of a timed mode: the crash wins — the run ends as a loss, score kept as-is.
- Backgrounding mid-run: the engine pauses; the phase timers freeze; the watchdog does not "recover" a paused game.
- Recording a finished run must never throw: persistence errors are swallowed and the engine still reaches `over`.
- Review prompts fire only after ≥3 real games, at most every 4th game or on a new best, and never interrupt gameplay.

## 13. Test cases
1. Launch from idle → countdown plays 3 steps → play begins.
2. Tap toggles lane; ship visibly hops with bounce + whoosh.
3. Asteroid hits ship → explosion, 900 ms crash anim → game-over panel with correct headline (NEW BEST / VICTORY / CRASHED).
4. Graze without touching → "+10" floater + ping; only in timed modes does it add points.
5. Survive 60s in Rush 60 → +100, victory fanfare, WON state.
6. Pause mid-run → sim freezes; resume continues exactly.
7. Background the app mid-run → run is paused on return; music resumes where it left off.
8. New best persists across app restarts; legacy `circlerush_best` key migrates into Endless best.
9. Pro purchase (when store configured) unlocks themes/orbs/ships/tiers; restore works on reinstall.
10. With no store products configured, the Pro screen shows the honest "after store setup" state and no buy button.
