extensions [ nw ]

globals [
  activate-initial-adopter?
  mouse-was-down?

  current-pen ;saving the plot pen name
  starting-tick ;for plotting ticks since beginning

  nice-colors ;for plotting
  remaining-pen-colors ;for plotting
  pen-counter ;for plotting

  first-go? ;keeping track in go-procedure (for setup-plot)
  show-labels?
]

breed [nodes node] ;a breed so we can layer the banner labels on top
breed [banners banner] ;used for label positioning

nodes-own [
first-exposed
first-adopted

times-exposed
times-adopted
times-dropped

adopted?
adopted-this-turn?

initial-round-percentage-contacts-adopted


]

to setup-network
  set nice-colors [15 65 105 25 44 115 35 125 75 85 135 5 0 55 95 125 46 17 133 23 117]
  let saved-colors ifelse-value (remaining-pen-colors = 0) [nice-colors] [remaining-pen-colors] ;if =0, it's the first time, and nothing has been used
  let saved-pen-counter pen-counter

  ;CLEARING:
  clear-globals clear-ticks clear-turtles clear-patches clear-drawing clear-output ;everything from clear-all EXCEPT clear-all-plots (so we can compare plots from different runs)

  ;workaround, globals we don't want deleted in clearing now re-saved:
  set remaining-pen-colors saved-colors
  set pen-counter saved-pen-counter
  set first-go? true ;for go procedure and setup-plot
  set show-labels? false ;dropped this... but code still there, if we wanna go back (only works for color-by time since adopted)

  import-network-structure
  ask nodes [setup-nodes]
  ask links [set-link-shape]

  ask patches [set pcolor 1] ;dark grey
  ask links [set color 7] ;a bit lighter grey than the default

  ;potentially 'infect' an initial node:
  ;if activate-initial-adopter? [
   ; ask one-of nodes [adopt]
  ;]
  reset-ticks
end

to change-nw-layout
  if network-structure = "small world (100)" [
    repeat 3 [layout-spring turtles links 1 0 0 ]
      repeat 6 [layout-spring turtles links 0 0 1 ]
  ]


  if network-structure = "small world (196)" [
    repeat 5 [layout-spring turtles links 1 0 0]
    repeat 6 [layout-spring turtles links 0 0 0.5] ;kan også lave mere luft om nødvendigt
  ]


end

to setup-plot ;after the ideas have been planted and the spreading mechanisms have been set
  initiate-quantity-adopted-plot
  update-quantity-adopted-plot
end

to setup-task ;auto-setup settings for the tasks
  if task = "Task 1a" [ ;figure out highest possible conformity rate for it to spread to everyone. simple.
    set network-structure "lattice (196)"
    setup-network
    ask node 35 [adopt]
    set mechanism-for-spreading "Conformity threshold"
    set conformity-threshold 1
    set drop-out-threshold 0

  ]

  if task = "Task 1b (Small world 100)" [
    set network-structure "small world (100)"
    setup-network
    set mechanism-for-spreading "Conformity threshold"
    set conformity-threshold 26
    set drop-out-threshold 0
  ]

  if task = "Task 1b (Small world 196)" [
    set network-structure "small world (196)"
    setup-network
    set mechanism-for-spreading "Conformity threshold"
    set conformity-threshold 26
    set drop-out-threshold 0
  ]



end


to go
  if first-go? [
    setup-plot
    set first-go? false
  ]
  ;setup-plot ;sets up the plot pen with the chosen settings ;should only be run the FIRST time!@@@@ so we can remove interface button!

  every 0.4 [
    if not any? nodes with [not adopted?] [stop] ;stop model if everyone has adopted

    ask nodes [ set initial-round-percentage-contacts-adopted percentage-contacts-adopted ] ;turtle variable fastlåses, % nabo-adopters, så den ikke skifter, når andre begynder at skifte i dette tick

    ;spread the innovation:
    spread


    ;dropout:
    ask nodes [
      if drop-out? and adopted? and not adopted-this-turn? [ ;can only dropout if they've been adopters for at least one turn (so it has had time to visualise)
        consider-drop-out
      ]

      recolor ;nodes recolor based on whether or not they have the innovation
    ]

    update-quantity-adopted-plot

    ask nodes [ set adopted-this-turn? false ]

    tick

  ]
