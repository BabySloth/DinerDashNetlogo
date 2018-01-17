;Team name: Babysloths
;Masataka Mizuno
;William Cao
;Final Project -- Tetris
;1/15/18

breed [sideBarTurtles sideBarTurtle]         ;Tells what blocks are saved and upcoming blocks
breed [controllingTurtles controllingTurtle] ;Player is controlling this turtle (only one exist at once)
breed [ghosts ghost]                         ;Tells which blocks to be colored gray

patches-own [
  isStationary? ;If a block can be placed on the patch
  isBlockPart?  ;Whether it needs to be colored to represent it is part of a block
  blockColor    ;What the color needs to change to
  isControlled? ;Whether the block is being controlled by player
  nextColor     ;For moving rows down
  isSideBar? ;Prevents sidebar pieces from disappearing
  ghostisstationary?
  ghostiscontrolled?
  ghostisblockpart?
]

controllingTurtles-own[
  ;Checks if the player already used the hold button in this drop
  isUsedPiece?
]

turtles-own [
  pieceDesign   ;Tells what block the turtle is going to create
]

ghosts-own [
  stopit
]

globals [
  level           ;Monitor variables
  linesCleared
  nextBlocksList  ;What the next 14 blocks are
  canCreateBlock? ;If player loses, blocks can no longer be created
]

;;;;;;;;;
;;Setup;;
;;;;;;;;;

to setup
  clear-all

  ;Sets up how the map will look like
  setMapDesign

  ;Determines what area are playable
  setPlayAbleArea

  ;Makes nextBlocksList a variable
  set nextBlocksList []

  ;Makes side bar area
  setSideBar

  ;Telling game that the player wants to play (start/again)
  set canCreateBlock? true
end

to setMapDesign
  ;Resizes world
  resize-world 0 15 0 21
  set-patch-size 25

  ;Creates pink border around the world
  ask patches with [pxcor = 0 or
    pxcor = 15 or
    pycor = 0 or
    pycor = 21 or
    pxcor = 4][

    set pcolor pink
  ]

  ;Create white line separating holding piece from next pieces
  cro 1[
    setxy .5 15
    set color white
    set heading 90
    pd
    fd 3
    die
  ]
end

to setPlayAbleArea
  ;Makes everything playable
  ask patches[
    set isStationary? false
    set isBlockPart? false
    set isControlled? false
    set isSideBar? false
  ]

  ;Narrows down to only well being playable
  ask patches with [pcolor = pink or pxcor <= 3][
    set isStationary? true
  ]
  ;Makes side bar distinct because blocks exist in an stationary area, which isn't allow in well
  ask patches with [pcolor = black and pxcor <= 3][
    set isSideBar? true
  ]
end

to setSideBar
  ;Hold piece
  ask patch 2 20[                ;Text display
    set plabel "Hold"
  ]

  create-sideBarTurtles 1[       ;This turtle shows what piece is being held
    setxy 2 18
  ]

  ask patch 2 15 [               ;Text display
    set plabel "Next"
  ]

  ;Shows what the next pieces are
  create-sideBarTurtles 1[
    setxy 2 13
  ]
  create-sideBarTurtles 1[
    setxy 2 8
  ]
  create-sideBarTurtles 1[
    setxy 2 3
  ]


  ;How both turtles will appear
  sideBarTurtleDesign
end

to sideBarTurtleDesign
  ask sideBarTurtles[
    set pieceDesign "null"         ;Doesn't have anything to switch to in the beginning
    hide-turtle                    ;Player doesn't need to see it
    set heading 180                ;180 to fit all the parts of the pieces
    setBlockPartsPatches           ;Makes the patches have a design to make it look like a tetris block
  ]
  ask patches with [isBlockPart?][ ;Shows the tetris parts to the player
    set pcolor blockColor
  ]
end

;;;;;;
;;Go;;
;;;;;;

to go
  if canCreateBlock?[ ;Only runs if the player did not lost yet
    ;Clear the row and add to monitors, needs to be outside of every for smooth removal
    clearLinesLogic

    every .75 [       ;Determines speed of dropping blocks
      createNextBlocksList               ;Determines order to drop blocks
      levelUp
      clearBlockPatches                  ;Clears blocks moving for illusion of it moving

      ifelse not any? controllingTurtles[
        createControllingTurtle false    ;Creates a turtle if player just placed one down
      ][
        moveBlockDown                    ;Moves the turtle down allowing for blocks to move down
      ]

      updateSideBar
      nextghostpieces
      ghostpieces
      showBlockPatches
    ]
  ]
