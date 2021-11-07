globals [
  price-list
  market-clearing-price-list
  equilibrium-price-list
  random-price-list
  negotiation-price-list
  price-offered-by

  active-trading-style ;used for active-turtles in compare-all

  price

  global-difference-list
  total-supply-list
  total-demand-list
  price-check-list
]

breed [merchants merchant]
breed [consumers consumer]

turtles-own [
  trading-style
  alpha ;preference for tableware
  beta ;preference for money
  money
  tableware
  mrs ;marginal rate of substitution ;hvor mange penge er EN tallerken værd (neutralt/ligegyldigt punkt)
  partner
]


to setup
  clear-all
  reset-ticks
  layout
  make-turtles price-setting ;tager price setting som input
  ask turtles [ set-partner ]
  ask turtles [ update-mrs ]
  create-price-lists
  initiate-price-plot
end


to go
  trade




  ;ask turtles [ update-mrs ] ;only for some price-settings
end


to trade ;THE function run in go!
  if price-setting = one-of ["market clearing" "equilibrium" "random"] [
    set active-trading-style price-setting
    set-price                                ; step 2
    ;decide-quantity                          ; step 3
    ;check-utility-and-trade                  ; step 4
    ;print-trade-details


  ]

  if price-setting = "negotiation" [
    set active-trading-style price-setting
    set-price
    ;print-trade-details
  ]

  if price-setting = "compare all price settings" [
    foreach ["market clearing" "equilibrium" "random" "negotiation"] [
      style ->
      set active-trading-style style

      set-price ;@include all

      if style != "negotiation" [ ;@@@
        decide-quantity
        check-utility-and-trade ;@remove from negotiation if included here
      ]
    ]

  ]

end

to set-price ;run in trade
  let price-function (word "set-price-" (substring active-trading-style 0 3)) ;e.g. "set-price-neg"
  run price-function
end

to-report temporary-budget [n] ;total capital in money
  report ( tableware * n ) + money
end

to-report temporary-optimal [n] ;Optimal holding of tableware
  report round ( temporary-budget n * alpha / n ) ;budget [ foreslået pris ] * alpha / foreslået pris
end

to-report temporary-demand [n]
  let demandd (temporary-optimal n - tableware)
  report ifelse-value demandd > 0 [demandd] [0]
end

to-report temporary-supply [n]
  let supplyy (tableware - temporary-optimal n)
  report ifelse-value supplyy > 0 [supplyy] [0]
end


to set-price-mar ;market clearing. from set-price, run in trade
  set global-difference-list [] ;clear, initiate
  set total-supply-list []
  set total-demand-list []

  set price-check-list map [i -> precision i 2] (range 0.1 20.1 .1) ;listen ser sådan her ud: [0.1 0.2 0.3 0.4 ... 20]
    ;n is price-temporary, i.e. each element of this price-list^^

  ask turtles with[ trading-style = "market clearing" ] [

    let list-supply (map [n -> temporary-supply n] price-check-list)
    ;Save evert turtles supply list in a global / total list::
        ifelse length total-supply-list > 0 [
      set total-supply-list (map + list-supply total-supply-list)
    ]
    [
      set total-supply-list list-supply ;First turtle cannot map as there is nothing in the tota-supply-list initially
    ]



    let list-demand (map [n -> temporary-demand n] price-check-list)
    ;Save evert turtles demand list in a global / total list::
        ifelse length total-demand-list > 0 [
      set total-demand-list (map + list-demand total-demand-list)
    ]
    [
      set total-demand-list list-demand ;First turtle cannot map as there is nothing in the tota-supply-list initially
    ]

  ;  show list-supply
  ;  show list-demand

    ;lav ny liste med FORSKELLEN på de to:
    let list-forskel (map + list-supply list-demand)

    ifelse length global-difference-list > 0 [
      set global-difference-list (map - global-difference-list list-forskel) ;Minus, as we want to find where the difference is the lowest. HOWEVER, when there are more than 2 agents we need another solution @@@@@
    ]
    [
      set global-difference-list list-forskel ;den første turtle til at gøre det (kan ikke mappe på tom liste)
    ]
  ] ;END of ask turtles

  set global-difference-list (map abs global-difference-list)
 ; show global-difference-list

  ;når vi har den forskels-liste for hver turtle, skal vi finde der, hvor summen af 'kolonnen' (samme liste-index) er mindst - altså den overall bedste pris

  let min-forskel min global-difference-list
  let nr-occurences frequency min-forskel global-difference-list ;bruger frequency funktion/reporter

  let first-index position min-forskel global-difference-list ;index for første appearance af min i listen
  let last-index first-index + nr-occurences


  let min-differences sublist price-check-list first-index last-index
 ; show min-differences
  set price mean min-differences ;THIS IS WHAT WE WANT - gemmer mean pris (da der er flere occurences)

  ;og gemme den pris (hvilken pris svarede det til i price-check-list?) (skal vi også gemme summen af supply-demand-forskel? eller gennemsnit?)

  plot-market-clearing

