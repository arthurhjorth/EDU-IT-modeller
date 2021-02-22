;; different entities in the model
breed [households household]
breed [people person]
breed [workplaces workplace]
breed [schools school]
breed [bars bar]

globals [ ;; global variables
  time
  str-time
  total-deaths
  placeholder
]

people-own [ ;; human attributes
  age ;depends on age-distribution
  ;mental-health ;If we have time - kan evt have indflydelse på kreativity og hvorvidt man får sine social needs opfyldthttps://www.youidraw.com/apps/painter/
  ;social-needs ;- how much people need to socialize (bars + priv) -gust. It depends on social-needs-distribution
  ;my-social-houses ;not ready yet - Each household has a group of people (which can change over time). if a household solely consists of young then higher chance of gathering + more volume. #my-party-house depends -gust
  my-household
  my-workplace
  my-bar
  infected-at
  time-of-death ;;so every turtle only checks if they die ONCE every day (kinda sinister... @IBH: better solution?)
]
;; household attributes
households-own [

  household-infected-%

  members
]

;; workplace attributes
workplaces-own [
  employees
]

;; school attributes
schools-own [
  students
]

;;bar attributes
bars-own [
  bargoers
]

to setup
  clear-all
  reset-ticks ; restart clock
  create-schools  5 [
    set color gray
    set shape "house colonial"
    move-to max-one-of (patches with [not any? turtles-here]) [pxcor + pycor]
    set students (turtle-set)
  ]
  create-workplaces 10 [
    set color gray
    set shape "factory"
    move-to max-one-of (patches with [not any? turtles-here]) [pxcor - pycor * 2]
    set employees (turtle-set)
  ]
  create-bars 10 [
    set color gray
    set shape "house ranch" ;;IBH: not sure what's the best shape for these... :P
    let bar-patches patches with [abs pycor < 6]
    move-to max-one-of (bar-patches with [not any? turtles-here]) [pxcor]
    set bargoers (turtle-set)
  ]


  create-households 700 [
    set color gray
    move-to min-one-of (patches with [not any? households-here]) [pxcor]
    set shape "house"

    ;;IBH: landsdækkende statistik om husstandsstørrelse fra http://apps.aalborgkommune.dk/images/teknisk/PLANBYG/BOLIGUNDERSOEGELSE/Del2.pdf (side 13)
    ;;1 = 39%, 2 = 33%, 3 = 12%, 4 = 11%, 5 = 4%, 6 (eller derover) = 1%
    let probability random-float 1
    if probability < 0.39                         [set placeholder 1]
    if probability >= 0.39 and probability < 0.72 [set placeholder 2]
    if probability >= 0.72 and probability < 0.84 [set placeholder 3]
    if probability >= 0.84 and probability < 0.95 [set placeholder 4]
    if probability >= 0.95 and probability < 0.99 [set placeholder 5]
    if probability >= 0.99                        [set placeholder 6]

    let household-members placeholder ; Jeg forstår ikke ovenstående og heller ej denne linje -gus

    set members (turtle-set)
    hatch-people household-members [
      set shape "person"
      hide-turtle

      ;;@IBH: fix alderssammensætningen: den er stadig ret tilfældig/forsimplet og ikke baseret på statistik...
      ;;eg. a household of 5 is very likely to consist of 4 adults and a child...
      ;;(skriv: ask households [show [age-group] of members] i command center efter setup for at få et indblik i sammensætningen...)

      ;;make sure the first person created is always an adult or elder:
      ifelse not any? other people-here
        [while [age-group = "child"] [set age age-distribution]]
        [set age age-distribution]


      ;set social-needs social-needs-distribution -gus
      set infected-at -1000
      set time-of-death random 24
      set my-household myself ;I dont really understand "myself" -gus (intentional joke in this question xD)
      ask my-household [set members (turtle-set members myself)]
      if age < 20 [
        set my-workplace one-of schools
        ask my-workplace [set students (turtle-set students myself)]
      ]
      if age >= 18 [
        set my-bar one-of bars ;;@IBH: nu har alle én stambar - mere realistisk, hvis de besøger flere forskellige?
        ask my-bar [set bargoers (turtle-set bargoers myself)]
      ]

      if age >= 20 [
        set my-workplace one-of workplaces
        ask my-workplace [set employees (turtle-set employees myself)]


        ]
      ]
    ]


  ask n-of  (initial-infection-rate / 100 * count people) people [set infected-at -1 * random average-duration * 24]

  ask turtles [recolor]


  set time ticks mod 24 ;;every tick is one hour
  ask patches [set pcolor patch-color] ;;change colors depending on the time of day (see patch-color reporter)
  set str-time (word time ":00")
  if time < 10 [set str-time (word "0" str-time)]