end

;;;;;;;;;;;;;;;;;;
;;Update sidebar;;
;;;;;;;;;;;;;;;;;;

to updateSideBar
  clearSideBarPieces
  updateNextPieces ;Update display on side to correctly match what next pieces are
  updateHoldPieces
  showSideBarPieces
end

to updateHoldPieces
  ask sideBarTurtle 1[
    setBlockPartsPatches
  ]
end

to updateNextPieces
  ;Asks bottom 3 turtles in sidebar to show what their next pieces are
  ask sideBarTurtles with [who > 1][
    set pieceDesign item (who - 2) nextBlocksList
    setBlockPartsPatches
  ]
end

;Shows the block
to showSideBarPieces
  ask patches with [isBlockPart? and isSideBar?][
    set pcolor blockColor
  ]
end

;Clears the block and updates to next block to display
to clearSideBarPieces
  ask patches with [isSideBar?][
    set isBlockPart? false
    set blockColor 0
    set pcolor black
  ]
end

;;;;;;;;;;;;
;;Movement;; ;;Some procedures are used in button's control (see bottom of Code)
;;;;;;;;;;;;

to moveBlockDown
  ask controllingTurtles[
    clearBlockPatches         ;Hides view
    set ycor (ycor - 1)       ;Tries to move block down
    setBlockPartsPatches      ;^

    ifelse validAction?[
      showBlockPatches
    ][
      ;Cannot move block down
      set ycor (ycor + 1)     ;Undo
      clearBlockPatches       ;^
      setBlockPartsPatches    ;^
      showBlockPatches        ;Show parts again to the player
      makeDropStationary      ;Makes the block stay and allows for another block to be made
    ]
  ]
end

to makeDropStationary
  ask patches with [isControlled?][
    set isStationary? true
    set isControlled? false
    set isBlockPart? false
  ]

  die ;Allows for another piece to spawn
end

;Procedure requires you do the action then
;Check if it is valid, if not: undo it
to-report validAction?
  let isValid? true ;Assumes it is a legal move
                    ;Checks if block is in an area is isn't suppose to
  ask patches with [isStationary?][
    if isControlled? [
      ;If it is, report false and fix variables(isBlockPart?)
      set isValid? false
      set isBlockPart? false
      set isControlled? false
    ]
  ]
  report isValid?
end

;;;;;;;;;;;;;;;;;;;
;;Block movements;; ;;Blocks are just patches chaning color to appear like they are moving
;;;;;;;;;;;;;;;;;;; ;;Deals with pieces in the well

;Removes all moving blocks
to clearBlockPatches
  ask patches with [isControlled? and isInWell?][
    set isControlled? false
    set isBlockPart? false
    set pcolor black
  ]
end

;Makes the blocks appear again
to showBlockPatches
  ask patches with [isBlockPart? and isInWell?][
    set pcolor blockColor
  ]
end

;;;;;;;;;;;;;;;
;;Ghost piece;;
;;;;;;;;;;;;;;;
to ghostPieces
  ask patches with [iscontrolled?]
  ; this will tell the piece that is moving to make a copy of itself
  [sprout 1 [
    set breed ghosts
    set hidden? true
    set heading 180
    set stopIt false
  ]]

  repeat 20[
    ask ghosts [
      if stopIt = false[
        if [isstationary?] of patch-ahead 1 = true[
          ask ghosts [ set stopIt true]
        ]
      ]
    ]
    ask ghosts [
      if stopIt = false [ fd 1]
    ]
  ]
  if count ghosts != 0
  [ ask ghosts [set pcolor gray set ghostiscontrolled? true]]
end

to nextGhostPieces
  if count ghosts != 0 or not canCreateBlock?[  ;Asks all ghosts block to be cleared or if the game is over
    ask patches with [pcolor = gray][
      set pcolor black]
    ask ghosts [
      die
    ]
  ]
  ask patches with [ pcolor = gray][
    if iscontrolled? [
      set pcolor [pcolor] of one-of patches with [iscontrolled?]
    ]
  ]

end