end

to plot-market-clearing
  ;brug global demand og supply lister

  set-current-plot "Demand and Supply Plot"
  clear-plot
  create-temporary-plot-pen "supply"
  set-current-plot-pen "supply"
  set-plot-pen-color 15
  set-plot-x-range 0.1 20
  let upper-bound ( money-merchants + money-consumers + tableware-merchants + tableware-consumers ) / 2
  set-plot-y-range 0 upper-bound
  ;plotxy price-check-list total-supply-list

  ;(map [[a b] -> plotxy a b] price-check-list total-supply-list)

  (foreach price-check-list total-supply-list
    [
      [x y] ->
      plotxy x y

    ])

  create-temporary-plot-pen "demand"
  set-current-plot-pen "demand"
  set-plot-pen-color 105
   set-plot-x-range 0.1 20

  (foreach price-check-list total-demand-list
    [
      [x y] ->
      plotxy x y

    ])

end


to set-price-equ ;equilibrium. from set-price, run in trade

  ; equilibrium sets the price as the  mean between the two agents' optimal prices (based on demand and excess demand from Hamill&Gilbert pp. 89)
  ; the underlying assumption from economy is that negotiating will even prices out over time - and that both are equally good at negotiating

  ask active-consumer [
    set price  precision (
      ( ( alpha * tableware ) + [ alpha * tableware ] of partner )  /
      ( ( beta * money ) + [ beta  * money ] of partner ) )    2

  ]

end

to set-price-ran ;random. from set-price, run in trade

  ;;;; we establish which trading rates each agent would like, and then pick a price at random in this interval
  ;;;; the underlying assumption is that over time, the prices will even out that both agents get a fair price
  ;;; furthermore, the price will play a role in how many items are traded

  let minMRS min [ mrs ] of active-turtles ;defining lowest MRS
   let maxMRS max [ mrs ] of active-turtles ;and highest MRS
    set price  minMRS + ( random ( 100 * ( maxMRS - minMRS ) ) / 100 ) ; because random produces integers

end


to set-price-neg ;negotiation. from set-price, run in trade

