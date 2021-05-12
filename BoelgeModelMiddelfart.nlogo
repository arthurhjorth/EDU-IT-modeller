extensions [table]

globals [
  start-wave ;; for drawing a wave
  end-wave ;; for drawing a wave, not sure we need it
  sea-patches
  drop-width k
  three-d?

  impact
  angle  ;; this can be used to easily create waves
  surface-tension
  friction

  hour ;keeping track of time

  testing
  colortest
]

turtles-own [xpos ypos zpos delta-z neighbor-turtles]

patches-own [
  depth base-height current-momentum next-momentum

  terrain-height ;baseret på kort fra DKs højdemodel
  soil-type
  satiety ;mæthedsgrad
  water-level
]

breed [momentums momentum]
momentums-own [force nearby-momentums forces-next-turn]

to setup
  ca
  set-terrain-height
  ;import-map



  ;import-pcolors "middelfart2.png"

;  ask patches with [shade-of? pcolor sky] [set pcolor blue] ;; this is too inclusive
;  set sea-patches patches with [pcolor = blue]
;  set-default-shape turtles "circle"
;  ask sea-patches [sprout 1  [
;    set color blue
;    set zpos 0
;    set xpos xcor
;    set ypos ycor
;    set delta-z 0
;;    show (list xcor ycor)
;    ]
;  ]
;  ask turtles [
;    set neighbor-turtles turtles-on neighbors4
;  ]
;  set drop-width 2
;
;  set impact 9
;  set angle 90 ;; this can be used to easily create waves
;  set surface-tension 51
;  set friction 94
;  set three-d? false

  set hour 0
  reset-ticks
end

to go

  ;update time
  if ticks mod (24 * 4) = 0 [set hour 0] ;here it loops around from 23 to 0
  print hour
  if ticks mod 4 = 0 and ticks > 0 [set hour hour + 1] ;each tick is 15 minutes ;FIX THIS
  print hour


  ;old wave stuff:
  if (mouse-down?) [
    ask turtles [release-drop mouse-xcor mouse-ycor]
  ]
    ask turtles [compute-delta-z]
    ask turtles [update-position-and-color]

  tick
end

to set-terrain-height
  ;import-pcolors "mf-terrain.png"
  import-pcolors "mf-terrain-grayscale.png"
  ask patches with [pcolor = white] [set pcolor sky] ;the sea
  ask patches with [pcolor = 89.9] [set pcolor 9.8] ;the extreme values, only a few patches
  ask patches with [pcolor = 39.9] [set pcolor 9.8]

  ;now pcolors range from 1.5 to 9.8 ...
  ;and the terrain should be from around 13.5 to 1.5 meters...


  set testing sort [pcolor] of patches
  ;show table:counts testing


  ;transform/scale the colors:


end

to show-pcolor
  if mouse-inside? [
    ask patch mouse-xcor mouse-ycor [set colortest pcolor]
  ]
end

to-report unique-pcolor-nr
  set testing [pcolor] of patches
  report length table:keys table:counts testing
end


to import-map
  ;import-pcolors "middelfart3.png"
  ;import-pcolors "mf-map-simple.png"
  import-pcolors "mf-map-contrast.png"
  ;import-pcolors "mf-terrain.png"

end

to color-correct-terrain ;used after import of terrain map
  ask patches with [shade-of? pcolor red] [set pcolor pink]
  ask patches with [shade-of? pcolor orange] [set pcolor grey]
  ask patches with [shade-of? pcolor yellow] [set pcolor violet]
  ask patches with [shade-of? pcolor green] [set pcolor yellow]
  ask patches with [shade-of? pcolor turquoise] [set pcolor orange]
  ask patches with [shade-of? pcolor blue] [set pcolor green]
  ask patches with [shade-of? pcolor sky] [set pcolor green]
  ask patches with [ count neighbors4 with [shade-of? pcolor green ] = 4 ] [set pcolor green]
  ask patches with [ count neighbors4 with [shade-of? pcolor yellow ] = 4 ] [set pcolor yellow]
  ask patches with [ count neighbors4 with [shade-of? pcolor violet ] = 4 ] [set pcolor violet]
end

to color-correct-map
  ask patches with [shade-of? pcolor blue] [set pcolor blue]
  ask patches with [shade-of? pcolor red] [set pcolor brown]
  ask patches with [shade-of? pcolor orange] [set pcolor brown]
  ask patches with [shade-of? pcolor yellow] [set pcolor white]
  ask patches with [shade-of? pcolor brown] [set pcolor orange]
  ask patches with [shade-of? pcolor orange] [set pcolor 18]
  repeat 4 [ ask patches with [ count neighbors4 with [shade-of? pcolor blue ] >= 3 ] [set pcolor blue] ]
end

to rainfall


end

to wave

end

to build-wall
  ;
end


;INTERFACE REPORTERS:

to-report minute
  if ticks mod 4 = 0 [report "00"]
  if ticks mod 4 = 1 [report "15"]
  if ticks mod 4 = 2 [report "30"]
  if ticks mod 4 = 3 [report "45"]
end

to-report str-time ;for interface
  report (word hour ":" minute)
end

to-report day
  report ticks mod (24 * 4)
end

