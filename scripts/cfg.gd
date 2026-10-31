class_name Cfg
## Ajustes do jogo reunidos em um lugar so.

const VIEW_W := 480.0
const VIEW_H := 800.0
const START_Y := 720.0
const PLAYER_START_Y := START_Y - 60.0
# Os SVGs sao rasterizados em dobro para continuarem nitidos em janela maior.
const ART_SCALE := Vector2(0.5, 0.5)

# Fisica do jogador. A altura do pulo normal e JUMP^2 / (2 * GRAVITY) = 224 px,
# entao GAP_MAX_HARD precisa ficar abaixo disso para o caminho ser sempre possivel.
const GRAVITY := 1500.0
const JUMP_VELOCITY := -820.0
const SPRING_VELOCITY := -1450.0
const JETPACK_VELOCITY := -1100.0
const JETPACK_TIME := 2.2
const MOVE_SPEED := 430.0
const MOVE_ACCEL := 2600.0
const SHOOT_COOLDOWN := 0.22
# Municao: a partida comeca cheia e cada JUMPS_PER_SHOT pulos devolvem um tiro.
const MAX_AMMO := 5
const JUMPS_PER_SHOT := 3

# Altura (em px) em que a dificuldade chega ao maximo.
const HARD_HEIGHT := 40000.0

const GAP_MIN_EASY := 45.0
const GAP_MAX_EASY := 80.0
const GAP_MIN_HARD := 110.0
const GAP_MAX_HARD := 180.0

const MOVING_EASY := 0.05
const MOVING_HARD := 0.40
# Plataformas extras (quebraveis ou que somem) ficam fora do caminho garantido.
const EXTRA_EASY := 0.10
const EXTRA_HARD := 0.50
const VANISHING_SHARE_EASY := 0.0
const VANISHING_SHARE_HARD := 0.5
const SPRING_CHANCE := 0.07

# Buffs: chance de surgir em cada plataforma comum.
const JETPACK_CHANCE := 0.012
const SHIELD_CHANCE := 0.014
const HEART_CHANCE := 0.006
const BOMB_CHANCE := 0.010
const TRIPLE_CHANCE := 0.012

const MAX_LIVES := 3
const MAX_BOMBS := 3
const TRIPLE_TIME := 10.0
const TRIPLE_SPREAD := 190.0
# Protecao apos reviver e apos o escudo absorver um golpe.
const REVIVE_PROTECTION := 2.5
const SHIELD_PROTECTION := 0.8

const MONSTER_MIN_HEIGHT := 2500.0
const MONSTER_MIN_SPACING := 1000.0
const MONSTER_CHANCE_EASY := 0.04
const MONSTER_CHANCE_HARD := 0.12