end


to go
  every .01 [
    ;; update time
    set time ticks mod 24
    ask patches [set pcolor patch-color] ;;change colors depending on the time of day (see patch-color reporter)
    ;;color-world ;;change colors depending on the time of day
    set str-time (word time ":00")
    if time < 10 [set str-time (word "0" str-time)]

    ;;; move people to jobs and schools
    if time = 8 [
      if not close-workplaces? [ask workers [move-to my-workplace]]
      if not close-schools? [ask all-students [move-to my-workplace]]
    ]


;;;socializing
;    if day = 6 [ ;Der skal implementeres at det kun er i weekenden at det er privat fest + bar (torsdag ogs?). Måske noget alla if day = 6+7, 14+15 etc
;      ;;going to bars/stores:
;      ;;@IBH: nu går alle på bar kl 17 - kan evt sprede det ud/gøre det mere realistik
;      ifelse close-bars-and-stores?
;        [ ask people [move-to my-household] ] ;;if closed
;        ;;if open:
;        [ ask people [
;          ifelse age-group = "adult" ;
;            [let chance random-float 1 ;a number between 0 and 1
;            ifelse chance < 0.3 [ move-to my-bar ] [ move-to my-household ] ;;@:her kan vi ændre sandsynligheden for at gå på bar
;        ]
;            [move-to my-household] ;;if not adult
;      ]]
;
;    ]


    if time = 17 [
      ;;going to bars/stores:
      ;;@IBH: nu går alle på bar kl 17 - kan evt sprede det ud/gøre det mere realistik
      ifelse close-bars-and-stores?
        [ ask people [move-to my-household] ] ;;if closed
        ;;if open:
        [ ask people [
          ifelse age-group = "adult" ;&not at privat socialt arrangement? -gus
            [let chance random-float 1 ;a number between 0 and 1
            ifelse chance < 0.3 [ move-to my-bar ] [ move-to my-household ] ;;@:her kan vi ændre sandsynligheden for at gå på bar
        ]
            [move-to my-household] ;;if not adult
      ]]

    ]



    if time = 20 [ask people [move-to my-household] ] ;;@IBH: nu er folk kun på bar kl 17-20 - gør evt, så de kan have late night parties :)

    ;; ask people who are infected to potentially infect others
    ask people with [infected?] [
      ask other people-here with [random-float 1 < probability-of-infection and not immune?] [ set infected-at ticks]

      ;;risk of infected people dying:
      if time = time-of-death [ ;;so every person only checks if they die ONCE every day (if it was every hour, the risk would be inflated...)
        let my-destiny random-float 1
        if my-destiny < my-death-risk [
          set total-deaths total-deaths + 1
          die
        ]

      ]

    ]

    ask turtles [recolor]
    if not any? people with [infected?] [stop]
    tick
  ]
end

to recolor
  set color 19.9 - (infected-rate * 4.9)
end

to-report infected-rate
  if is-workplace? self [
    ifelse any? employees with [infected?] [
      report count employees with [infected?] / count employees
    ]
    [
      set color black
    ]
  ]
  if is-household? self [
    if any? members with [infected?] [
      report count members with [infected?] / count members
    ]
  ]
  if is-school? self [
    if any? students with [infected?] [
     report count students with [infected?] / count students
    ]
  ]
  if is-bar? self [
    if any? bargoers with [infected?] [
      report count bargoers with [infected?] / count bargoers
    ]
  ]
  report 0
end

to-report workers
  report people with [age > 20]
end

to-report all-students
  report people with [age <= 20]
end

to-report working-at-home? ;;person reporter
  ifelse time >= 8 and time <= 16 and age-group = "adult" and close-workplaces?  ;;AH: adult and workplaces closed, and between 8 and 16 oclock
    [report true]
    [report false]