end

to adopt ;node procedure, run when the innovation is adopted
  set adopted? true
  set adopted-this-turn? true

  ;; If RESET-TICKS hasn't been called, we need to set FIRST-HEARD to 0. Unfortunately,
  ;; the only way to know if RESET-TICKS hasn't been called yet is to try to get the TICKS
  ;; and catch the ensuing error. On normal ticks, we use TICKS + 1 because that's going
  ;; to be the tick on which this node will be included in statistics:
  if first-adopted < 0 [
    carefully [
      set first-adopted ticks + 1
    ] [
      set first-adopted 0
      ;@never runs? initial nodes are 1, not 0...
    ]
  ]
  ;first-adopted = the tick at which they (most recently, if they've dropped and re-adopted) adopted the innovation

  recolor
end

to-report time-since-adopted ;node-reporter
report ticks - first-adopted
end



to setup-nodes ;node procedure. Run in setup (can also use it later if new nodes join)
  set adopted? false set adopted-this-turn? false
  set first-adopted -1 ;to avoid tick issues, see explanation in rumor mill model


  recolor
end


to set-link-shape
  if network-structure = "small world (100)" or network-structure = "small world (196)" [
      set shape "curve"
  ]
end



to recolor ;node procedure, run in go
  ifelse adopted?
    [set color green]
    [set color white]


  ;can add other color/label variables here
  ;label-when-adopted
end

to color-when-adopted ;node procedure
  ifelse adopted? [
    let nice-upper-value (max [first-adopted] of nodes) + 1 ;makes sure range1 for scale-color is always a nice value, no matter the network
    set color scale-color yellow first-adopted nice-upper-value 0
  ]
  [
    set color white
  ]

  ;the tick at which they (most recently) adopted the innovation
  ;@consider: what about dropout? do we instead wanna visualise when they first got it?
end

to size-by [measure] ;node procedure
  ;simple linear transformation
  ;NewValue = (((OldValue - OldMin) * (NewMax - NewMin)) / (OldMax - OldMin)) + NewMin
  ;moves their nr for the nw measure to a corresponding scale of the wanted sizes (determined by layout/space)

  ;depending on the nw structure, set lower and upper size limit:
  let NewMin 0.8 ;lower size limit
  let NewMax 2.9 ;upper size limit
  let OldMin "NA" ;just a placeholder
  let OldMax "NA"
  let OldValue "NA"

  if measure = "Betweenness" [
    set OldMin (min [betweenness] of nodes)
    set OldMax (max [betweenness] of nodes)
    set OldValue betweenness
  ]
  if measure = "Closeness" [
    set OldMin (min [closeness] of nodes)
    set OldMax (max [closeness] of nodes)
    set OldValue closeness
  ]
  if measure = "Degree" [
    set OldMin (min [degree] of nodes)
    set OldMax (max [degree] of nodes)
    set OldValue degree
  ]
  if measure = "Time since adopted" [
    set OldMin (min [time-since-adopted] of nodes)
    set OldMax (max [time-since-adopted] of nodes)
    set OldValue time-since-adopted
  ]


  ;actually make the node change size using the formula:
  set size (((OldValue - OldMin) * (NewMax - NewMin)) / (OldMax - OldMin)) + NewMin


end

to set-default-size ;node procedure
  ifelse network-structure = "small world (196)" [
      set size 1.1 ]
    [
      set size 1.8
      if network-structure = "preferential attachment (500)" [ set size 1 ]
    ]
end

to color-by [measure] ;button in interface, colors a network by a chosen measure
  ask banners [set label ""]

  if measure = "Time since adopted" [
    ask nodes [color-when-adopted label-when-adopted]
  ]

  if measure = "Betweenness" [
    let lower-value (min [betweenness] of nodes) - 0.1
    let upper-value (max [betweenness] of nodes) + 0.1
    ask nodes with [not adopted?] [set color scale-color blue betweenness upper-value lower-value] ;the darker the color, the higher the value
  ]

  if measure = "Closeness" [
    let lower-value (min [closeness] of nodes) - 0.02
    let upper-value (max [closeness] of nodes) + 0.02
    ask nodes with [not adopted?] [set color scale-color red closeness upper-value lower-value] ;the darker the color, the higher the value
  ]

  if measure = "Degree" [
    let lower-value (min [degree] of nodes) - 0.5
    let upper-value (max [degree] of nodes) + 0.5
    ask nodes with [not adopted?] [set color scale-color violet degree upper-value lower-value] ;the darker the color, the higher the value
  ]


end


to label-when-adopted ;node procedure
  if show-labels? [
    let the-label first-adopted

    hatch-banners 1 [
      set size 0 ;invisible


      ;LABEL POSITIONING:
      ;@customize this for each network, make sure it's readable!:
      set heading 120
      let forward-this-amount ifelse-value (length (word the-label) < 2) [0.6] [0.9] ;if one digit or two digits, forward different amounts - to make it centered!
      forward forward-this-amount
      set label the-label
      if [color] of self >= 44 [set label-color black] ;for readability - if node is light, label should be dark


    ]


    ;set label first-adopted
    ;if color > 44 [set label-color black] ;light nodes have dark label colors for readability
    display
  ]
end



to spread ;run in go

  if mechanism-for-spreading = "100 % chance of spreading" [
    ask adopters [
      ask link-neighbors with [not adopted?] [
        adopt
      ]
    ]
  ]

  if mechanism-for-spreading = "50 % chance of spreading" [
    ask adopters [
      ask link-neighbors with [not adopted?] [
        if random-float 100 < 50 [
          adopt
        ]
      ]
    ]
  ]

    if mechanism-for-spreading = "5 % chance of spreading" [
    ask adopters [
      ask link-neighbors with [not adopted?] [
        if random-float 100 < 5 [
          adopt
        ]
      ]
    ]
  ]

  if mechanism-for-spreading = "Conformity threshold" [
    ask nodes with [not adopted?] [
      if initial-round-percentage-contacts-adopted >= conformity-threshold [ ;lig med eller større
        adopt
      ]
    ]
  ]
end

to consider-drop-out ; adopter procedure, run by adopters in to-go (if drop-out? is on)
  ;initial-round-percentage-contacts-adopted is set in the previous 'ask nodes' step in go - so everybody sets that BEFORE doing this one by one (so as if everybody acts at once)

  if drop-out? [ ;gamle "Drop out if % neighbors lower than threshold"
        if initial-round-percentage-contacts-adopted < drop-out-threshold [
      set adopted? false
      set times-dropped ( times-dropped + 1 )
    ]
  ]

  ;DROPPET:
;  if drop-out-options = "percentage chance for dropping out" [ ;every round, my chance of dropping out is the percentage of non-adopters around me
;    if random-float 100 > initial-round-percentage-contacts-adopted [
;      set adopted? false
;      set times-dropped (times-dropped + 1 )
;    ]
;  ]
end

to-report drop-out? ;replaces the old interface switch
  report ifelse-value (drop-out-threshold = 0) [false] [true]
end

to clear-the-plot
  clear-all-plots
  set remaining-pen-colors nice-colors
  set pen-counter 0
end

to initiate-quantity-adopted-plot
  set-current-plot "Diffusion rate"
  set-plot-y-range 0 100
  setup-new-pen
end

to setup-new-pen ;used to start up a new plot pen
  set pen-counter pen-counter + 1
  set current-pen (word pen-counter ": " nw-name-short ", " count adopters " initial, " mechanism-short) ;pen name (nw-name-short and mechanism-short are reporters)
  create-temporary-plot-pen current-pen
  set-plot-pen-color first remaining-pen-colors ;@make sure it's non-repeating?
  set remaining-pen-colors but-first remaining-pen-colors ;removing the used color from the 'palette' so we have no repeats :)
  set-current-plot-pen current-pen
  set starting-tick ticks ;used for plotting and time-since-start, this is now '0'
  update-quantity-adopted-plot
