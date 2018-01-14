;Masataka William
;Period 9
;Tetris draft

;Breed determines what shape the block is
breed [sticks stick]
breed [boxes box]
breed [pyramids pyramid]
breed [sBlocks sBlock]
breed [zBlocks zBlock]
breed [jBlocks jBlock]
breed [lBlocks lBlock]

;Patches get cleared depending on age and isMoving
patches-own [ isPatchMoving? stationary? designColor nextColor]
turtles-own [ isTurtleMoving? ]

;Terms
;Well - the playing field

;Sidebar - the 3 by 20 patch on the left side displaying next block and
;what block was saved

;Block/tetrominoes - the **PATCHES** colored representing blocks

;Invisible turtle - the turtle being controlled by the player
;and the tetrominoes are build based on the position of this turtle

;Sticks, pyramids... all the names of breed - names of tetrominoes

globals [
  ;Monitors
  level
  linesCleared
  goal

  ;List of blocks will spawn in the future
  nextBlocksList
]

;;;;;;;;;;
;;Setups;;
;;;;;;;;;;

to setup
  ca ;Removes previous games stats

  ;Game code setup
  setUpVariables

  ;Displays setup
  setUpWorld
end

;Sets up the displays
to setUpWorld
  resize-world 0 14 0 21
  set-patch-size 25
  createGameBorder
  createBorderLines
  setStationaryPatches
end

;Separates well from side bar
to createBorderLines
  ask patch 4 20 [
    sprout 1[
      set heading 0
      set color white
      fd .5
      lt 90
      fd .5
      pd
      lt 90
      fd 20
      die
    ]
  ]
end

;Pink border around the world
to createGameBorder
  ask patches with [pxcor = 0 or
    pxcor = 14 or
    pycor = 0 or
    pycor = 21 ][

    set pcolor pink
  ]
end

;Sets up patches variables and globals to prevent errors
;Errors from globals always being initializing as 0 and a []
to setupVariables
  ask patches[
    set isPatchMoving? false
    set stationary? true ;Will be changed to false in well during next setup procedure call
  ]

  ;Makes nextBlocksList an list
  set nextBlocksList []
  set level 1
end

to setStationaryPatches
  ;Makes everything an place to be able to put a block
  ask patches[
    set stationary? false
  ]
  ;Limits the places you can put down blocks
  ask patches with [pcolor = pink or pxcor <= 3][
    set stationary? true
  ]
end

