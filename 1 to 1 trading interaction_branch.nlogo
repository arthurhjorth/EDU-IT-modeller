globals [
  price
  market-price
  equilibrium-price
  random-price
  price-temporary
  deal-tableware
  deal-money
  deal
  succesful-trades
  price-list
  market-price-list
  equilibrium-price-list
  random-price-list

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
  create-price-lists
end


to go

  trade2

  produce-tableware
  break-tableware
  earn-money
  update-price-list
  update-mrs

  tick

  if ticks = stop-after-x-tick [
    stop
  ]
wait running-speed ;just to make the output better readable

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


 if price-setting = "market-clearing"
  [
  repeat (1) [ make-market-ppls "merchants"]
  repeat (1) [ make-market-ppls "consumers"]
  ]


  if price-setting = "equilibrium"
  [
  repeat (1) [ make-equilibrium-ppls "merchants"]
  repeat (1) [ make-equilibrium-ppls "consumers"]
  ]


  if price-setting = "random"
  [
  repeat (1) [ make-random-ppls "merchants"]
  repeat (1) [ make-random-ppls "consumers"]
  ]


  if compare-all-price-settings?
  [
  repeat (1) [ make-market-ppls "merchants"]
  repeat (1) [ make-market-ppls "consumers"]
   repeat (1) [ make-equilibrium-ppls "merchants"]
  repeat (1) [ make-equilibrium-ppls "consumers"]
   repeat (1) [ make-random-ppls "merchants"]
  repeat (1) [ make-random-ppls "consumers"]
  ]



ask turtles
  [set size 5]

  ask merchants
  [set shape "tableware"
  set heading 90]

  ask consumers
  [set shape "person"
  set heading 270]

end


to make-market-ppls [kind]
  if kind = "merchants" [
   create-merchants 1 [
   set alpha alpha-merchants
   set beta precision ( 1 - alpha-merchants ) 3
   set money money-merchants
   set tableware tableware-merchants
   set mrs 0
   set color green + 2
   setxy -10 8.5

  ]
  ]

  if kind = "consumers" [
   create-consumers 1 [
   set alpha alpha-consumers
   set beta precision ( 1 - alpha-consumers ) 3
   set money money-consumers
   set tableware tableware-consumers
   set mrs 0
      set color yellow + 2
      setxy 10 8.5

  ]
  ]

end

to make-equilibrium-ppls [kind]

   if kind = "merchants" [
   create-merchants 1 [
   set alpha alpha-merchants
   set beta precision ( 1 - alpha-merchants ) 3
   set money money-merchants
   set tableware tableware-merchants
   set mrs 0
   set color green + 0.7
   setxy -10 -2.5

  ]
  ]

  if kind = "consumers" [
   create-consumers 1 [
   set alpha alpha-consumers
   set beta precision ( 1 - alpha-consumers ) 3
   set money money-consumers
   set tableware tableware-consumers
   set mrs 0
      set color yellow + 0.7
      setxy 10 -2.5

  ]
  ]
end

to make-random-ppls [kind]
  if kind = "merchants" [
   create-merchants 1 [
   set alpha alpha-merchants
   set beta precision ( 1 - alpha-merchants ) 3
   set money money-merchants
   set tableware tableware-merchants
   set mrs 0
   set color green - 0.3
   setxy -10 -12.5

  ]
  ]

  if kind = "consumers" [
   create-consumers 1 [
   set alpha alpha-consumers
   set beta precision ( 1 - alpha-consumers ) 3
   set money money-consumers
   set tableware tableware-consumers
   set mrs 0
      set color yellow - 0.6
      setxy 10 -12.5
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



 ; ask patches [set pcolor blue]
 ; ask patches with [pycor < 13] [set pcolor blue + 1]
 ; ask patches with [pycor < 9] [set pcolor blue + 2]


;  ask patches with [pxcor > -8 and pxcor < 8 and pycor > -14 and pycor < 0]
;  [set pcolor blue]
ask patch 3 5
[set plabel "Market clearing"]


ask patch 2 -6
[set plabel "Equilibrium"]


  ask patch 1 -16
[set plabel "Random"]

  ask patches [set pcolor blue ]
  ask patches with [pycor > 4 ] [set pcolor blue + 1]
  ask patches with [pycor = 5 ] [set pcolor blue + 0.5]
  ask patches with [pycor < -6 ] [set pcolor blue - 1 ]
  ask patches with [pycor = -6] [set pcolor blue - 1.5 ]
  ask patches with [pycor = -16] [set pcolor blue - 2.5 ]




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

to calculate-market-clearing-price

set price-temporary 0.1

repeat 200 [


  ]

end




to trade ;not currently in use
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
                           ( ( beta * money ) + [ beta  * money ] of partner ) )    2 ]



   output-print (word "Consumer optimal price"  ". "
      word "Merchant optimal price"  ". "
      word "Average price-point of the two" price ". " )
    ]



  if price-setting = "random"
  [
   let minMRS min [ mrs ] of turtles
   let maxMRS max [ mrs ] of turtles
    set price  minMRS + ( random ( 100 * ( maxMRS - minMRS ) ) / 100 ) ; because random produces integers


     output-print ( word "Consumer MRS " maxMRS ". "
    word "Merchant MRS " minMRS ". "
    word "Random price in between: " precision price 2)
  ]