end

to-report nw-name-short ;used for plot pen name
  let nw-list [ "lattice (100)" "lattice (196)" "small world (100)" "small world (196)" "preferential attachment (100)" "preferential attachment (196)" "preferential attachment (500)" ]
  let short-name-list [ "Lat (100)" "Lat (196)" "SW (100)" "SW (196)" "PA (100)" "PA (196)" "PA (500)"]
  let index position network-structure nw-list
  let short-name item index short-name-list
  report short-name
end

to-report mechanism-short ;used for plot pen name
  let mechanism-list [ "100 % chance of spreading" "50 % chance of spreading" "5 % chance of spreading" "Conformity threshold"]
  let last-name (word "Adopt if > " conformity-threshold " % around")
  let short-name-list (list "100% spread" "50% spread" "5% spread" (word "adopt if > " conformity-threshold " %"))
  let index position mechanism-for-spreading mechanism-list
  let short-name item index short-name-list
  report short-name
end

to update-quantity-adopted-plot
  set-current-plot "Diffusion rate"
  set-current-plot-pen current-pen ;pen name saved in this global variable
  set-plot-pen-mode 0
  plotxy time-since-start quantity-adopted
  display
end

to-report time-since-start ;used for plotting
  report ticks - starting-tick
end


to plant-innovation
  let mouse-is-down? mouse-down?
  if mouse-clicked? [

    ask min-one-of nodes  [distancexy mouse-xcor mouse-ycor] [
      set adopted? not adopted? ;flips the status
      recolor

    ]
    ;@evt SØRG FOR AT MAN SKAL VÆRE PÅ NODEN, når man trykker
  ]