to-report ghostvalidAction?
  let ghostisValid? true ;Assumes it is a legal move
                         ;Checks if block is in an area is isn't suppose to
  ask patches with [ghostisStationary?][
    if ghostisControlled? [
      ;If it is, report false and fix variables(isBlockPart?)
      set ghostisValid? false
      set ghostisBlockPart? false
      set ghostisControlled? false
    ]
  ]
  report ghostisValid?
end

;;;;;;;;;;;;;;;;;;
;;Clearing lines;; NOTE: We did not follow rules of 1 line cleared = 1 line, 2 lines cleared = 3 lines on outline
;;;;;;;;;;;;;;;;;; because it will be too confusing for the player and code

to clearLinesLogic
  ;Creates a nested for-loop to check every row if they are fill
  let yPos 19 ;Checks up to down
  repeat 19[
    if (isRowFull? yPos)[
      clearRow yPos       ;Removes tetris pieces from the row
      moveRowsDown yPos   ;Makes all stationary tetris pieces from above move down
    ]
    set yPos (yPos - 1)   ;Moves on to the row below to check if they are full (loop)
  ]
end

to-report isRowFull? [yPos]
  let isFull? true

  ;Creates an for-loop with xPos being the loop variable
  let xPos 4 ;Minimum pycor of the well is 4
  repeat 11[
    ask patch xPos yPos[
      if not isStationary?[ ;If there exist a gap, the row is not full
        set isFull? false
      ]
    ]
    set xPos (xPos + 1)     ;Moves from left side of row to right side of row (loop)
  ]
  report isFull?            ;Report back after checking if row is full
end

to clearRow [yPos]
  ;Removes blocks in yPos row inside the well
  ask patches with [pycor = yPos and isInWell?][
    set isStationary? false   ;Blocks can be placed again
    set pcolor black          ;Tells player block can be placed again there
  ]

  ;Add to counter for leveling up
  set linesCleared linesCleared + 1
end

to moveRowsDown [yPos]
  ;Only move down rows above the one cleared
  ask patches with [pycor > yPos and isInWell? and isStationary?][
    set isStationary? false ;Every block is moving down, so the space is clear for blocks to be placed

    ask patch pxcor (pycor - 1)[        ;Gives row below what color to change to
      set nextColor [pcolor] of myself
    ]
    set pcolor black                    ;Clears the patches from being seen
  ]

  ;Tells row below to change only if it has a color to change to
  ;**No blocks can be colored 0
  ask patches with [nextColor != 0][
    set pcolor nextColor
    set nextColor 0
    set isStationary? true
  ]
end

;Reports true if the patch is part of the well
to-report isInWell?
  report pxcor >= 5 and pxcor <= 14 and pycor < 21 and pycor > 0
end

;;;;;;;;;;;;;;;;;;;;;;;;;
;;Creating blocks logic;;
;;;;;;;;;;;;;;;;;;;;;;;;;

;Creates next 14(actually 7 to 14, but can just be assumed to be 14 blocks) to be created
to createNextBlocksList
  ;;Rules for creating blocks explained using bags:
  ;There are two bag each containg the seven possible tetris pieces. The computer
  ;will take a piece randomly from one bag at a time for the player to place down.
  ;Once the bag is empty, the computer will refill it and move to the second bag.
  ;Once the second bag is empty it will go back to the first bag to repeat this process.
  ;This process allows for the player to have an almost completely equal chance of every block
  ;** This is not a 2-D list, but a list with 14 elements
  ;** This algotherim is based on the original tetris with permutation set of 7

  ;This is all the pieces of blocks in tetris
  let POSSIBLE_BLOCKS (list "sticks" "boxes" "pyramids" "sBlocks" "zBlocks" "jBlocks" "lBlocks")

  ;When player first starts, the two bags are generated
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

to createControllingTurtle [used?]
  create-controllingTurtles 1[
    setxy 9 19                             ;Top middle of the screen
    set pieceDesign item 0 nextBlocksList  ;What type of block is dropping
    set heading 90                         ;Fit all the pieces of the tetris block
    hide-turtle                            ;Player does not need to see it
    setBlockPartsPatches                   ;Player can see the blocks
    set isUsedPiece? used?                 ;Determines if the player can save the piece or is forced to drop it
    if not validAction?[                   ;The player filled up too many spaces to fit room for another piece
       set canCreateBlock? false             ;Prevents more blocks from being created
      setLostScreen
    ]

    if pcolor != black[                    ;Player cannot fill up to the 19th spot

    ]
  ]

  ;nextBlocksList needs to removed the used up block
  set nextBlocksList bf nextBlocksList
