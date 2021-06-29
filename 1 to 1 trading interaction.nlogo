globals [
  price ;
  deal-tableware
  deal-money
  deal
  succesful-trades
  price-list

]


breed [merchants merchant]
breed [consumers consumer]

merchants-own [
  alpha
  beta
  money
  tableware
  mrs
  offer-money
  offer-tableware
  offer
  utility
  initial-utility
  partner
  temp-tableware
  temp-money
  temp-utility

 ]

consumers-own [
  alpha
  beta
  money
  tableware
  mrs
  offer-money
  offer-tableware
  offer
  utility
  initial-utility
  partner
  temp-tableware
  temp-money
  temp-utility

]


to setup
  clear-all
  reset-ticks

  layout
  populate
  update-mrs
  set-partner
  calculate-utility
  set-initial-utility
  create-price-list
end


to go

  trade

  produce-tableware
  break-tableware
  earn-money
  update-price-list
  update-mrs

  tick

  if ticks = stop-after-x-tick [
    stop
  ]

  ;only consumers earning money - how it affects the dynamics. People will likely be more likely to pay more for a plate
  ;Tableware production --> price will fall if the relation between tableare prod and money prod
  ;Add dynamics - earns money, destroys plates,

  ;

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;; FUNCTIONS ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to populate ;;run in setup. Create starting population
  repeat (nr-ppls / 2) [ make-ppls "merchants"]
  repeat (nr-ppls / 2) [ make-ppls "consumers"]

end


to make-ppls [kind]

  if kind = "merchants" [
   create-merchants 1 [
   set alpha alpha-merchants
   set beta precision ( 1 - alpha-merchants ) 3
   set money money-merchants
   set tableware tableware-merchants
   set mrs 0

   ;looks
   set shape "tableware"
   set size 7
   set color blue
   setxy -10 -10
   set heading 90


  ]
  ]

  if kind = "consumers" [
   create-consumers 1 [
   set alpha alpha-consumers
   set beta precision ( 1 - alpha-consumers ) 3
   set money money-consumers
   set tableware tableware-consumers
   set mrs 0

         ;looks
      set shape "person"
      set size 7
      set color white
      setxy 10 -10
      set heading 360 - 90

  ]
  ]
end

to layout
;  create-turtles 1
;  ask turtles
;  [set shape "building institution" ;make it acropolis
;    set size 13
;    setxy 0 10
;    set color white]



  ask patches [set pcolor blue]
  ask patches with [pycor < 13] [set pcolor blue + 1]
  ask patches with [pycor < 9] [set pcolor blue + 2]


  ask patches with [pxcor > -8 and pxcor < 8 and pycor > -14 and pycor < 0]
  [set pcolor blue]

  ask patch 5 -10
  [set plabel "Trade mechanics can be"]
  ask patch 5 -11
  [set plabel "shown here"]

end

to update-mrs
ask merchants [
    let nr ( alpha-merchants * money )  / ( beta * tableware )
    let rounded precision nr 3
    set mrs rounded

]


ask consumers [
    let nr ( alpha-consumers * money )  / ( beta * tableware )
    let rounded precision nr 3
    set mrs rounded

]

;Cudos to   chap5 edgeworth box game.
  ;   set mrsCapt ( alphaCapt * captsCigs )  / ( ( 1 - alphaCapt ) * captsChocs )
  ;   set mrsSgt  ( alphaSgt * sgtsCigs  )  / ( ( 1 - alphaSgt ) *  sgtsChocs )

end


to set-partner
  ask consumers [
   set partner one-of merchants
  ]

  ask consumers [
   ask partner [
      set partner myself
    ]
  ]

end


to trade
  calculate-utility ;currently only used for choosing quantity

;;;;;;;;;-------------;;;;;;;;; Choosing price:

if price-setting = "choose price" [
    ask turtles [
     set price choose-price
    ]
  ]