; Other procedures that should be run on mouse-click

set mouse-was-down? mouse-is-down?
end

to plant-based-on
  let candidates nodes with [not adopted?]

  if based-on-this = "Betweenness centrality" [
    ask max-one-of candidates [betweenness] [ adopt ]
  ]

  if based-on-this = "Closeness centrality" [
    ask max-one-of candidates [closeness] [ adopt ]
  ]

  if based-on-this = "Degree centrality" [
    ask max-one-of candidates [degree] [ adopt ]
  ]


end

;---REPORTERS
to-report quantity-adopted
  report (count adopters) / (count nodes) * 100
end

to-report adopters ;just makes code more readable, instead of writing 'nodes with [adopted?]' every time
  report nodes with [adopted?]
end

to-report contacts-adopted ;node reporter
  report ( count in-link-neighbors with [adopted?] )
end

to-report percentage-contacts-adopted ;node reporter
  report ( contacts-adopted / ( count in-link-neighbors ) * 100  )
end

to-report mouse-clicked? ;used for plant-innovation
  report (mouse-was-down? = true and not mouse-down?)
end

to-report betweenness ;node reporter
  report nw:betweenness-centrality ;@use precision a little bit? (e.g. lattice, why only node 50 and not the whole 4-node middle? meaningful differences?)
end

to-report closeness ;node reporter
  report nw:closeness-centrality
end

to-report degree ;node reporter
  report count my-links
end

;---IMPORT NETWORKS
to import-network-structure
  if network-structure = "preferential attachment (100)" [
    nw:load-graphml "pref-net100.graphml" ]
  if network-structure = "preferential attachment (196)" [
    nw:load-graphml "pref-net196.graphml" ]
  if network-structure = "small world (100)" [
    nw:load-graphml "smallworld100.graphml" ]
  if network-structure = "small world (196)" [
    nw:load-graphml "smallworld196.graphml" ]
  if network-structure = "lattice (100)" [
  nw:load-graphml "lattice100.graphml" ]
  if network-structure = "lattice (196)" [
  nw:load-graphml "lattice196.graphml" ]
  if network-structure = "preferential attachment (500)" [
    nw:load-graphml "500pref.graphml" ]

  ask turtles [
    set breed nodes ;important!
    set shape "circle-with-border"

    set-default-size

  ]

  ;layout it nicely:

;
;    if network-structure = "small world" [
;      set breed nodes
;      set shape "circle"
;      set size 1.3
;      move-outwards 15
;    ]
;
;  ]
end

to move-outwards [steps] ;node procedure, used in import-network-structure
  facexy 0 0
  left 180
  forward steps

end
@#$#@#$#@
GRAPHICS-WINDOW
315
10
913
609
-1
-1
9.67213115
1
12
1
1
1
0
0
0
1
-30
30
-30
30
0
0
1
ticks
30.0

BUTTON
925
40
1010
85
go once
go
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
1014
40
1099
85
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

CHOOSER
15
355
302
400
mechanism-for-spreading
mechanism-for-spreading
"100 % chance of spreading" "50 % chance of spreading" "5 % chance of spreading" "Conformity threshold"
3

CHOOSER
10
35
295
80
network-structure
network-structure
"lattice (100)" "lattice (196)" "small world (100)" "small world (196)" "preferential attachment (100)" "preferential attachment (196)" "preferential attachment (500)"
2

PLOT
920
280
1485
600
Diffusion rate
time
% adopters
0.0
10.0
0.0
100.0
true
true
"" ""
PENS

CHOOSER
1230
50
1485
95
task
task
"Task 1a" "Task 1b (Small world 100)" "Task 1b (Small world 196)"
0

SLIDER
15
445
300
478
conformity-threshold
conformity-threshold
1
100
33.0
1
1
%
HORIZONTAL

SLIDER
15
565
300
598
drop-out-threshold
drop-out-threshold
0
100
0.0
1
1
%
HORIZONTAL

BUTTON
15
185
302
218
(PRESS THIS BUTTON AND CLICK ON A NODE)
plant-innovation
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
1070
175
1160
208
Reset
ask nodes [recolor set-default-size]\nask banners [die]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
925
100
1185
125
5. Visualize
17
0.0
1

TEXTBOX
125
500
275
521
Drop-out
17
0.0
1

TEXTBOX
85
330
285
351
Spreading mechanism
17
0.0
1

TEXTBOX
10
10
295
51
1. Choose network structure
17
0.0
1

BUTTON
1360
240
1485
280
CLEAR PLOT
clear-the-plot
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
10
80
295
113
Setup network
setup-network
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
15
160
225
178
2. Plant one or more ideas
17
0.0
1

TEXTBOX
15
295
205
316
3. Choose settings
17
0.0
1

TEXTBOX
925
15
1115
56
4. Go/Start the spread!
17
0.0
1

BUTTON
195
225
300
270
NIL
plant-based-on
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
15
225
192
270
based-on-this
based-on-this
"Betweenness centrality" "Closeness centrality" "Degree centrality"
1

BUTTON
1070
125
1160
170
VISUALIZE
color-by visualize-this\nask nodes [size-by visualize-this]
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
925
125
1065
170
visualize-this
visualize-this
"Time since adopted" "Betweenness" "Closeness" "Degree"
1

TEXTBOX
1220
160
1445
216
add layout animation:\n\nrepeat 4000 [layout-spring turtles links .01 3 1]
11
0.0
1

BUTTON
1230
100
1485
133
NIL
setup-task
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1260
20
1445
45
----- SETUP A TASK -----
17
0.0
1

BUTTON
10
115
295
148
Change layout visualization
change-nw-layout
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
15
530
305
565
At least this % of my neighbors must have adopted, or I drop out:
12
0.0
1

TEXTBOX
20
410
300
440
If conformity threshold: I adopt if at least this % of my neighbors have also adopted:
12
0.0
1

TEXTBOX
925
175
1060
235
Darker color and bigger size indicates a higher score on the chosen measure.
12
0.0
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

circle-with-border
false
0
Circle -7500403 true true 0 0 300
Circle -1 false false 0 0 300
Circle -1 false false 0 0 300

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

curve
3.0
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