;;;;;;;;;----------;;;;;;;;;; Price end




;;;;;;;;;;-------------;;;;;;;;;; Quantity of trade

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



;;; alternative trading system in two steps. 1) price-setting according to condition, and 2) setting quantity.
; price-setting in seperate functions for the purpose of the all-in-one condition

to trade2
if price-setting = "equilibrium" [
    set-equilibrium-price
    decide-quantity
    trade-and-update-holdings   ; ----  done separately from decide-function!
  ]


  if price-setting = "random" [
    set-random-price
    decide-quantity
    trade-and-update-holdings
  ]

if price-setting = "choose price" [
  decide-quantity
    trade-and-update-holdings
  ]


  ;@@lisa: differing by price-setting is not so great for an all-in-one model. Needed: distinguish between the different agents.
  ;; idea: price-setting included in agent-setup? or unique IDs for the turtles. or refering within their spaces.

  if compare-all-price-settings? [
    set-equilibrium-price
    set-random-price
    decide-quantity
  ] ;@@lisa: missing in quantity. probably needs to run 2 setups simultaneously

end



to set-equilibrium-price

    ask consumers [
      set equilibrium-price  precision (
                           ( ( alpha * tableware ) + [ alpha * tableware ] of partner )  /
                           ( ( beta * money ) + [ beta  * money ] of partner ) )    2 ]
;evt output-print her

;updating price-list
Set equilibrium-price-list fput equilibrium-price equilibrium-price-list

end



To set-random-price

   let minMRS min [ mrs ] of turtles
   let maxMRS max [ mrs ] of turtles
    set random-price  minMRS + ( random ( 100 * ( maxMRS - minMRS ) ) / 100 ) ; because random produces integers
;+text-output?

Set random-price-list fput random-price random-price-list
End




To decide-quantity

If price-setting = "equilibrium" [
set price equilibrium-price
]

If price-setting = "random" [
set price random-price
]

If price-setting = "manual-trade" [
set price choose-price]