end

;;;;;;;;;;;;;;;
;;Lost screen;;
;;;;;;;;;;;;;;;

to setLostScreen
  clearObjects
  ask patch 14 11[
    set plabel "You Lost, Please Click Restart To Begin Again"
  ]
end

;Removes all except border
to clearObjects
  ask controllingTurtles[
    set pieceDesign "null"   ;Prevent pieces from creating something
  ]
  ask patches with [pcolor != pink][
    set pcolor black
    set blockColor 0
    set isBlockPart? false
  ]
end

;;;;;;;;;;;;
;;Leveling;;
;;;;;;;;;;;;

to levelUp
  ;every 10 lines cleared, game will speed up by 1/20 and level up
  set level ((floor linesCleared / 10) + 1)
end


;;;;;;;;;;;;;;;;;;;;;;;
;;Tetris block design;;
;;;;;;;;;;;;;;;;;;;;;;;

;Must be called by sideBarTurtles or controllingTurtles
to setBlockPartsPatches
  let colorDesign 0           ;Determines what color the blocks are
  if pieceDesign = "sticks" [
    sticksDesign
    set colorDesign cyan
  ]
  if pieceDesign = "boxes"[
    boxesDesign
    set colorDesign yellow
  ]
  if pieceDesign = "pyramids"[
    pyramidsDesign
    set colorDesign magenta
  ]
  if pieceDesign = "lBlocks"[
    lBlocksDesign
    set colorDesign orange
  ]
  if pieceDesign = "jBlocks"[
    jBlocksDesign
    set colorDesign blue
  ]
  if pieceDesign = "zBlocks"[
    zBlockDesign
    set colorDesign red
  ]
  if pieceDesign = "sBlocks"[
    sBlockDesign
    set colorDesign green
  ]

  setColorToChangeTo colorDesign ;Makes the tetris block update its color
end

to setColorToChangeTo [colorDesign]
  ;Because every patch has the same variable of isBlockPart? and blockColor,
  ;I can't do ask patches with [isBlockPart?] and must go through each breed calling this

  ;For patches in the well
  if breed = controllingTurtles[
    ask patches with [not isSideBar? and isBlockPart?][ ;;Do not use isInWell?
      set isControlled? true
      set blockColor colorDesign
    ]
  ]

  ;For patches that is showing what piece is being held
  if breed = sideBarTurtles and who = 1[
    ask patches with [ isSideBar? and
      pycor >= 15 and pycor <= 20 and isBlockPart?][

      set blockColor colorDesign
    ]
  ]

  ;;For patch that is showing what piece is next:

  if breed = sideBarTurtles and who = 2[
    ask patches with [ isSideBar? and
      pycor >= 11 and pycor <= 14 and isBlockPart?] [

      set blockColor colorDesign
    ]
  ]

  if breed = sideBarTurtles and who = 3[
    ask patches with [ isSideBar? and
      pycor >= 6 and pycor <= 9 and isBlockPart?] [

      set blockColor colorDesign
    ]
  ]
  if breed = sideBarTurtles and who = 4[
    ask patches with [ isSideBar? and
      pycor >= 1 and pycor <= 5 and isBlockPart?] [

      set blockColor colorDesign
    ]
  ]
end

to sticksDesign
  threeRowLine
  ask patch-ahead 2[ set isBlockPart? true ]
end

to boxesDesign
  ask patch-here [set isBlockPart? true ]
  ask patch-ahead 1 [ set isBlockPart? true ]
  ask patch-right-and-ahead 45 1 [ set isBlockPart? true ]
  ask patch-right-and-ahead 90 1 [ set isBlockPart? true ]
end

to pyramidsDesign
  threeRowLine
  ask patch-left-and-ahead 90 1 [ set isBlockPart? true ]
end

to lBlocksDesign
  threeRowLine
  ask patch-left-and-ahead 45 1 [ set isBlockPart? true ]
end

to jBlocksDesign
  threeRowLine
  ask patch-at-heading-and-distance (heading + 225) 1 [ set isBlockPart? true ]
end

to sBlockDesign
  ask patch-here [set isBlockPart? true]
  ask patch-ahead 1 [set isBlockPart? true]
  ask patch-right-and-ahead 90 1 [set isBlockPart? true]
  ask patch-right-and-ahead 135 1 [set isBlockPart? true]
end