;
;  let initial-bidder one-of active-turtles ;randomly decides who opens the negotiation
;  let second-bidder [partner] of initial-bidder
;
;
;  ask initial-bidder [
;
;    ;;;; round 1:
;    set price mrs
;    decide-quantity
;    ;possible to make an ifelse about deal here already to save computing
;    check-utility-and-trade ;write out the outputs. No interesting until the deal actually pulls through
;    ifelse deal > 0 [
;      if price-setting = "compare-all-price-settings" [stop]
;      output-print ( word "Offer 1 made by " ( [ breed ] of initial-bidder ) " accepted.")
;      stop ] ;if the bid is accepted, exit this function
;
;
;    [
;      ;;;; else, start round 2:
;      ;if the first deal is not accepted, partner suggests its mrs instead and the trading evaluation runs again
;
;      set price [mrs] of partner
;      decide-quantity
;      check-utility-and-trade
;      ifelse deal > 0 [
;        if price-setting = "compare-all-price-settings" [stop]
;        output-print ( word "Offer 2 made by " [ breed ] of second-bidder " accepted." )
;        stop]
;
;
;      [
;        ;;;; else, start round 3:
;        ;agent1 now gets to set the price again. This time she sets it according to the principle: My optimal price + 20% of the price difference between the intial two offers
;        let mrs-price-difference ( mrs - [mrs] of partner ) ;might be a positive or negative number - that is great for these calculations
;        set price mrs + (mrs-price-difference * 0.2 ) ;this could also be the bid of the other agent depending on whether the mrs-difference is a positive or negative. In practice shouldn't matter
;        decide-quantity
;        check-utility-and-trade
;        ifelse deal > 0 [
;          if price-setting = "compare-all-price-settings" [stop]
;          output-print ( word "Offer 3 made by " [ breed ] of initial-bidder " accepted.")
;          stop]
;
;        [
;          ;;;; else, start round 4:
;          ; agent2 does the same
;          set price ( [mrs] of partner + mrs-price-difference * 0.2 ) ;oops, for the merchant subtraction is needed. How can we do this smart?
;          decide-quantity
;          check-utility-and-trade
;          ifelse deal > 0 [
;            if price-setting = "compare-all-price-settings" [stop]
;            output-print ( word "Offer 4 made by " [ breed ] of second-bidder " accepted." )
;            stop]
;
;          [
;            ;;; round 5, agent 1 with 40%
;            set price mrs + (mrs-price-difference * 0.4 )
;            decide-quantity
;            check-utility-and-trade
;            ifelse deal > 0 [
;              if price-setting = "compare-all-price-settings" [stop]
;              output-print ( word "Offer 5 made by " [ breed ] of initial-bidder " accepted." )
;              stop]
;
;            [
;              ; round 6, agent2 does the same
;              set price ( [mrs] of partner + mrs-price-difference * 0.4 )
;              decide-quantity
;              check-utility-and-trade
;              ifelse deal > 0 [
;                if price-setting = "compare-all-price-settings" [stop]
;                output-print ( word "Offer 6 made by " [ breed ] of second-bidder  " accepted." )
;                stop ]
;
;
;
;
;              [
;                ;final round - agent1 offers to meet halfway. If this is a no-deal, there will be no trade.
;                set price mrs + mrs-price-difference * 0.5
;                decide-quantity
;                check-utility-and-trade
;                if deal > 0
;                [if price-setting = "compare-all-price-settings" [stop]
;                  output-print "Agents met halfway between their initial prices." ]
;                if deal = 0
;                [ if price-setting = "compare-all-price-settings" [stop]
;                  output-print "Agents did not agree on a trading price." ]
;
;                ;the end
;
;              ]
;            ]
;          ]
;        ]
;      ]
;    ]
;  ]
;

end


to decide-quantity
  ;
end

to check-utility-and-trade
  ;
end


to-report active-turtles ;the ones currently trading
  ifelse price-setting = "compare all price settings" [
    report turtles with [trading-style = active-trading-style]
  ]
  [
    report turtles
  ]
end

to-report active-merchant
    report one-of active-turtles with [breed = "merchants"]
end

to-report active-consumer
    report one-of active-turtles with [breed = "consumer"]
end


to update-mrs ;turtle procedure. Run in setup and go. ;only used for equilibrium?
  ifelse tableware = 0 [
    set mrs "no tableware left"
  ]
  [
    set mrs precision ( (alpha * money) / (beta * tableware) ) 3
  ]
end




;---SETUP STUFF

to set-partner ;turtle procedure
  let my-style trading-style
  set partner one-of other turtles with [trading-style = my-style]
end

to create-price-lists ;run in setup
  set price-list []
  set market-clearing-price-list []
  set equilibrium-price-list []
  set random-price-list []
  set negotiation-price-list []
  set price-offered-by []
end