;;;;;;;;;;;;;;;;;;;;;;;; Equilibrium
  ; equilibrium sets the price as the  mean between the two (the underlying assumption is that negotiating will even prices out over time - and that both are equally good at negotiating)
;based on equilibrum from red cross parcel

    if price-setting = "equilibrium" [
    ask consumers [
      set price  precision (
                           ( ( alpha * tableware ) + [ alpha * tableware ] of partner )  /
                           ( ( beta * money ) + [ beta  * money ] of partner ) )    2 ]    ;mangler beta
 ]






  if price-setting = "random"
  [
   let minMRS min [ mrs ] of turtles
   let maxMRS max [ mrs ] of turtles
    set price  minMRS + ( random ( 100 * ( maxMRS - minMRS ) ) / 100 ) ; because random produces integers


  output-print ( word "blabla " minMRS )
  ]


;;;;;;;;;----------;;;;;;;;;; Price end




;;;;;;;;;;-------------;;;;;;;;;; Quantity of trade
  ;;;@@lisa: round number of tableware for whole numbers only - not necessary for $$$$ (maybe down to two decimals tho)

if quantity-options = "standard" [

  ask consumers [
    let budget (tableware * price ) + money ;calculating budget based on tableware owned and price-setting and current holding of money
    let optimal round (budget * alpha / price) ;optimal number of tableware to HOLD given the current price
    set offer precision ( optimal - tableware ) 2 ;offer to buy the number of tableware optimal with current holding subtracted
  ]


  ask merchants [
    let budget ( tableware * price ) + money ;@@ check up on why we choose quantity according to this
    let optimal ( budget * alpha / price )
    set offer precision ( tableware - optimal ) 2  ;@@ why is this the other way around compared to consumers????? because merchants don't want tableware! e.g. got 50, optimal is 30. 50-30=20. sell 20!

    ; let nr-tableware-consumer-wants ( optimal - tableware ) ; how much tableware the consumer wants ideally
    ;set offer-money min list ( nr-tableware-consumer-wants * price ) ( money - 1 )
    ;set offer-tableware ( offer-money / price )

  ]

  ]
    ;let nr-tableware-supply ( tableware - optimal )
    ;set offer-tableware min list ( nr-tableware-supply * price ) ( tableware - 1 )
    ;set offer-money 0