to go
  every 1 - (1 / 20 * level) [
    createNextBlocksList ;Creates order to spawn blocks to drop

    ifelse not any? turtles with [isTurtleMoving?][
      spawnNextBlock
      ask turtles with [ isTurtleMoving? ][
        setPatchDesign
      ]
      updatePatches
    ][
      ;Blocks are created depending on the invisible turtle
      ;controlled by player and forced downward movement by the game

      ;Block movements
      moveBlockDown

      ;Clear line
      clearLines

      ;Monitors
      levelUp
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;
;;Blocks movement;;
;;;;;;;;;;;;;;;;;;;

;Checks if the block can move down and moves it down
;or makes the block stationary to represent it cannot
;go further down
to moveBlockDown
  ask turtles with [ isTurtleMoving?][
    ifelse canMoveDown?[
      clearPatchesMoving ;Hides the block on the scren
      set ycor ycor - 1 ;Moves the turtle down
      setPatchDesign ;SetPatchDesign and updatePatches work
      updatePatches  ;together to show block to player
    ][
      ;Makes it a stationary block that can no longer movs
      ask patches with [isPatchMoving?][
        set isPatchMoving? false
        set stationary? true
      ]
      die ;Allows for creating another block to drop
    ]
  ]
end

;Checks if there is a stationary block below
to-report canMoveDown?
  let canMove true
  ask patches with [isPatchMoving?][
    ask patch pxcor (pycor - 1)[
      if stationary? = true[
        set canMove false
      ]
    ]
  ]
  report canMove
end

;Removes all patches that are moving
;to allow for smooth movement
;Assisted by updatesPatches
to clearPatchesMoving
  ask patches with [isPatchMoving?][
    set isPatchMoving? false
    set pcolor black
  ]
end

;Shows block to player again
to updatePatches
  ask patches with [isPatchMoving?][
    set pcolor designColor
  ]
end

;;;;;;;;;;;;;;;;;;
;;Clearing lines;;
;;;;;;;;;;;;;;;;;;

to clearLines
  ;Create an for-loop with yPos being loop variable
  let yPos 19
  repeat 19[ ;Repeat 19 to cover all possible rows
    if (isRowFull? yPos)[
      clearRow yPos ;Clears the row
      moveRowsDown yPos ;Moves all the rows above down
    ]
    set yPos (yPos - 1)
  ]
end

to clearRow [yPos]
  ;Clears the row with the matching yPos and pxcor that are in the well
  ask patches with [pycor = yPos and isInWell?][
    set stationary? false ;Block can be placed on the row now
    set pcolor black ;Player won't see the original row anymore
  ]

  ;Add to counter that lines were cleared
  set linesCleared linesCleared + 1
end

to moveRowsDown [yPos]
  ask patches with [pycor > yPos and isInWell? and stationary?][
    set stationary? false ;Blocks can be placed on the patch

    ;Gives row below what color to change to
    ask patch pxcor (pycor - 1)[
      set nextColor [pcolor] of myself
    ]
    ;Clears the block from being seen
    set pcolor black
  ]

  ;Tells row below to change color only if it has a color to change to
  ask patches with [nextColor != 0][
    set pcolor nextColor
    set nextColor 0
    set stationary? true
  ]
end

;Checks if the entire row has a part of a block to be cleared
to-report isRowFull? [yPos]
  let full? true

  ;Creates an for-loop with xPos being the loop variable
  let xPos 4
  repeat 10[
    ask patch xPos yPos[
      if not stationary?[
        set full? false
      ]
    ]
    set xPos (xPos + 1)
  ]
  report full?
end

;Reports true if the patch is part of the well
to-report isInWell?
  report pxcor >= 4 and pxcor <= 13 and pycor < 21 and pycor > 0
end

;;;;;;;;;;;;
;;Monitors;;
;;;;;;;;;;;;

to levelUp
  ;every 10 lines cleared, game will speed up by 1/20 and level up
  set level ((floor linesCleared / 10) + 1)
end

;;;;;;;;;;;;;;;;;;;;;;;;;
;;Creating Blocks Logic;;
;;;;;;;;;;;;;;;;;;;;;;;;;

;Creates what the next 14* blocks will be
;Is actually 7 or 14 next blocks, but can just be assumed to be 14
to createNextBlocksList
  ;;Rules for creating blocks
  ;There are two bag each containg the seven possible tetris pieces. The computer
  ;will take a piece randomly from one bag at a time for the player to place down.
  ;Once the bag is empty, the computer will refill it and move to the second bag.
  ;Once the second bag is empty it will go back to the first bag to repeat this process.
  ;This process allows for the player to have an almost completely equal chance of every block
  ;** This is not a 2-D list, but a list with 14 elements
  ;** This algotherim is based on the original tetris with permutation set of 7

  ;This is all the pieces of blocks in tetris
  let POSSIBLE_BLOCKS (list sticks boxes pyramids sBlocks zBlocks jBlocks lBlocks)

  ;When player first starts, the two sets are generated
  if empty? nextBlocksList [
    ;Creates the first bag
    set nextBlocksList shuffle POSSIBLE_BLOCKS
    ;Creates the second bag
    let randomSet shuffle POSSIBLE_BLOCKS
    foreach randomSet [x -> set nextBlocksList lput x nextBlocksList] ;x is each element
  ]

  ;Every 7 blocks placed will generate another set of 7 blocks to add to queue
  if length nextBlocksList = 7[
    let randomSet shuffle POSSIBLE_BLOCKS
    foreach randomSet [blockElement -> set nextBlocksList lput blockElement nextBlocksList]
  ]
end

;Create the turtle at the center and sets the shape
to spawnNextBlock
  cro 1[
    set isTurtleMoving? true ;Tells computer to move this specific block
    set breed item 0 nextBlocksList ;Sets block to the next block in the list to create
    determineHeading ;Specific heading to prevent blocks from going fof the screen
    setxy 9 19 ;Middle of screen
    ;hide-turtle ;Player will only see the patches

    ;If the turtle spawns on a block, game is over because the well is filled
    if pcolor != black[
      ;Lost
    ]
  ]

  ;Tells game that the next piece is used up
  set nextBlocksList bf nextBlocksList
end

to determineHeading
  ifelse breed = sticks[ ;Prevents sticks from going off the screen
    set heading 270 ;Prevents block from sticking our randomly
  ][
    set heading 180
  ]
end

;;;;;;;;;;;;;;;;;
;;Blocks Design;;
;;;;;;;;;;;;;;;;;

;Patch's isPatchMoving? is set to true
;So that updatePatches procedure will set the color

;Asks the patches around the turtle to look like that of the block
to setPatchDesign
  ;Gives the design of the block (color and shape)

  if breed = sticks [
    sticksDesign
    colorChoices cyan
  ]
  if breed = boxes[
    boxesDesign
    colorChoices yellow
  ]
  if breed = pyramids[
    pyramidsDesign
    colorChoices magenta
  ]
  if breed = lBlocks[
    lBlocksDesign
    colorChoices orange
  ]
  if breed = jBlocks[
    jBlocksDesign
    colorChoices blue
  ]
  if breed = zBlocks[
    zBlockDesign
    colorChoices red
  ]
  if breed = sBlocks[
    sBlockDesign
    colorChoices green
  ]
end

to sticksDesign
  threeRowLine
  ask patch-at-heading-and-distance (heading + 180) 1[ set isPatchMoving? true ]
end

to boxesDesign
  ask patch-here [set isPatchMoving? true ]
  ask patch-ahead 1[ set isPatchMoving? true ]
  ask patch (xcor - 1) (ycor - 1) [ set isPatchMoving? true ]
  ask patch (xcor - 1) ycor [ set isPatchMoving? true ]
end

to pyramidsDesign
  twoRowLine
  ask patch-at-heading-and-distance (heading + 90) 1 [ set isPatchMoving? true]
  ask patch-at-heading-and-distance (heading + 200) 1 [ set isPatchMoving? true]
end

to lBlocksDesign
  threeRowLine
  ask patch-at-heading-and-distance (heading + 90) 1 [ set isPatchMoving? true ]
end

to jBlocksDesign
  threeRowLine
  ask patch-at-heading-and-distance (heading + 25) 2 [ set isPatchMoving? true ]
end

to sBlockDesign
  twoRowLine
  ask patch-at-heading-and-distance (heading + 90) 1 [ set isPatchMoving? true]
  ask patch-at-heading-and-distance (heading + 135) 1 [ set isPatchMoving? true]
end

to zBlockDesign
  ask patch-here [ set isPatchMoving? true ]
  ask patch-at-heading-and-distance ( heading + 180) 1 [ set isPatchMoving? true ]
  ask patch-at-heading-and-distance (heading + 90) 1 [ set isPatchMoving? true ]
  ask patch-at-heading-and-distance (heading + 35) 1 [ set isPatchMoving? true ]
end

;Helps make blocks design:

;Makes patches colored 3 in a line to prevent repetitive code
to threeRowLine
  ask patch-ahead 1 [
    set isPatchMoving? true
  ]
  ask patch-ahead 2 [
    set isPatchMoving? true
  ]
  ask patch-here [
    set isPatchMoving? true
  ]
end

; Makes patches colored 2 in a line to prevent repetitve code
to twoRowLine
  ask patch-here [
    set isPatchMoving? True
  ]
  ask patch-ahead 1 [
    set isPatchMoving? true
  ]
end

;Makes each block have an unique color
to colorChoices [colorChoice]
  ask patches with [isPatchMoving?][
    set designColor colorChoice
  ]
end


;;;;;;;;;;;;
;;Controls;;
;;;;;;;;;;;;
;Controls need to move patch not just turtle that is moving***

to lefty
  moveRight -1 ;same as moving left 1
end

to righty
  moveRight 1
end

;Moves to right
to moveRight [distanceMove]
  ask turtles with [ isTurtleMoving? ][
    clearPatchesMoving ;Removes block from screen
    set xcor xcor + distanceMove ;Moves the invisible turtle for testing
    setPatchDesign

    ;Undo the movement if the action
    ;breaks the game's rule
    if not validAction? [
      clearPatchesMoving
      set xcor xcor + (-1 * distanceMove)
      setPatchDesign
    ]

    ;Shows blocks to player again
    updatePatches
  ]
end

to down
  moveBlockDown
end

to rotateRight
  rotation 90
end

to rotateLeft
  rotation 270 ;Same thing as lt 90
end

;Rotation to right
to rotation [degree]
  ask turtles with [ isTurtleMoving? and breed != boxes ][
    clearPatchesMoving ;Removes block from screen
    rt degree ;Rotates the invisble turtle for testing
    setPatchDesign

    ;Undo rotation if the action
    ;breaks the game's rule
    if not validAction?[
      clearPatchesMoving
      rt 270 ;undo the rotation
      setPatchDesign
    ]
  ]

  ;Shows blocks to player again
  updatePatches
end

;Checks if what player does will go into
;an area it isn't suppose to (non-well area)
to-report validAction?
  let valid? true
  ask patches with [stationary?][
    if isPatchMoving?[
      set valid? false
      set isPatchMoving? false
    ]
  ]
  report valid?
end




@#$#@#$#@
GRAPHICS-WINDOW
255
10
638
569
-1
-1
25.0
1
10
1
1
1
0
1
1
1
0
14
0
21
0
0
1
ticks
30.0

MONITOR
10
53
67
98
NIL
level
17
1
11

MONITOR
10
114
113
159
Lines Cleared
linesCleared
17
1
11

MONITOR
78
53
135
98
NIL
goal
17
1
11

BUTTON
76
173
147
206
Down
down
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
7
171
70
204
Left
lefty
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

BUTTON
151
173
220
206
Right
righty
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

BUTTON
11
10
84
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
4
214
120
247
Rotate Left 
rotateLeft
NIL
1
T
OBSERVER
NIL
K
NIL
NIL
1

BUTTON
124
214
250
247
Rotate Right 
rotateRight
NIL
1
T
OBSERVER
NIL
L
NIL
NIL
1

BUTTON
110
14
173
47
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
