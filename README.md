# kaim
best aimbot script ever
```
loadstring(game:HttpGet("https://raw.githubusercontent.com/sdwird/kaim/refs/heads/main/kaim-v4.1.lua"))()
```
copy paste to any executor (%80 unc required to work)

after every update your config files will not work 

Modules

🗡️ Module Breakdown

🎯 Combat Module (Aimbot & Triggerbot)

The Combat tab houses an advanced targeting engine built to bypass anti-cheats and hit moving targets perfectly.

Prediction Engine: Calculates enemy velocity and adjusts your aim to lead targets perfectly.

Smooth Aiming: Lerps your camera naturally towards the target instead of snapping instantly, making your aim look highly legitimate.

Aim Modes:

Smart: Automatically targets the highest visible body part (Head > Torso > Limbs) so you don't shoot at walls.

Chaos: Randomly cycles targeted body parts every 0.3 seconds to bypass strict hit-box anti-cheats.

Triggerbot: Automatically fires your weapon the millisecond an enemy enters your crosshair, featuring customizable humanized delays.

👁️ Visuals Module (ESP & Chams)

A completely lag-free visual suite that caches properties to maintain maximum FPS in crowded lobbies.

Dynamic ESP Boxes & Text: Draws perfectly scaled 2D boxes, names, and exact distance tracking around enemies.

Visibility Colors: ESP elements automatically turn Green when an enemy is visible and Red when they are behind a wall.

Health Bars: Smooth, color-transitioning health bars dynamically scale alongside the enemy bounding boxes.

3D Chams: Uses native Roblox highlights to color enemies through walls, featuring customizable fill/outline transparencies (Solid or Ghost chams).

Target HUD: A sleek, draggable UI card that displays the stats (Name, HP, Distance, Targeted Part) of the enemy you are currently locked onto.

🏃 Player Module

Take control of your local character's physics and movement.

WalkSpeed & JumpPower: Safely override your movement constraints.

Smart Noclip: Walk directly through walls. Unlike other scripts, KAIM caches your original collision states, meaning you won't fall through the floor or permanently break your character's hitboxes when you turn it off.

⚙️ Settings & Configuration

Config Manager: Save multiple different setups (e.g., "Legit", "Rage", "Sniper") into local .json files. Load them instantly with a dropdown menu without having to reconfigure the script every time you play.

Custom Themes: Change the look of the entire mod menu on the fly using native WindUI themes (Dark, Light, Rose, Amethyst, Ocean, Sunset).

Diagnostics: View your executor's trust rating, exact UNC percentage, and engine compatibility directly inside the menu.

💻 Supported Executors

KAIM is optimized to bypass standard drawing API limits and works flawlessly on modern execution engines, including:

Premium: Krampus, Ro-Exec, Wave

Standard: Xeno, Solara, Celery, Electron, Appleware

Mobile: Delta, Codex

⚠️ Important Notice

Config Resets: Due to frequent optimizations and updates to the script's memory structure, old configuration files may occasionally break after major updates. If the script does not load your settings, please delete your old config and create a new one!