;Making sure only whole numbers are traded.
  ; ((((solution from edgeworth does not give us whole numbers in tableware after trades


if quantity-options = "standard" [
  ask turtles with [ offer > 0 ] [
  set offer floor ( offer ) ;only whole number of tableware is traded
  ;let offerUnits floor ( offer * price ) ;why multiply just to divide again?
  ;set offer offerUnits / price
  ]



;removing offers below 0
ask turtles with [ offer < 0 ]
  [
    set offer 0
  ]

;simple way of choosing which quantity
set deal min list ( [ offer ] of turtle 0 ) ( [ offer ] of turtle 1 ) ;the number to trade is decided by the agent who wants to trade the fewest
  ] ; quantity options standard end


if quantity-options = "one tableware at a time" [
  ask turtles [
     set deal 1
    ]
  ]

;variables used for all quantity options
set deal-tableware deal
set deal-money deal * price ;total price of purchase (for the quantity decided upon)

  ;;;;;;;;;;;;;--------------;;;;;;;;;;;; choosing quantity end



;;;;;;;;;;;;;;;;---------;;;;;;;;;;;; check if we increase utility, and engage in trade if yes. Otherwise nothing happens.
  ;(set deal 0 is to allow us to prompt "trade cancelled" or so)

ask consumers [
   if deal > 0 [
     set temp-tableware ( tableware + deal-tableware )
     set temp-money ( money - deal-money )
     set temp-utility precision ( ( temp-tableware ^ alpha ) * ( temp-money ^ beta ) ) 2 ;cobb-douglas utility function
    ]
  ]

ask merchants [
   if deal > 0 [
     set temp-tableware ( tableware - deal-tableware )
     set temp-money ( money + deal-money )
     set temp-utility precision ( ( temp-tableware ^ alpha ) * ( temp-money ^ beta ) ) 2 ;cobb-douglas utility function
    ]
  ]

;if temp-utility is smaller than utility then we set deal = 0. otherwise trade is accepted.
;This also means that all price offers which does not allow a higher utility for both traders end up in a cancelled trade
ask consumers [
    if temp-utility < utility [
     set deal 0
    ]
  ]

ask merchants [
     if temp-utility < utility [
       set deal 0

      ]
    ]

if deal > 0 [
     ask consumers [
       set tableware temp-tableware
       set money temp-money
       set succesful-trades succesful-trades + 1
      ]

     ask merchants [
       set tableware temp-tableware
       set money temp-money
       set succesful-trades succesful-trades + 1
      ]
    ]


end


to create-price-list
  set price-list []
end


to update-price-list
  set price-list fput price price-list
end


to produce-tableware
  if tableware-production? [
    ask merchants [
    set tableware (tableware + tableware-produced-per-tick)
  ]
  ]
end

to break-tableware
  if tableware-breakage? [
    ask consumers [
    set tableware ( tableware - tableware-broken-per-tick-consumers )
  ]
  ]

end

to earn-money
if consumers-earn-money? [
    ask consumers [
    set money (money + salary-daily )
    ]
    ]
end



to calculate-utility

  ; Cobb-Douglas utility function ;;;copied from red cross parcels model
  ;As i understand the utility hereby is a measure of the total quantity of tableware and money, modified by the alpha and betas. Meaning that the weight of money+tableware is modified by the alphas + betas.
  ;in short, an individual utility function dependant on alphas and betas.

 ask merchants  [
    set utility  precision ( ( tableware ^ alpha ) * ( money ^ beta ) ) 2
  ]


 ask consumers [
    set utility  precision ( ( tableware ^ alpha ) * ( money ^ beta ) ) 2
  ]
end

to set-initial-utility
  ask merchants [
   set initial-utility utility
  ]

   ask consumers [
   set initial-utility utility
  ]
end




to-report nr-succesful-trades
  report ( succesful-trades / 2 )
end

to-report nr-tableware-merchants
  report item 0 [ tableware ] of merchants
end

to-report nr-money-merchants
  report precision ( item 0 [ money ] of merchants ) 2 ;simply rounding to 2 decimals
end

to-report nr-tableware-consumers
  report item 0 [ tableware ] of consumers
end


to-report nr-money-consumers
  report precision ( item 0 [ money ] of consumers ) 2
end

to-report utility-merchants
  report [ utility ] of merchants
end

to-report utility-consumers
  report [ utility ] of consumers
end

to-report report-offer-consumers
  ;report [ offer ] of consumers
  report item 0 [offer] of consumers ;this way we get the item on the list, not the list itself. still a question: why is it a list in the first place?
end

to-report report-offer-merchants
  report item 0 [ offer ] of merchants
end

to-report report-price
  report price
end

to-report report-mrs-merchants
  report item 0 [ mrs ] of merchants
end

to-report report-mrs-consumers
  report item 0 [ mrs ] of consumers
end

to-report report-beta-merchants
  report item 0 [ beta ] of merchants
end

to-report report-beta-consumers
  report item 0 [ beta ] of consumers
end


to-report mean-price
  if length price-list > 0 [
report ( ( sum price-list ) / ( length price-list ) )
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
462
10
899
448
-1
-1
13.0
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

INPUTBOX
3
50
158
110
nr-ppls
2.0
1
0
Number

INPUTBOX
183
217
284
277
money-merchants
50.0
1
0
Number

INPUTBOX
322
214
424
274
money-consumers
50.0
1
0
Number

INPUTBOX
183
281
285
341
tableware-merchants
50.0
1
0
Number

INPUTBOX
323
277
426
337
tableware-consumers
50.0
1
0
Number

BUTTON
6
10
69
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
72
10
135
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

INPUTBOX
293
10
448
70
stop-after-x-tick
40.0
1
0
Number

SLIDER
181
130
309
163
alpha-merchants
alpha-merchants
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
324
127
451
160
alpha-consumers
alpha-consumers
0
0.9
0.9
0.1
1
NIL
HORIZONTAL

TEXTBOX
187
99
315
127
Variables for the merchant breed
11
0.0
1

TEXTBOX
326
93
449
121
Variables for the consumer breed\n
11
0.0
1

MONITOR
1087
10
1166
55
NIL
report-price
17
1
11

MONITOR
1092
100
1248
145
NIL
report-mrs-merchants
17
1
11

MONITOR
911
98
1064
143
NIL
report-mrs-consumers
17
1
11

CHOOSER
8
116
156
161
price-setting
price-setting
"market-clearing" "equilibrium" "random" "choose price"
2

MONITOR
183
167
312
212
Beta for merchants
report-beta-merchants
17
1
11

MONITOR
324
164
450
209
Beta for consumers
report-beta-consumers
17
1
11

MONITOR
1101
190
1243
235
NIL
report-offer-merchants
17
1
11

MONITOR
909
188
1052
233
NIL
report-offer-consumers
17
1
11

SLIDER
2
163
155
196
choose-price
choose-price
1
30
1.0
0.01
1
NIL
HORIZONTAL

MONITOR
1094
268
1241
313
NIL
nr-tableware-merchants
17
1
11

MONITOR
1093
312
1242
357
NIL
nr-money-merchants
17
1
11

MONITOR
909
269
1057
314
NIL
nr-tableware-consumers
17
1
11

MONITOR
909
317
1058
362
nr-money-consumers
nr-money-consumers
17
1
11

MONITOR
737
452
862
497
NIL
nr-succesful-trades
17
1
11

SWITCH
40
422
152
455
dynamics?
dynamics?
0
1
-1000

SWITCH
6
465
198
498
consumers-earn-money?
consumers-earn-money?
1
1
-1000

SWITCH
4
501
184
534
tableware-production?
tableware-production?
1
1
-1000

SWITCH
4
540
189
573
tableware-breakage?
tableware-breakage?
1
1
-1000

MONITOR
1242
266
1345
311
total tableware
nr-tableware-consumers + nr-tableware-merchants
17
1
11

SLIDER
188
502
423
535
tableware-produced-per-tick
tableware-produced-per-tick
0
20
6.0
1
1
NIL
HORIZONTAL

SLIDER
201
464
373
497
salary-daily
salary-daily
0
20
10.0
1
1
NIL
HORIZONTAL

MONITOR
1243
311
1332
356
total money
nr-money-merchants + nr-money-consumers
17
1
11

TEXTBOX
1023
246
1173
264
Current holdings
11
0.0
1

TEXTBOX
964
170
1184
198
Most recent offer (quantity to buy/ sell)
11
0.0
1

TEXTBOX
960
80
1196
108
Current marginal rate of substitution (MRS)
11
0.0
1

TEXTBOX
909
10
1073
38
Most recent price of tableware
11
0.0
1

PLOT
946
410
1146
560
price/tableware
Ticks/ time
price per item
0.0
10.0
0.0
3.0
true
false
"" ""
PENS
"default" 1.0 0 -9276814 true "" "plot price"
"pen-1" 1.0 0 -5298144 true "" "plot mean-price"

SLIDER
195
540
464
573
tableware-broken-per-tick-consumers
tableware-broken-per-tick-consumers
0
20
3.0
1
1
NIL
HORIZONTAL

CHOOSER
4
367
184
412
quantity-options
quantity-options
"standard" "one tableware at a time"
1

MONITOR
1179
492
1329
537
mean price/ tableware
mean-price
17
1
11

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

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

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

tableware
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 171 109 231 64 261 79 186 139
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Circle -1 true false 205 14 76
Circle -11221820 false false 215 23 56

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
0
@#$#@#$#@