end

to-report is-homeschooling? ;;@IBH: tager ikke hensyn til antal (eller alder) af børn og voksne i husstanden - kan evt. gøres lidt mere realistisk
  ifelse working-at-home? and any? people-here with [age-group = "child"]  ;;if adult + it's between 8 and 16 + there are kids in the house
    [report true]
    [report false]
end


;; a simple population distribution from Danmarks Statistik, generalizing 3 age groups, corresponding to non-adults, adults and elders

to-report age-distribution ; we need to implement the young age group here aswell but i don't really understand the code -gus
  (ifelse
    random-float 1 < 0.72 [ ;72% is the percentage of the population in Denmark above 17 and below 75 anno 2021 (DKs Statistik)
      ;set age 17 + random 57
      report 18 + random 58 ;;IBH: random returns a value between 0 and one less than the number - so I changed 17 to 18 :)
    ]
    random-float 1 > (1 - 0.2) [ ;20% below 18
      ;set age random 17
      report random 18
    ]
    ;elders above 74, 8%
    [
      ;set age 74 + random 26
      report 75 + random 27
    ])
end

to-report age-group ;;IBH: bruger de tre grupper fra DKs Statistik (ret forsimplet, men måske fint at holde det til tre): 0-17, 18-74, 75+
  if age <= 17 [ report "child" ] ;;initially 20 %
  ;if age > 17 and age < 28 [report "young" ] ;This allows us to have a group of young people more likely to party and bars
  ;if age >= 28 and age < 75 [report "adult" ] ;same (remove adult below)
  if age > 17 and age < 75 [ report "adult" ] ;;initially 72 %
  if age >= 75 [ report "elder" ] ;;initially 8 %
end


;to-report social-needs-distribution ; -gus
;  if age-group = "child" [ report 5 ]
;  if age-group = "young" [ report random 11 ]
;  ifelse age-group = "adult" [
;    let chance random-float 1
;    ifelse chance < 0.3 [ report random 11 ] [ report random 4 ]
;  ]
;  ifelse age-group = "elder" [
;    let chance random-float 1
;    ifelse chance < 0.1 [ report random 11 ] [ report random 3 ]
;  ]
;
;end


to-report infected?
  report ticks >= infected-at and ticks <=  infected-at + average-duration * 24
end

to-report days-infected
  ifelse infected?
    []
    [report 0]
end

to-report my-death-risk
;;@IBH: can change these probabilities (quite random right now), and maybe make more fine-grained!
  ;;@could add 'deathliness of virus' to the interface, and a chooser 'depends-on-age?'
  ;;DAILY probabilities of dying if infected:
  if age-group = "child" [report 0.002]
  if age-group = "adult" [report 0.02]
  if age-group = "elder" [report 0.2]
end

to-report immune? ;;@nu antager vi, at alle bliver immune
  report infected-at != -1000 and infected-at + average-duration * 24 < ticks
end

to-report day
  report floor (ticks / 24)
end

to-report productivity ;;for productivity plot (sum [productivity] of people)
  ifelse age-group = "adult" [
    ifelse working-at-home? [
      ifelse is-homeschooling? [
        report (home-productivity / 100) * (productivity-while-homeschooling / 100) ;;if working from home AND homeschooling
        ;;@IBH idé: skal vi gøre, så hvis skoler er lukkede, bliver folk med børn hjemme og arbejder + homeschooler, selv hvis arbejdspladser ikke er lukket?
      ]
      [ ;;if not homeschooling:
        report home-productivity / 100
      ]
    ]
    [ ;;if adult working in workplace:
      report 1
    ]
  ]
  [ ;;if age-group != adult:
    report 0 ;;nu antages det, at børn og ældre ikke bidrager til produktiviteten... ;) @IBH: maybe change this
  ]

  ;;@working-at-home? og is-homeschooling? beskriver nu, om de CURRENTLY gør det - derfor får productivity plot nu weird bumps uden for arbejdstiden. @IBH: fix det evt

  ;;@include expenses-per-infection somewhere in these calculations?
end