to zBlockDesign
  ask patch-here [set isBlockPart? true]
  ask patch-right-and-ahead 180 1 [set isBlockPart? true]
  ask patch-right-and-ahead 90 1 [set isBlockPart? true]
  ask patch-right-and-ahead 45 1 [set isBlockPart? true]
end

;;Helps make blocks design:
;Makes patches colored 3 in a line to prevent repetitive code
to threeRowLine
  ask patch-at-heading-and-distance (heading + 180) 1 [ set isBlockPart? true ]
  ask patch-ahead 1 [ set isBlockPart? true ]
  ask patch-here [ set isBlockPart? true ]
end

;;;;;;;;;;;;
;;Controls;; ;;Some commands are from movement code (see above)
;;;;;;;;;;;;

;;Movement to right, left, down

to moveLeft
  movementR -1 ;Effectively same as moving left 1 unit
end

to moveRight
  movementR 1
end

;Movement to 1 patch to the right
to movementR [distanceRight]
  ;Only works if the player is able to play a piece
  if canCreateBlock?[
    ask controllingTurtles[ ;Boxes have no reason to rotate
    clearBlockPatches                                   ;Removes block from screen
    set xcor (xcor + distanceRight)                     ;Tries to move
    setBlockPartsPatches                                ;^

    ;Undo rotation if action breaks game's rule
    if not validAction?[
      clearBlockPatches
      set xcor (xcor + (-1 * distanceRight))            ;Undo
      setBlockPartsPatches
    ]

    ;Show block to player again
    showBlockPatches
    ;Show block to player again
      nextGhostPieces
    ghostPieces
    ]
  ]
end

to moveDown
  moveBlockDown
end

;;Rotation

to rotateLeft
  rotation 270 ;Effectively same as turing 90 degrees left
end

to rotateRight
  rotation 90
end

to rotation [degreeRight]
  ;Only works if the player is able to play a piece
  if canCreateBlock?[
    ask controllingTurtles with [pieceDesign != "boxes"][ ;Boxes have no reason to rotate
    clearBlockPatches    ;Removes block from screen
    rt degreeRight       ;Tries to rotate
    setBlockPartsPatches ;^

    ;Undo rotation if action breaks game's rule
    if not validAction?[
      clearBlockPatches
      rt 270             ;Undo
      setBlockPartsPatches
    ]

    ;Show block to player again
    showBlockPatches
    ;Show ghost piece
    nextGhostPieces
    ghostPieces
  ]
  ]
end

to holdPiece
  ;Only works if the player is able to play a piece
  if canCreateBlock?[
    let pieceToHold "null"
    ;If player already held the piece and is trying to do it
  ;in the same run, this procedure will not run
  let procedureRun? true

  ask controllingTurtles[
    ;Only works if it is not a usedPiece
    ifelse isUsedPiece?[
      set procedureRun? false  ;Player already click hold in the run
    ][
      set pieceToHold pieceDesign ;Tells sidebar turtle to display the piece being held
    ]
  ]

  if procedureRun?[

    ask sideBarTurtle 1[
      if pieceDesign != "null"[   ;Piece was saved before
        set nextBlocksList fput pieceDesign nextBlocksList ;Make the next block to spawn be the one that was saved
      ]
      set pieceDesign pieceToHold ;Makes the turtle appear like the block saved
    ]
    ask controllingTurtles[
      die ;Enables for using the next block/saved block
    ]
    ;Makes a controlling turtle with true as parameter to tell the game that they cannot rehold
    createControllingTurtle true
  ]
  ]
end

;Restarting is just pressing setup again
to restart
  setup
end









@#$#@#$#@
GRAPHICS-WINDOW
257
10
665
569
-1
-1
25.0
1
11
1
1
1
0
1
1
1
0
15
0
21
0
0
1
ticks
30.0

MONITOR
6
45
63
90
NIL
level
17
1
11

MONITOR
6
94
109
139
Lines Cleared
linesCleared
17
1
11

BUTTON
74
144
145
177
Down
moveDown
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
6
144
69
177
Left
moveLeft
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
150
144
219
177
Right
moveRight
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
6
10
79
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
6
181
122
214
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
126
181
252
214
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
83
10
146
43
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

BUTTON
6
217
69
250
Hold
holdPiece
NIL
1
T
OBSERVER
NIL
C
NIL
NIL
1

BUTTON
151
10
224
43
NIL
restart
NIL
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