to initiate-price-plot ;run in setup
  set-current-plot "Price plot"
  set-plot-y-range 0 3

  ;create the plot pens to use:
  ifelse price-setting = "compare-all-price-settings" [

    ;@plot latest or mean? (for quantity)
    create-temporary-plot-pen "Market-clearing success"
    set-plot-pen-color red
    create-temporary-plot-pen "Market-clearing success2"
    set-plot-pen-color red
    set-plot-pen-mode 2

    create-temporary-plot-pen "Equilibrium success"
    set-plot-pen-color yellow
    create-temporary-plot-pen "Equilibrium success2"
    set-plot-pen-color yellow
    set-plot-pen-mode 2

    create-temporary-plot-pen "Random success"
    set-plot-pen-color green
    create-temporary-plot-pen "Random success2"
    set-plot-pen-color green
    set-plot-pen-mode 2

    create-temporary-plot-pen "Negotiation success"
    set-plot-pen-color violet
    create-temporary-plot-pen "Negotiation success2"
    set-plot-pen-color violet
    set-plot-pen-mode 2
  ]
  [
    create-temporary-plot-pen "Price trade successful"
    set-plot-pen-color green
    set-plot-pen-mode 2

    ;@FIGURE OUT HOW TO BEST VISUALISE - LINES, DOTS, ETC !!! (change dot size???)

    create-temporary-plot-pen "Price trade unsuccessful"
    set-plot-pen-color red
    set-plot-pen-mode 2 ;point mode

    create-temporary-plot-pen "Mean price successful trades" ;kvantitet?
    set-plot-pen-color blue
  ]
end



;---TURTLE REPORTERS

to-report my-utility ;turtle reporter
  report precision ( ( tableware ^ alpha ) * ( money ^ beta ) ) 2
end


;---LAYOUT STUFF

to layout ;run in setup ;sets up the world/background
  ;
end


to make-turtles [kind] ;run in setup
  ifelse kind = "compare all price settings" [
    ;if compare all:

    ;@TILFØJ

  ]
  [ ;if not compare all:

    create-consumers 1 [
      set color (my-color kind) + 1.5
      setxy -32 -5 ;@check position
      set shape "person"
      set heading 270
      set size 12
      set alpha alpha-consumers
      set beta precision ( 1 - alpha-consumers ) 3
      set money money-consumers
      set tableware tableware-consumers
      set trading-style kind
    ]

    create-merchants 1 [
      set color (my-color kind) - 1.5
      setxy 32 -5 ;@check position
      set trading-style kind
      set shape "person" ;ADD TABLEWARE SHAPE@
      set size 12
      set heading 90

      set alpha alpha-merchants
      set beta precision ( 1 - alpha-merchants ) 3
      set money money-merchants
      set tableware tableware-merchants
    ]




  ]


end

to-report my-color [kind] ;from make-turtles. input = trading style
  if kind = "market clearing" [
    report red
  ]

  ;...@ and so on
end

to-report frequency [an-item a-list]
    report length (filter [ i -> i = an-item] a-list)
end
@#$#@#$#@
GRAPHICS-WINDOW
325
10
803
489
-1
-1
5.8025
1
10
1
1
1
0
0
0
1
-40
40
-40
40
0
0
1
ticks
30.0

CHOOSER
39
225
227
270
price-setting
price-setting
"market clearing" "equilibrium" "random" "negotiation" "compare all price settings"
1

SLIDER
99
118
271
151
alpha-consumers
alpha-consumers
0
1
0.9
0.1
1
NIL
HORIZONTAL

SLIDER
61
467
233
500
tableware-consumers
tableware-consumers
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
46
67
218
100
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
353
501
525
534
tableware-merchants
tableware-merchants
0
100
50.0
1
1
NIL
HORIZONTAL

BUTTON
47
20
110
53
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
120
21
183
54
NIL
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

SLIDER
80
175
252
208
money-merchants
money-merchants
1
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
80
320
252
353
money-consumers
money-consumers
1
100
50.0
1
1
NIL
HORIZONTAL

PLOT
1000
220
1200
370
Demand and Supply Plot
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS

PLOT
915
375
1115
525
Price plot
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

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
