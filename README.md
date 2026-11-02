# Chicken Jump

[![Chicken Jump cover art](itch/cover.png)](https://emilianostack.itch.io/chickenjump)

An endless arcade jumper made with Godot. Steer a bouncing chicken from platform to platform, up through day, sunset, night and into outer space.

**[Play it on itch.io](https://emilianostack.itch.io/chickenjump)** in your browser, on desktop or mobile.

## Screenshots

<table>
  <tr>
    <td align="center"><img src="itch/screenshots/menu.png" width="240" alt="Main menu"><br>Main menu</td>
    <td align="center"><img src="itch/screenshots/gameplay.png" width="240" alt="Gameplay during the day"><br>Daytime</td>
    <td align="center"><img src="itch/screenshots/sunset.png" width="240" alt="Gameplay at sunset"><br>Sunset</td>
  </tr>
  <tr>
    <td align="center"><img src="itch/screenshots/night.png" width="240" alt="Gameplay at night"><br>Night</td>
    <td align="center"><img src="itch/screenshots/space.png" width="240" alt="Gameplay in outer space"><br>Outer space</td>
    <td align="center"><img src="itch/screenshots/game-over.png" width="240" alt="Game over screen"><br>Game over</td>
  </tr>
</table>

Every platform, monster and power-up in one test scene:

<img src="itch/screenshots/elements.png" width="240" alt="All game elements on one screen">

## Features

- Moving, crumbling and vanishing platforms
- Monsters you can shoot or stomp, with limited ammo that reloads as you jump
- Springs, jetpack, shield, extra lives, bombs and triple shot
- Difficulty that rises as you climb
- Best score saved on your device
- 9 languages: English, Portuguese, Spanish, French, German, Italian, Russian, Korean and Chinese

## Controls

| Action | Keyboard and mouse | Touchscreen |
| ------ | ------------------ | ----------- |
| Move | Left/Right arrows or A/D | On-screen buttons |
| Shoot | Space, W, Up arrow or left click | On-screen button |
| Bomb | E, Down arrow or right click | On-screen button |

## Sprites

All the art is vector, in SVG, and lives in [assets/](assets/).

### Chicken

<table>
  <tr>
    <td align="center"><img src="assets/player/rising.svg" width="120" alt="Chicken rising"><br>Rising</td>
    <td align="center"><img src="assets/player/falling.svg" width="120" alt="Chicken falling"><br>Falling</td>
    <td align="center"><img src="assets/player/dead.svg" width="120" alt="Chicken defeated"><br>Defeated</td>
  </tr>
</table>

### Monsters

<table>
  <tr>
    <td align="center"><img src="assets/monsters/spiky.svg" width="90" alt="Spiky monster"><br>Spiky</td>
    <td align="center"><img src="assets/monsters/bat_up.svg" width="110" alt="Bat with wings up"><br>Bat, wings up</td>
    <td align="center"><img src="assets/monsters/bat_down.svg" width="110" alt="Bat with wings down"><br>Bat, wings down</td>
  </tr>
</table>

### Platforms

<table>
  <tr>
    <td align="center"><img src="assets/platforms/grass.svg" width="120" alt="Grass platform"><br>Grass</td>
    <td align="center"><img src="assets/platforms/moving.svg" width="120" alt="Moving platform"><br>Moving</td>
    <td align="center"><img src="assets/platforms/cloud.svg" width="120" alt="Vanishing cloud platform"><br>Cloud</td>
    <td align="center"><img src="assets/platforms/break_left.svg" width="120" alt="Left half of a breakable platform"><br>Breakable, left</td>
    <td align="center"><img src="assets/platforms/break_right.svg" width="120" alt="Right half of a breakable platform"><br>Breakable, right</td>
  </tr>
</table>

### Power-ups and items

<table>
  <tr>
    <td align="center"><img src="assets/items/jetpack.svg" width="44" alt="Jetpack"><br>Jetpack</td>
    <td align="center"><img src="assets/items/flame.svg" width="34" alt="Jetpack flame"><br>Flame</td>
    <td align="center"><img src="assets/items/shield.svg" width="60" alt="Shield"><br>Shield</td>
    <td align="center"><img src="assets/items/bubble.svg" width="70" alt="Shield bubble"><br>Bubble</td>
    <td align="center"><img src="assets/items/heart.svg" width="60" alt="Heart"><br>Heart</td>
  </tr>
  <tr>
    <td align="center"><img src="assets/items/bomb.svg" width="60" alt="Bomb"><br>Bomb</td>
    <td align="center"><img src="assets/items/triple.svg" width="60" alt="Triple shot"><br>Triple shot</td>
    <td align="center"><img src="assets/items/bullet.svg" width="34" alt="Bullet"><br>Shot</td>
    <td align="center"><img src="assets/items/spring_idle.svg" width="40" alt="Spring at rest"><br>Spring</td>
    <td align="center"><img src="assets/items/spring_up.svg" width="40" alt="Released spring"><br>Spring, released</td>
  </tr>
</table>

### Touch buttons and background

<table>
  <tr>
    <td align="center"><img src="assets/touch/left.svg" width="70" alt="Left button"><br>Left</td>
    <td align="center"><img src="assets/touch/right.svg" width="70" alt="Right button"><br>Right</td>
    <td align="center"><img src="assets/touch/shoot.svg" width="70" alt="Shoot button"><br>Shoot</td>
    <td align="center"><img src="assets/touch/bomb.svg" width="70" alt="Bomb button"><br>Bomb</td>
    <td align="center"><img src="assets/background/hills.svg" width="200" alt="Background hills"><br>Hills</td>
  </tr>
</table>

## Run from source

1. Install [Godot 4.7](https://godotengine.org/download).
2. Clone this repository and open `project.godot` in Godot.
3. Press F5 to run the game.

On Windows, if Godot was installed with WinGet, `jogar.cmd` starts the game directly.

## Export

Install the Godot export templates, then run `exportar.ps1` on Windows. It creates `ChickenJump-web.zip` and `ChickenJump-windows.zip` in `build/`. The script looks for a Godot installed with WinGet.

## Tests

The tests are scripts in `tests/`. For example:

```
godot --headless --fixed-fps 60 --path . --script res://tests/bugs.gd
```

The usage of each test is at the top of its file.

## Licenses

Third-party licenses, including those for Godot and the fonts, are in [LICENSES.txt](LICENSES.txt).