;similarly for market clearing:
;If price-setting = "market-clearing" [
;Let price ???


ask consumers [
    let budget (tableware * price ) + money ;calculating budget based on tableware owned and price-setting and current holding of money
    let optimal round (budget * alpha / price) ;optimal number of tableware to HOLD given the current price
    set offer precision ( optimal - tableware ) 2 ;offer to buy the number of tableware optimal with current holding subtracted
  ]


  ask merchants [
    let budget ( tableware * price ) + money ;@@ check up on why we choose quantity according to this
    let optimal ( budget * alpha / price )
    set offer precision ( tableware - optimal ) 2  ;@@ why is this the other way around compared to consumers????? because merchants don't want tableware! e.g. got 50, optimal is 30. 50-30=20. sell 20!

  ]


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
end


to trade-and-update-holdings
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

End




to create-price-lists
  set price-list []
  set market-price-list []
  set equilibrium-price-list []
  set random-price-list []
end


;update inside price-setting function instead
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

  let quantity-offer ( item 0 [offer] of consumers )
 ifelse quantity-offer > 0
  [report quantity-offer]
  [report "not interested in buying"]  ;only positive quantities are reported; if not, there is no chance of trading
  ; should the quantity value be added even when negative?

;@@lisa: needs to be adjusted for 1x tableware trades
end

to-report report-offer-merchants
  let quantity-offer item 0 [ offer ] of merchants
  ifelse quantity-offer > 0
  [report quantity-offer]
  [report "not interested in selling"]
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


;to-report merchant-optimal-price
;;  report
;;
;;  precision
;;  ( [ alpha * tableware ] of merchant 1 /
;;  [beta * money] of merchant 1 )
;;  2
;
;

;to-report consumer-optimal-price
;
;  report
;
;  precision
;  ( [ alpha * tableware ] of consumer 1 /
;  [beta * money] of consumer 1 )
;  2
;
;
;end
@#$#@#$#@
GRAPHICS-WINDOW
458
107
895
545
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
219
216
320
276
money-merchants
50.0
1
0
Number

INPUTBOX
358
213
460
273
money-consumers
50.0
1
0
Number

INPUTBOX
219
280
321
340
tableware-merchants
50.0
1
0
Number

INPUTBOX
359
276
462
336
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
100.0
1
0
Number

SLIDER
193
130
321
163
alpha-merchants
alpha-merchants
0
1
0.2
0.1
1
NIL
HORIZONTAL

SLIDER
336
127
463
160
alpha-consumers
alpha-consumers
0
0.9
0.4
0.1
1
NIL
HORIZONTAL

TEXTBOX
199
99
327
127
Variables for the merchant breed
11
0.0
1

TEXTBOX
338
93
461
121
Variables for the consumer breed\n
11
0.0
1

MONITOR
1087
10
1250
55
price
precision report-price 2
17
1
11

MONITOR
1092
78
1248
123
NIL
report-mrs-merchants
17
1
11

MONITOR
911
76
1064
121
NIL
report-mrs-consumers
17
1
11

CHOOSER
8
143
157
188
price-setting
price-setting
"market-clearing" "equilibrium" "random" "choose price"
1

MONITOR
195
167
324
212
Beta for merchants
report-beta-merchants
17
1
11

MONITOR
336
164
462
209
Beta for consumers
report-beta-consumers
17
1
11

MONITOR
1101
153
1243
198
NIL
report-offer-merchants
17
1
11

MONITOR
897
153
1093
198
NIL
report-offer-consumers
17
1
11

SLIDER
2
190
155
223
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
908
267
1055
312
NIL
nr-tableware-merchants
17
1
11

MONITOR
1091
270
1240
315
NIL
nr-money-merchants
17
1
11

MONITOR
908
222
1056
267
NIL
nr-tableware-consumers
17
1
11

MONITOR
1092
225
1241
270
nr-money-consumers
nr-money-consumers
17
1
11

MONITOR
726
547
851
592
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
1
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
927
312
1030
357
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
1.0
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
20.0
1
1
NIL
HORIZONTAL

MONITOR
1123
315
1212
360
total money
round ( nr-money-merchants + nr-money-consumers )
17
1
11

TEXTBOX
1022
204
1172
222
Current holdings
11
0.0
1

TEXTBOX
964
133
1184
161
Most recent offer (quantity to buy/ sell)
11
0.0
1

TEXTBOX
960
58
1196
86
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
893
361
1328
591
price/tableware
Ticks/ time
price per item
0.0
10.0
0.0
2.0
true
true
"" ""
PENS
"price" 1.0 0 -9276814 true "" "plot price"
"mean" 1.0 0 -5298144 true "" "plot mean-price"
"equilibrium" 1.0 2 -14454117 true "" "if equilibrium-price > 0 [\nplot equilibrium-price ]"
"random" 1.0 0 -13840069 true "" "if random-price > 0 [\nplot random-price]"

SLIDER
195
540
464
573
tableware-broken-per-tick-consumers
tableware-broken-per-tick-consumers
0
20
2.0
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
935
591
1085
636
mean price/ tableware
precision mean-price 2
17
1
11

OUTPUT
460
10
896
140
9

SWITCH
0
228
214
261
compare-all-price-settings?
compare-all-price-settings?
0
1
-1000

SLIDER
533
559
705
592
running-speed
running-speed
0
1
0.25
0.05
1
NIL
HORIZONTAL

TEXTBOX
1096
599
1246
627
monitor only prices from succesful trades
11
0.0
1

TEXTBOX
11
264
161
292
all agents are using one mode right now
11
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