to-report patch-color ;;depends on the time of day
  ;;IBH: måske lidt overkill haha, men det ser nice nok ud
  ;;@OBS: får det jeres model til at køre langsommere? mine patches ser lidt 'splotchy' ud/opdaterer ikke synkront (måske et problem for NetLogo Web?)
  ;;de præcise farver kan evt. tweakes, feel free til at ændre det :)
  if time = 0 [ report 100]
  if time = 1 [ report 101]
  if time = 2 [ report 101.5]
  if time = 3 [ report 102]
  if time = 4 [ report 102.5]
  if time = 5 [ report 103]
  if time = 6 [ report 104.5]
  if time = 7 [ report 95]
  if time = 8 [ report 96]
  if time = 9 [ report 96.5]
  if time = 10 [ report 97]
  if time = 11 [ report 97.5]
  if time = 12 [ report 97]
  if time = 13 [ report 107.5]
  if time = 14 [ report 107]
  if time = 15 [ report 106.5]
  if time = 16 [ report 106]
  if time = 17 [ report 105.5]
  if time = 18 [ report 104]
  if time = 19 [ report 102.5]
  if time = 20 [ report 102]
  if time = 21 [ report 101.5]
  if time = 22 [ report 101]
  if time = 23 [ report 100.5]
end










@#$#@#$#@
GRAPHICS-WINDOW
240
55
768
584
-1
-1
15.76
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
50
60
112
93
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
115
60
180
93
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

SLIDER
15
15
230
48
initial-infection-rate
initial-infection-rate
0
100
13.5
.1
1
%
HORIZONTAL

SLIDER
5
430
230
463
home-productivity
home-productivity
0
200
64.0
1
1
% (of normal)
HORIZONTAL

MONITOR
470
10
579
55
Time of the Day
str-time
0
1
11

PLOT
775
10
1205
205
Infection rates
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"% infected" 1.0 0 -16777216 true "" "plot count people with [infected?] / count people"

PLOT
775
400
1205
595
Productivity
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [productivity] of people"

SWITCH
10
120
235
153
close-workplaces?
close-workplaces?
1
1
-1000

SWITCH
10
155
235
188
close-schools?
close-schools?
0
1
-1000

SLIDER
5
465
230
498
productivity-while-homeschooling
productivity-while-homeschooling
0
100
50.0
1
1
%
HORIZONTAL

SLIDER
5
500
230
533
expenses-per-infection
expenses-per-infection
0
100
58.0
1
1
NIL
HORIZONTAL

TEXTBOX
40
405
190
423
Economic Assumptions
15
0.0
1

TEXTBOX
70
100
170
118
Interventions
15
0.0
1

SLIDER
10
300
230
333
probability-of-infection
probability-of-infection
0
0.0025
3.3E-4
0.00001
1
/ hour
HORIZONTAL

TEXTBOX
25
280
185
300
Virological Assumptions
15
0.0
1

SLIDER
10
335
230
368
incubation-time
incubation-time
0
240
27.0
1
1
hours
HORIZONTAL

SLIDER
10
370
230
403
average-duration
average-duration
0
25
6.0
1
1
days
HORIZONTAL

SWITCH
10
190
235
223
close-bars-and-stores?
close-bars-and-stores?
1
1
-1000

MONITOR
415
10
472
55
Day
Day
17
1
11

PLOT
775
205
1205
400
SIR Plots
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"S" 1.0 0 -13345367 true "" "plot count people with [not immune? and not infected?]"
"I" 1.0 0 -2674135 true "" "plot count people with [infected?]"
"R" 1.0 0 -8630108 true "" "plot count people with [immune?]"

MONITOR
1390
300
1465
345
NIL
total-deaths
17
1
11

MONITOR
1390
255
1465
300
NIL
count people
17
1
11

PLOT
1210
40
1495
190
Age distribution over time
Time
Count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Children" 1.0 0 -14439633 true "" "plot count people with [age-group = \"child\"]"
"Adults" 1.0 0 -13345367 true "" "plot count people with [age-group = \"adult\"]"
"Elders" 1.0 0 -2674135 true "" "plot count people with [age-group = \"elder\"]"

SWITCH
10
230
202
263
max-5people-restriction?
max-5people-restriction?
1
1
-1000

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

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

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

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

house ranch
false
0
Rectangle -7500403 true true 270 120 285 255
Rectangle -7500403 true true 15 180 270 255
Polygon -7500403 true true 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180

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