to-report nedsivningsevne
  ;baseret på https://www.plastmo.dk/beregnere/faskineberegner.aspx
  if jordtype = "Groft sand" [report 0.001] ;10^-3
  if jordtype = "Fint sand" [report 0.0001] ;10^-4
  if jordtype = "Fint jord" [report 0.00001] ;10^-5
  if jordtype = "Sandet ler" [report 0.000001] ;10^-6
  if jordtype = "Siltet ler" [report 0.0000001] ;10^-7
  if jordtype = "Asfalt" [report 0] ;ingen nedsivning @?
end

to-report nedsivningsevne-interface ;as string (so shown as decimal nr)
  ;baseret på https://www.plastmo.dk/beregnere/faskineberegner.aspx
  if jordtype = "Groft sand" [report "0.001 m/sek"] ;10^-3
  if jordtype = "Fint sand" [report "0.0001 m/sek"] ;10^-4
  if jordtype = "Fint jord" [report "0.00001 m/sek"] ;10^-5
  if jordtype = "Sandet ler" [report "0.000001 m/sek"] ;10^-6
  if jordtype = "Siltet ler" [report "0.0000001 m/sek"] ;10^-7
  if jordtype = "Asfalt" [report "Ingen nedsivning"] ;ingen nedsivning @?
end


;TING FRA BØLGEMODELLEN:

to release-drop    [drop-xpos drop-ypos]    ;Turtle procedure for releasing a drop onto the pond
  if (((xpos - drop-xpos) ^ 2) + ((ypos - drop-ypos) ^ 2) <= ((.5 * drop-width) ^ 2))
[set delta-z (delta-z + (k * ((sum [zpos] of neighbor-turtles) -
        ((count neighbor-turtles) * zpos) - impact)))]
;  show delta-z
end

to compute-delta-z    ;Turtle procedure
   set k (1 - (.01 * surface-tension))        ;k determines the degree to which neighbor-turtles'
  set delta-z (delta-z + (k * ((sum [zpos] of neighbor-turtles) - ((count neighbor-turtles) * zpos))))
end

to update-position-and-color  ;Turtle procedure
  set zpos ((zpos + delta-z) * (.01 * friction))    ;Steal energy by pulling the turtle closer
  set color scale-color blue zpos 100 -100            ;to ground level
  ifelse three-d?
   [
     let y (zpos + (ypos * sin angle))
     let x (xpos + (ypos * cos angle))
     ifelse patch-at (x - xcor) (y - ycor) != nobody
      [ setxy x y show-turtle ]
      [ hide-turtle ]]
   [
     ifelse patch-at (xpos - xcor) (ypos - ycor) != nobody
      [ setxy xpos ypos
      show-turtle ]
      [ hide-turtle ]]
end
@#$#@#$#@
GRAPHICS-WINDOW
250
10
973
385
-1
-1
3.7831
1
10
1
1
1
0
0
0
1
-94
94
-48
48
0
0
1
ticks
30.0

BUTTON
135
30
210
63
NIL
go\n
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
35
30
108
63
NIL
setup\n
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
1355
90
1465
123
Make wave
ask sea-patches with [pycor = 54] [ask turtles-here [set zpos wave-strength]]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
75
270
235
315
Jordtype
Jordtype
"Groft sand" "Fint sand" "Fint jord" "Sandet ler" "Siltet ler" "Asfalt"
1

BUTTON
400
480
500
525
Lav bølge
wave
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
675
480
777
525
Start nedbør
rainfall
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
985
265
1082
310
Hav-vandstand
\"x meter\"
17
1
11

MONITOR
985
325
1082
370
Vandspejl
\"x meter\"
17
1
11

SLIDER
1325
50
1497
83
wave-strength
wave-strength
1
1000
389.0
1
1
NIL
HORIZONTAL

SLIDER
35
115
210
148
hav-niveau
hav-niveau
0
100
50.0
1
1
m
HORIZONTAL

MONITOR
985
65
1040
110
Tid
str-time
17
1
11

MONITOR
75
320
235
365
Jordens nedsivningsevne
nedsivningsevne-interface
17
1
11

SLIDER
600
390
850
423
mm-per-30-min
mm-per-30-min
0
50
10.0
1
1
mm
HORIZONTAL

SLIDER
600
430
850
463
nedbør-varighed
nedbør-varighed
0
5
1.5
.25
1
timer
HORIZONTAL

BUTTON
1360
330
1490
363
NIL
color-correct-terrain
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
1360
375
1487
408
NIL
color-correct-map
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
985
15
1040
60
Dag
day
17
1
11

SLIDER
355
390
540
423
bølge-højde
bølge-højde
0
300
90.0
5
1
cm
HORIZONTAL

SLIDER
355
430
540
463
bølge-styrke
bølge-styrke
0
50
8.0
1
1
NIL
HORIZONTAL

BUTTON
65
435
230
495
BYG EN BØLGEBRYDER
build-wall
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
1115
90
1205
123
NIL
show-pcolor
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1115
45
1205
90
NIL
colortest
17
1
11

BUTTON
1135
190
1257
223
draw height lines
import-drawing \"mf-heightline-ref.png\"
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
1220
235
1322
268
NIL
clear-drawing
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1185
130
1280
175
NIL
unique-pcolor-nr
17
1
11

BUTTON
1275
190
1382
223
draw city map
import-drawing \"mf-map.png\"
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
1360
295
1505
328
import rainbow terrain
import-pcolors \"mf-terrain.png\"
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
NetLogo 6.2.0
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
1
@#$#@#$#@
