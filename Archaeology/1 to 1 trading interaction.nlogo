globals [
  price
  price-temporary
  deal
  succesful-trades
  price-list
  market-clearing-price-list
  equilibrium-price-list
  random-price-list
  negotiation-price-list
  temp-closest-to-market-clearing
  active-merchant
  active-consumer
  active-turtles
  merchant-optimal-price
  consumer-optimal-price
  unsuccesful-price
  recorded-time
  price-offered-by
  ;temporary for bug fixing
  initial-bidder
  second-bidder
  total-demand
  total-supply
  total-demand-list
  total-supply-list
  global-difference-list ;liste af lister - forskels-liste fra hver agent
  price-check-list
  consumer-mrs
  merchant-mrs
]


breed [merchants merchant]
breed [consumers consumer]


; edit: we don't need a seperate breeds-own. Perhaps later for layout.
turtles-own [
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
  ;for market-clearing
  temp-budget
  trading-style
  optimal-tableware
  supply
  demand
  optimal-price
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

  trade
  produce-tableware
  break-tableware
  earn-money
  update-mrs
  ;conversate ;;; now in check-utility-and-trade, as we want different text dependant on success or failed trade



  tick

  if ticks = stop-after-x-tick [
    stop
  ]
wait running-speed ;just to make the output better readable @@lisa: alternativ: every

end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




to populate ;;run in setup. Create starting population

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;creating agents with their specific traits;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;determines characteristics specific to each type: location, color and price-setting strategy


 if price-setting = "market-clearing"
  [
  repeat 1 [ make-market-clearing-turtles "merchants"]
  repeat 1 [ make-market-clearing-turtles "consumers"]
  ]


  if price-setting = "equilibrium"
  [
  repeat 1 [ make-equilibrium-turtles "merchants"]
  repeat 1 [ make-equilibrium-turtles "consumers"]
  ]


  if price-setting = "random"
  [
  repeat 1 [ make-random-turtles "merchants"]
  repeat 1 [ make-random-turtles "consumers"]
  ]


   if price-setting = "negotiation"
  [
  repeat 1 [ make-negotiation-turtles "merchants"]
  repeat 1 [ make-negotiation-turtles "consumers"]
  ]



  if price-setting = "compare-all-price-settings"
  [
  repeat 1 [ make-market-clearing-turtles "merchants"]
    repeat 1 [ make-market-clearing-turtles "consumers"]
    repeat 1 [ make-equilibrium-turtles "merchants"]
    repeat 1 [ make-equilibrium-turtles "consumers"]
    repeat 1 [ make-random-turtles "merchants"]
    repeat 1 [ make-random-turtles "consumers"]
    repeat 1 [ make-negotiation-turtles "merchants"]
    repeat 1 [ make-negotiation-turtles "consumers"]
  ]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;filling in traits general to all agents;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  let wanted (turtle-set merchants consumers) ;temporary variable to only handle these two turtle-breeds
  ask wanted
  [set size 5
  set mrs 0]

  ask merchants [
  set shape "tableware"
  set heading 90
  set alpha alpha-merchants
   set beta precision ( 1 - alpha-merchants ) 3
   set money money-merchants
  set tableware tableware-merchants
  ]


  ask consumers
  [set shape "person"
    set heading 270
    set alpha alpha-consumers
    set beta precision ( 1 - alpha-consumers ) 3
    set money money-consumers
    set tableware tableware-consumers
  ]


  if price-setting != "compare-all-price-settings" [ ;;; different formats
    ask wanted [
      set size 8
    ]
    ask merchants [
      setxy 10 -9
    ]
    ask consumers [
      setxy -10 -9
    ]
  ]

end



to make-market-clearing-turtles [kind]
  if kind = "merchants" [
    create-merchants 1 [
      set color red - 1
      setxy 10 11
      set trading-style "market-clearing"
  ]
  ]


  if kind = "consumers" [
    create-consumers 1 [
      set color red + 1.5
      setxy -10 11
      set trading-style "market-clearing"
  ]
  ]

end


to make-equilibrium-turtles [kind]

   if kind = "merchants" [
   create-merchants 1 [
   set color yellow - 1
   setxy 10 3
   set trading-style "equilibrium"
  ]
  ]

  if kind = "consumers" [
   create-consumers 1 [
      set color yellow + 1.5
      setxy -10 3
      set trading-style "equilibrium"
  ]
  ]
end


to make-random-turtles [kind]
  if kind = "merchants" [
   create-merchants 1 [
   set color green - 1
   setxy 10 -5
      set trading-style "random"

  ]
  ]

  if kind = "consumers" [
   create-consumers 1 [
      set color green + 1.5
      setxy -10 -5
      set trading-style "random"
  ]
  ]
end


to make-negotiation-turtles [kind]
  if kind = "merchants" [
   create-merchants 1 [
   set color magenta - 1
   setxy 10 -13 ;@ needs to be adjusted along with all the rest
      set trading-style "negotiation"

  ]
  ]

  if kind = "consumers" [
   create-consumers 1 [
      set color magenta + 1.5
      setxy -10 -13
      set trading-style "negotiation"
  ]
  ]
end



to layout


  ifelse price-setting = "compare-all-price-settings"

    [
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;; layout compare-all-price-settings ;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



    ;coloring patch sections for 4 conditions
    ask patches [ set pcolor blue - 2 ]
    ask patches with [ pycor > -8 ][ set pcolor blue - 1]
    ask patches with [ pycor > 0 ][ set pcolor blue ]
    ask patches with [ pycor > 8 ][ set pcolor blue + 1]
    ask patches with [pycor = 16] [set pcolor blue + 1.5] ;the top one will be bigger by one patch


    ;adding plabels to signify conditions
    ask patch 3 8
    [set plabel "Market-clearing"]
    ask patches with [pycor = 8 ] [set pcolor blue - 0.5]


    ask patch 2 0
    [set plabel "Equilibrium" ]
    ask patches with [pycor = -0] [set pcolor blue - 1.5 ]


    ask patch 1 -8
    [set plabel "Random"]
    ask patches with [pycor = -8] [set pcolor blue - 2.5 ]


    ask patch 2 -16
    [set plabel "Negotiation"]
    ask patches with [pycor = -16] [set pcolor blue - 3 ]


  ]


 [
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;; else, layout singular conditions ;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;patch colors
    ask patches [set pcolor blue - 1]
    ask patches with [pycor > 7 ] [set pcolor blue - 0.5]
    ask patches with [pycor > 11.5] [set pcolor blue ]


    ; putting a visual tag to show the condition
    ask patch 1 -16 [set plabel price-setting set pcolor blue]
    ask patches with [pycor < -14] [set pcolor blue - 2 ]


    ;;;gimmicks: acropolis
    create-turtles 1
    ask turtles
    [set shape "building institution" ;make it acropolis
      set size 8
      setxy 0 12
      set color white]

  ]

end



to conversate-trade-failed
    ;defining plabels
  ;;; consumer talks
  let c-talk1 patch pxcor-consumer 7 ;price
  let c-talk2 patch pxcor-consumer 1 ;quantity
  let c-talk3 patch pxcor-consumer -5 ;utility

  ;;; merchant talks
  let m-talk1 patch pxcor-merchant 6 ;price
  let m-talk2 patch pxcor-merchant 0 ;quantity
  let m-talk3 patch pxcor-merchant -5 ;utility

  ;;; agreement talks


      ;;;;;;; first commands are specific to condition ;;;;;;;
  if price-setting = "market-clearing" [
    ;clearing conversate success plabels
    let shared-talk1 patch pxcor-shared 5
    ask shared-talk1 [set plabel " " ]

    let shared-talk3 patch 6 5 ;price
    let shared-talk4 patch 7 4 ;utility
    ;@giver det mening at sætte information om supply/ demand her?
    ask shared-talk3 [set plabel "No agent benefits in utility from a"]
    ask shared-talk4 [set plabel "trade with prices between 0.1 and 20"]
  ]

    if price-setting = "equilibrium" [
    ;clearing conversate success plabels
    ask patch -8 7 [ set plabel " " ]
    ask patch -6 6 [ set plabel " " ]
    ask patch 10 7 [set plabel ""]
    ask patch 12 6 [set plabel " " ]
    ask patch 6 0  [set plabel ""]
    ask patch 8 -1 [set plabel " "]

    ask patch 10 0 [ set plabel "Utility does not increase for both agents, no trade is made" ]

  ]

   if price-setting = "random" [
      ask patch -5 7 [set plabel ""] ;;sæt fokus på indifference: "for mig er én tableware det samme værd som x penge"
      ask patch -5 6 [set plabel ""]
      ask patch -5 5 [set plabel ""]


      ask patch 14 7 [set plabel ""]
      ask patch 14 6 [set plabel ""]
      ask patch 14 5 [set plabel ""]


      ask patch 8 0  [set plabel "" ]
      ask patch 8 -1  [set plabel ""]

    ask patch 10 0 [ set plabel "Utility does not increase for both agents, no trade is made" ]
  ]


end

to conversate-trade-success
    ;defining plabels
  ;;; consumer talks
  let c-talk1 patch pxcor-consumer 7 ;price
  let c-talk2 patch pxcor-consumer 1 ;quantity
  let c-talk3 patch pxcor-consumer -5 ;utility

  ;;; merchant talks
  let m-talk1 patch pxcor-merchant 6 ;price
  let m-talk2 patch pxcor-merchant 0 ;quantity
  let m-talk3 patch pxcor-merchant -5 ;utility

  ;;; agreement talks
  let shared-talk1 patch pxcor-shared 5 ;price
  let shared-talk2 patch 0 4 ;utility


;;;;;;;; samtale-output;;;;;;;
; for nu udkast
;@actual values still need to be added

    ;;;;;;; first commands are specific to condition ;;;;;;;
  if price-setting = "market-clearing" [
      ;def plabels
      let shared-talk-mc1 patch 14 5 ;price
      let shared-talk-mc2 patch 0 4 ;utility

    ;@giver det mening at sætte information om supply/ demand her?
    ask shared-talk-mc1 [set plabel "This is the price at which the difference between supply and demand is the lowest:"]
    ask shared-talk-mc2 [set plabel precision price 2]


    ;; something something refer to the plot on supply/ demand
  ]


  if price-setting = "equilibrium" [ ;@tilføj noget med "my ideal propertions are such and such, so my ideal price is x"

    ask patch -8 7 [set plabel (word "my ideal price is: " precision consumer-optimal-price 2) ]
    ask patch -6 6 [set plabel precision consumer-optimal-price 2 ]

  ;

    ask patch 10 7 [set plabel "my ideal price is:"]
    ask patch 12 6 [set plabel precision merchant-optimal-price 2 ]


    ;
    ask patch 6 0  [set plabel "We meet halfway. This will be the price:"]
    ask patch 8 -1 [set plabel precision price 2]
    ]


 if price-setting = "random" [
      ask patch -5 7 [set plabel "The price for tableware at which"] ;;sæt fokus på indifference: "for mig er én tableware det samme værd som x penge"
      ask patch -5 6 [set plabel "i am indifferent about trading is:"]
      ask patch -5 5 [set plabel precision consumer-mrs 2]


      ask patch 14 7 [set plabel "The price for tableware at which"]
      ask patch 14 6 [set plabel "i am indifferent about trading is:"]
      ask patch 14 5 [set plabel precision merchant-mrs 2]


      ask patch 8 0  [set plabel "we pick a price at random between our mrs" ]
      ask patch 8 -1  [set plabel precision price 2]

      ;;; tilføj quantity
  ]


  if price-setting = "negotiation" [
        ask c-talk1 [set plabel "i bid my ideal price"] ;;sæt fokus på indifference: "for mig er én tableware det samme værd som x penge" (er det mrs?)
      ask m-talk1 [set plabel "to me, one piece of tableware is worth x (mrs) money"]
      ask shared-talk2  [set plabel "we pick a price at random between our mrs" ]





    ;;;;;;; commands that are shared for all conditions ;;;;;;
    ;quantity
    ask c-talk2  [set plabel "i want to buy this amount" ]
    ask m-talk2  [set plabel "i want to sell this amount" ]
    ask shared-talk2  [set plabel "we trade this amount" ]

    ;utility
    ask c-talk3  [set plabel "utility changed by :)" ]
    ask m-talk3  [set plabel "utility changed by :)" ]
  ]

end


;MRS beregninger med basis i bogen
;Cudos to   chap5 edgeworth box game.
  ;   set mrsCapt ( alphaCapt * captsCigs )  / ( ( 1 - alphaCapt ) * captsChocs )
  ;   set mrsSgt  ( alphaSgt * sgtsCigs  )  / ( ( 1 - alphaSgt ) *  sgtsChocs )


to update-mrs

  ;; løsning for at undgå division med 0 (når tableware = 0):
  ;; vi springer over udregning af ny mrs indtil næste runde og indsætter label "no tableware left"


ask merchants [
    if tableware = 0 [set mrs "no tableware left" stop]

    let nr ( alpha-merchants * money )  / ( beta * tableware )
    let rounded precision nr 3
    set mrs rounded
  ]


ask consumers [
    if tableware = 0 [set mrs "no tableware left" stop]

    let nr ( alpha-consumers * money )  / ( beta * tableware )
    let rounded precision nr 3
    set mrs rounded

]

end



to set-partner
  ask consumers [
    let my-style trading-style
    let me self
    set partner one-of merchants with [ trading-style = my-style]
    ;set partner one-of other merchants with [ trading-style = [ trading-style ] of self ]  ; partner skal have samme trading-style som mig selv

   ask partner [
      set partner me
    ]
  ]
end



to trade ;this is now THE function. No more trade2!
;;;;;;;;;;;;;    trading in 4 steps (seperate functions:
;;;;;;;;;;;;;    1) identify active agents
;;;;;;;;;;;;;    2) set price according to price-setting
;;;;;;;;;;;;;    3) decide quantity to trade
;;;;;;;;;;;;;    4) make sure both agents improve their utility, then trade



  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;; identifying active agents ;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  if price-setting = "market-clearing" [
    activate-market-clearing-turtles         ; step 1
    set-market-clearing-price                ; step 2
    decide-quantity                          ; step 3
    check-utility-and-trade                  ; step 4
    print-trade-details                      ;prints @commented out

  ]


  if price-setting = "equilibrium" [
    activate-equilibrium-turtles
    set-equilibrium-price
    decide-quantity
    check-utility-and-trade
    print-trade-details
  ]


  if price-setting = "random" [
    activate-random-turtles
    set-random-price
    decide-quantity
    check-utility-and-trade
    print-trade-details
  ]

  if price-setting = "negotiation" [
    activate-negotiation-turtles
    set-negotiation-price
    print-trade-details
  ]
  ;that's all for this command


  if price-setting = "compare-all-price-settings" [ ;just like the rest of them, but all of the above bundled together

    activate-market-clearing-turtles
    set-market-clearing-price
    decide-quantity
    check-utility-and-trade


    activate-equilibrium-turtles
    set-equilibrium-price
    decide-quantity
    check-utility-and-trade


    activate-random-turtles
    set-random-price
    decide-quantity
    check-utility-and-trade


    activate-negotiation-turtles
    set-negotiation-price

   ]

end


;these commands "activates" turtles with a certain trading-style, so that only they run the trading-procedures
;three groupings: merchants, consumers and both together
to activate-market-clearing-turtles
  set active-turtles turtles with [ trading-style = "market-clearing" ]
  set active-merchant merchants with [ trading-style = "market-clearing" ]
  set active-consumer consumers with [ trading-style = "market-clearing" ]
end


to activate-equilibrium-turtles
  set active-turtles turtles with [ trading-style = "equilibrium" ]
  set active-merchant merchants with [ trading-style = "equilibrium" ]
  set active-consumer consumers with [ trading-style = "equilibrium" ] ;specifying which agents we want to use in this command!
end


to activate-random-turtles
  set active-turtles turtles with [ trading-style = "random" ]
  set active-merchant merchants with [ trading-style = "random" ]
  set active-consumer consumers with [ trading-style = "random" ] ;specifying which agents we want to use in this command!
end

to activate-negotiation-turtles
  set active-turtles turtles with [ trading-style = "negotiation" ]
  set active-merchant merchants with [ trading-style = "negotiation" ]
  set active-consumer consumers with [ trading-style = "negotiation" ] ;specifying which agents we want to use in this command!
end



to-report temporary-budget [n] ;total capital in money
  report ( tableware * n ) + money
end

to-report temporary-optimal [n] ;Optimal holding of tableware
  report round ( temporary-budget n * alpha / n )
end

to-report temporary-demand [n]
  let demandd (temporary-optimal n - tableware)
  report ifelse-value demandd > 0 [demandd] [0]
end

to-report temporary-supply [n]
  let supplyy (tableware - temporary-optimal n)
  report ifelse-value supplyy > 0 [supplyy] [0]
end

;      set temp-budget ( tableware * price-temporary ) + money ;essentially how much your total capital (tableware and money) is worth in money.
;      set  optimal-tableware round ( temp-budget * alpha / price-temporary ) ; how much tableware you want given your budget, alpha and the current price
;      ;if optimal-tableware < 1  [
;      ; set optimal-tableware 1

to set-market-clearing-price
  set global-difference-list [] ;clear, initiate
  set total-supply-list []
  set total-demand-list []

  set price-check-list map [i -> precision i 2] (range 0.1 20.1 .1) ;listen ser sådan her ud: [0.1 0.2 0.3 0.4 ... 20]
    ;n is price-temporary, i.e. each element of this price-list^^

  ask turtles with[ trading-style = "market-clearing" ] [

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

    show list-supply
    show list-demand

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
  show global-difference-list

  ;når vi har den forskels-liste for hver turtle, skal vi finde der, hvor summen af 'kolonnen' (samme liste-index) er mindst - altså den overall bedste pris

  let min-forskel min global-difference-list
  let nr-occurences frequency min-forskel global-difference-list ;bruger frequency funktion/reporter

  let first-index position min-forskel global-difference-list ;index for første appearance af min i listen
  let last-index first-index + nr-occurences


  let min-differences sublist price-check-list first-index last-index
  show min-differences
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

 to-report consumer-ideal-price
  report [alpha * tableware ] of active-consumer / [ beta * money ] of active-consumer
end


to-report merchant-ideal-price
   report [alpha * tableware ] of active-merchant / [ beta * money ] of active-merchant
end




to set-equilibrium-price

 ;;;;;;;;;;;;;;;; Equilibrium ;;;;;;;;;;;;;;;;;;
; equilibrium sets the price as the  mean between the two agents' optimal prices
; the underlying assumption from economy is that negotiating will even prices out over time - and that both are equally good at negotiating
; based on equilibrum from the red cross parcel

  ask active-consumer [
     set price  precision (
                           ( ( alpha * tableware ) + [ alpha * tableware ] of partner )  /
      ( ( beta * money ) + [ beta  * money ] of partner ) )    2

  ]

   ;;;;;;;;;;;;;;;;;;;
  ;; output-prints ;;
  ;;;;;;;;;;;;;;;;;;;

  ask active-consumer [
  set consumer-optimal-price ( alpha * tableware ) / ( beta * money ) ;disse passer ikke
  ]

  ask active-merchant [
  set merchant-optimal-price ( alpha * tableware / beta  * money )
  ]

  if price-setting = "compare-all-price-settings" [stop]

 output-print (word "Consumer price (here)." )
   ; output-print (word "Consumer price " precision consumer-optimal-price 2 ". " )
 ; output-print (word "Consumer price (reporter) " precision consumer-ideal-price 2 ". " ) ;from reporter

  output-print (word "Merchant price (here). ")
  ;    output-print (word "Merchant price " precision merchant-optimal-price 2 ". " )
  ;    output-print (word "Merchant price (reporter) " precision merchant-ideal-price 2 ". " ) ;from reporter

    output-print (word "Midway meeting point " price ". " )

end



To set-random-price
  ;;;; we establish which trading rates each agent would like, and then pick a price at random in this interval
  ;;;; the underlying assumption is that over time, the prices will even out that both agents get a fair price
  ;;; furthermore, the price will play a role in how many items are traded
  set consumer-mrs item 0 [ mrs ] of active-consumer
  set merchant-mrs item 0 [mrs ] of active-merchant
  let minMRS min [ mrs ] of active-turtles ;defining lowest MRS
   let maxMRS max [ mrs ] of active-turtles ;and highest MRS
    set price  minMRS + ( random ( 100 * ( maxMRS - minMRS ) ) / 100 ) ; because random produces integers



  ;;;;;;;;;;;;;;;;;;;
  ;; output-prints ;;
  ;;;;;;;;;;;;;;;;;;;

  if price-setting = "compare-all-price-settings" [stop]
  output-print (word "Lowest MRS " precision minMRS 2 ". " )
  output-print (word "Highest MRS " precision maxMRS 2 ". " ) ;is there a smarter way to change the line than putting a new command?
  output-print (word "Random price in between this round " precision price 2 ". " )

End


to set-bidders
  set initial-bidder one-of active-turtles ;randomly decides who opens the negotiation
  set second-bidder [partner] of initial-bidder

end


to set-optimal-price
  ;Set optimal price
  ask active-turtles [
    set optimal-price ( alpha * tableware ) / ( beta * money )

  ]

;    set temp-budget ( tableware * price-temporary ) + money ;essentially how much your total capital (tableware and money) is worth in money.
;    set optimal-tableware round ( temp-budget * alpha / price-temporary ) ; how much tableware you want given your budget, alpha and the current price
;    set optimal-money round ( temp-budget * beta )
;    set optimal-price
;
;      @@@@@@delete prob
;
;  ]
;
end

to set-negotiation-price ; simple version for getting rid of error


  set initial-bidder one-of active-turtles ;randomly decides who opens the negotiation

  set second-bidder [partner] of initial-bidder ;nogengange problem med at definere second-bidder. Hvorfor?



  ask initial-bidder [

   ;;;; round 1:
    set price mrs
    decide-quantity
    ;possible to make an ifelse about deal here already to save computing
    check-utility-and-trade ;write out the outputs. No interesting until the deal actually pulls through

        ifelse deal > 0 [
      if price-setting = "compare-all-price-settings" [stop]
      output-print ( word "Offer 1 made by " ( [ breed ] of initial-bidder ) " accepted.")
      stop ] ;if the bid is accepted, exit this function


    [
    ;;;; else, start round 2:
      ;if the first deal is not accepted, partner suggests its mrs instead and the trading evaluation runs again

      set price [mrs] of second-bidder
      decide-quantity
      check-utility-and-trade
    ]
  ]
;
;      ifelse deal > 0 [
;        if price-setting = "compare-all-price-settings" [stop]
;        output-print ( word "Offer 2 made by " [ breed ] of second-bidder " accepted." )
;       stop]


;      [
;      ;;;; else, start round 3:
;      ;agent1 now gets to set the price again. This time she sets it according to the principle: My optimal price + 20% of the price difference between the intial two offers
;        let mrs-price-difference ( mrs - [mrs] of partner ) ;might be a positive or negative number - that is great for these calculations
;        set price mrs + (mrs-price-difference * 0.2 ) ;this could also be the bid of the other agent depending on whether the mrs-difference is a positive or negative. In practice shouldn't matter
;        decide-quantity
;        check-utility-and-trade
;        ifelse deal > 0 [
;          if price-setting = "compare-all-price-settings" [stop]
;         output-print ( word "Offer 3 made by " [ breed ] of initial-bidder " accepted.")
;        stop]
;
;        [
;          ;;;; else, start round 4:
;          ; agent2 does the same
;          set price ( [mrs] of partner + mrs-price-difference * 0.2 ) ;oops, for the merchant subtraction is needed. How can we do this smart?
;          decide-quantity
;          check-utility-and-trade
;          ifelse deal > 0 [
;            if price-setting = "compare-all-price-settings" [stop]
;              output-print ( word "Offer 4 made by " [ breed ] of second-bidder " accepted." )
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
;             stop ]
;
;
;

;              [
;                ;final round - agent1 offers to meet halfway. If this is a no-deal, there will be no trade.
;                ;set price mrs + mrs-price-difference * 0.5
;        set price mrs * 0.5
;                decide-quantity
;                check-utility-and-trade
;                if deal > 0
;                [if price-setting = "compare-all-price-settings" [stop]
;                  output-print "Agents met halfway between their initial prices." ]
;                if deal = 0
;                [ if price-setting = "compare-all-price-settings" [stop]
;                  output-print "Agents did not agree on a trading price." ]

                ;the end

              ;]
            ;]
          ;]
;        ]
 ;     ]
  ;  ]
  ;]


end



to set-negotiation-price-NORMALwERROR ;this version runs with MRS while we haven't figured out "ideal" price-setting
  ;@ a loop can definitely be useful here. ;-) (see test-negotiation-price-loop for starters)


set-bidders ;make this LET?
set-optimal-price


  ask initial-bidder [

   ;;;; round 1:
    set price mrs
    decide-quantity
    ;possible to make an ifelse about deal here already to save computing
    check-utility-and-trade ;write out the outputs. No interesting until the deal actually pulls through
    ifelse deal > 0 [
      if price-setting = "compare-all-price-settings" [stop]
      output-print ( word "Offer 1 made by " ( [ breed ] of initial-bidder ) " accepted.")
      stop ] ;if the bid is accepted, exit this function


    [
    ;;;; else, start round 2:
      ;if the first deal is not accepted, partner suggests its mrs instead and the trading evaluation runs again

      set price [mrs] of partner
      decide-quantity
      check-utility-and-trade
      ifelse deal > 0 [
        if price-setting = "compare-all-price-settings" [stop]
        output-print ( word "Offer 2 made by " [ breed ] of second-bidder " accepted." )
       stop]


      [
      ;;;; else, start round 3:
      ;agent1 now gets to set the price again. This time she sets it according to the principle: My optimal price + 20% of the price difference between the intial two offers
        let mrs-price-difference ( mrs - [mrs] of partner ) ;might be a positive or negative number - that is great for these calculations
        set price mrs + (mrs-price-difference * 0.2 ) ;this could also be the bid of the other agent depending on whether the mrs-difference is a positive or negative. In practice shouldn't matter
        decide-quantity
        check-utility-and-trade
        ifelse deal > 0 [
          if price-setting = "compare-all-price-settings" [stop]
         output-print ( word "Offer 3 made by " [ breed ] of initial-bidder " accepted.")
        stop]

        [
          ;;;; else, start round 4:
          ; agent2 does the same
          set price ( [mrs] of partner + mrs-price-difference * 0.2 ) ;oops, for the merchant subtraction is needed. How can we do this smart?
          decide-quantity
          check-utility-and-trade
          ifelse deal > 0 [
            if price-setting = "compare-all-price-settings" [stop]
              output-print ( word "Offer 4 made by " [ breed ] of second-bidder " accepted." )
            stop]

          [
            ;;; round 5, agent 1 with 40%
            set price mrs + (mrs-price-difference * 0.4 )
            decide-quantity
            check-utility-and-trade
            ifelse deal > 0 [
              if price-setting = "compare-all-price-settings" [stop]
              output-print ( word "Offer 5 made by " [ breed ] of initial-bidder " accepted." )
              stop]

            [
              ; round 6, agent2 does the same
              set price ( [mrs] of partner + mrs-price-difference * 0.4 )
              decide-quantity
              check-utility-and-trade
              ifelse deal > 0 [
                if price-setting = "compare-all-price-settings" [stop]
                output-print ( word "Offer 6 made by " [ breed ] of second-bidder  " accepted." )
             stop ]




              [
                ;final round - agent1 offers to meet halfway. If this is a no-deal, there will be no trade.
                set price mrs + mrs-price-difference * 0.5
                decide-quantity
                check-utility-and-trade
                if deal > 0
                [if price-setting = "compare-all-price-settings" [stop]
                  output-print "Agents met halfway between their initial prices." ]
                if deal = 0
                [ if price-setting = "compare-all-price-settings" [stop]
                  output-print "Agents did not agree on a trading price." ]

                ;the end

              ]
            ]
          ]
        ]
      ]
    ]
  ]


end


to test-loop
  ;;;set bidders;;;
    set initial-bidder one-of active-turtles ;randomly decides who opens the negotiation
  set second-bidder [partner] of initial-bidder


  let mrs1 [mrs] of initial-bidder
  let mrs2 [mrs] of second-bidder
  let mrs-difference (abs ( mrs1 - mrs2 ) )


; right now we don't distinguish which breed opens the negotiation
  ;prices to run through loop
  let potential-prices ( list
    mrs1
    mrs2
   ( mrs1 - mrs-difference * 0.2 )
   ( mrs2 + mrs-difference * 0.2 )
   ( mrs1 - mrs-difference * 0.4 )
   ( mrs2 + mrs-difference * 0.4 )
   ( mrs1 - mrs-difference * 0.5 )
  )





end


to test-negotiation-price-loop ;for now with MRS

  ;;;setting optimal prices;;;;
;      ask active-turtles [
 ;   set optimal-price ( alpha * tableware ) / ( beta * money )
 ; ]

  ;;;set bidders;;;
  set initial-bidder one-of active-turtles ;randomly decides who opens the negotiation
  set second-bidder [partner] of initial-bidder


  let mrs1 [mrs] of initial-bidder
  let mrs2 [mrs] of second-bidder
  let mrs-difference (abs ( mrs1 - mrs2 ) )


; right now we don't distinguish which breed opens the negotiation
  ;prices to run through loop
  let potential-prices ( list
    mrs1
    mrs2
   ( mrs1 - mrs-difference * 0.2 )
   ( mrs2 + mrs-difference * 0.2 )
   ( mrs1 - mrs-difference * 0.4 )
   ( mrs2 + mrs-difference * 0.4 )
   ( mrs1 - mrs-difference * 0.5 )
  )



  loop [
   ask active-turtles [
      set price potential-prices ;something something [item v + 1] in potential-prices. Ét item ad gangen.
      print potential-prices
    decide-quantity
    check-utility-and-trade
    if deal > 0 [stop]
    ]
  ]


end

to loop-di-doop



  set-bidders

  let mrs1 [mrs] of initial-bidder
  let mrs2 [mrs] of second-bidder
  let mrs-difference (abs ( mrs1 - mrs2 ) )

    let potential-prices ( list
    mrs1
    mrs2
   ( mrs1 - mrs-difference * 0.2 )
   ( mrs2 + mrs-difference * 0.2 )
   ( mrs1 - mrs-difference * 0.4 )
   ( mrs2 + mrs-difference * 0.4 )
   ( mrs1 - mrs-difference * 0.5 )
  )

  let negotiating-turtles (turtle-set initial-bidder second-bidder)

let deal? false

  while not deal? [
  foreach potential-prices [
  p ->

    set price p
    ask initial-bidder [
      decide-quantity
      check-utility-and-trade

    ]
    if deal > 0 [set deal? true]

]
]

;   [
;              ; round 6, agent2 does the same
;              set price ( [mrs] of partner + mrs-price-difference * 0.4 )
;              decide-quantity
;              check-utility-and-trade
;              ifelse deal > 0 [
;                output-print ( word "Offer 6 made by " [ breed ] of second-bidder  " accepted." )
;             stop ]

end



to set-negotiation-price-optprice ;this is actually a full command - no need for extra decide-quantity and checking utility after this
  ;@ a loop can definitely be useful here. ;-)




set-bidders ;make this LET?
set-optimal-price

  ask initial-bidder [

   ;;;; round 1:
    set price optimal-price
    decide-quantity
    ;possible to make an ifelse about deal here already to save computing
    check-utility-and-trade ;write out the outputs. No interesting until the deal actually pulls through
    ifelse deal > 0 [
      output-print ( word "Offer 1 made by " ( [ breed ] of initial-bidder ) " accepted.")
      stop ] ;if the bid is accepted, exit this function

    [
    ;;;; else, start round 2:
      ;if the first deal is not accepted, partner suggests its mrs instead and the trading evaluation runs again

      set price [optimal-price] of partner
      decide-quantity
      check-utility-and-trade
      ifelse deal > 0 [
        output-print ( word "Offer 2 made by " [ breed ] of second-bidder " accepted." )
       stop]

      [
      ;;;; else, start round 3:
      ;agent1 now gets to set the price again. This time she sets it according to the principle: My optimal price + 20% of the price difference between the intial two offers
        let optimal-price-difference ( optimal-price - [optimal-price] of partner ) ;might be a positive or negative number - that is great for these calculations
        set price optimal-price + (optimal-price-difference * 0.2 ) ;this could also be the bid of the other agent depending on whether the mrs-difference is a positive or negative. In practice shouldn't matter
        decide-quantity
        check-utility-and-trade
        ifelse deal > 0 [
         output-print ( word "Offer 3 made by " [ breed ] of initial-bidder " accepted.")
        stop]

        [
          ;;;; else, start round 4:
          ; agent2 does the same
          set price ( [optimal-price] of partner + optimal-price-difference * 0.2 ) ;oops, for the merchant subtraction is needed. How can we do this smart?
          decide-quantity
          check-utility-and-trade
          ifelse deal > 0 [
              output-print ( word "Offer 4 made by " [ breed ] of second-bidder " accepted." )
            stop]

          [
            ;;; round 5, agent 1 with 40%
            set price optimal-price + (optimal-price-difference * 0.4 )
            decide-quantity
            check-utility-and-trade
            ifelse deal > 0 [
              output-print ( word "Offer 5 made by " [ breed ] of initial-bidder " accepted." )
              stop]

            [
              ; round 6, agent2 does the same
              set price ( [optimal-price] of partner + optimal-price-difference * 0.4 )
              decide-quantity
              check-utility-and-trade
              ifelse deal > 0 [ output-print ( word "Offer 6 made by " [ breed ] of second-bidder  " accepted." )
             stop ]




              [
                ;final round - agent1 offers to meet halfway. If this is a no-deal, there will be no trade.
                set price optimal-price + optimal-price-difference * 0.5
                decide-quantity
                check-utility-and-trade
                if deal > 0
                [ output-print "Agents met halfway between their initial prices." ]
                if deal = 0
                [ output-print "Agents did not agree on a trading price." ]

                ;the end

              ]
            ]
          ]
        ]
      ]
    ]
  ]

end




to set-negotiation-price2 ;this is actually a full command - no need for extra decide-quantity and checking utility after this
  ;@ a loop can definitely be useful here. ;-)

;  let initial-bidder one-of active-turtles ;randomly decides who opens the negotiation
;  let second-bidder [partner] of initial-bidder
set-bidders ;make this LET?
set-optimal-price


  ;;;lisa: her kommer en MEGET klodset løsning. To kommandoer afhængig af hvem der er inital-bidder. Kan altid forbedres.


  if [breed] of initial-bidder = "merchant" [

    ;;;;; merchant as first-bidder ;;;;;

    ask initial-bidder [

   ;;;; round 1:
    set price optimal-price
    decide-quantity
    ;possible to make an ifelse about deal here already to save computing
    check-utility-and-trade ;write out the outputs. No interesting until the deal actually pulls through
    ifelse deal > 0 [
      output-print ( word "Offer 1 made by " ( [ breed ] of initial-bidder ) " accepted.")
      set price-offered-by fput ( [breed] of initial-bidder ) price-offered-by ;tracking who made the accepted offer in a list
      stop  ;if the bid is accepted, exit this function
    ]



    [
    ;;;; else, start round 2:
      ;if the first deal is not accepted, partner suggests its mrs instead and the trading evaluation runs again

      ;set price [mrs] of partner ;commenting for bug-fixing
      set price [optimal-price] of second-bidder
      decide-quantity
      check-utility-and-trade
      ifelse deal > 0 [
        output-print ( word "Offer 2 made by " [ breed ] of second-bidder " accepted." )
        set price-offered-by fput ( [breed] of second-bidder ) price-offered-by
       stop]

      [
      ;;;; else, start round 3:
      ;agent1 now gets to set the price again. This time she sets it according to the principle: My optimal price + 20% of the price difference between the intial two offers
        let optimal-price-difference abs ( optimal-price - [optimal-price] of partner ) ;now always an absolute value
        set price optimal-price - (optimal-price-difference * 0.2 ) ; merchant is first bidder in this chunk of code; we can assume he sets the higher price of the two agents, and therefore to meet towards the middle, we subtract the difference from the optimal price
        decide-quantity
        check-utility-and-trade
        ifelse deal > 0 [
         output-print ( word "Offer 3 made by " [ breed ] of initial-bidder " accepted.") ;we know for sure that this is merchant rn
          set price-offered-by fput ( [breed] of initial-bidder ) price-offered-by
        stop]

        [
          ;;;; else, start round 4:
          ; agent2 does the same
          set price ( [optimal-price] of second-bidder + optimal-price-difference * 0.2 )

          decide-quantity
          check-utility-and-trade
          ifelse deal > 0 [
              output-print ( word "Offer 4 made by " [ breed ] of second-bidder " accepted." )
            set price-offered-by fput ( [breed] of second-bidder ) price-offered-by
            stop]

          [
            ;;; round 5, agent 1 with 40%
            set price optimal-price - (optimal-price-difference * 0.4 )
            decide-quantity
            check-utility-and-trade
            ifelse deal > 0 [
              output-print ( word "Offer 5 made by " [ breed ] of initial-bidder " accepted." )
              set price-offered-by fput ( [breed] of initial-bidder ) price-offered-by
              stop]

            [
              ; round 6, agent2 does the same
              ;buggy-fixy: set price ( [mrs] of partner + mrs-difference * 0.4 )
              set price ( [optimal-price] of second-bidder + optimal-price-difference * 0.4 )
              decide-quantity
              check-utility-and-trade
              ifelse deal > 0 [ output-print ( word "Offer 6 made by " [ breed ] of second-bidder  " accepted." )
                set price-offered-by fput ( [breed] of second-bidder ) price-offered-by
             stop ]




              [
                ;final round - agent1 offers to meet halfway. If this is a no-deal, there will be no trade.
                set price optimal-price + optimal-price-difference * 0.5
                decide-quantity
                check-utility-and-trade
                if deal > 0
                [ output-print "Agents met halfway between their initial prices."
                set price-offered-by fput ( "met halfway" ) price-offered-by]
                if deal = 0
                [ output-print "Agents did not agree on a trading price."
                set price-offered-by fput ( "no deal" ) price-offered-by]

                ;the end

              ]
            ]
          ]
        ]
      ]
    ]
  ]
        ;;;;; ELSE: consumer as first-bidder ;;;;;

    ask initial-bidder [

   ;;;; round 1:
    set price optimal-price
    decide-quantity
    ;possible to make an ifelse about deal here already to save computing
    check-utility-and-trade ;write out the outputs. No interesting until the deal actually pulls through
    ifelse deal > 0 [
      output-print ( word "Offer 1 made by " ( [ breed ] of initial-bidder ) " accepted.")
      set price-offered-by fput ( [breed] of initial-bidder ) price-offered-by ;tracking who made the accepted offer in a list
      stop  ;if the bid is accepted, exit this function
    ]



    [
    ;;;; else, start round 2:
      ;if the first deal is not accepted, partner suggests its mrs instead and the trading evaluation runs again

      ;set price [mrs] of partner ;commenting for bug-fixing
      set price [optimal-price] of second-bidder
      decide-quantity
      check-utility-and-trade
      ifelse deal > 0 [
        output-print ( word "Offer 2 made by " [ breed ] of second-bidder " accepted." )
        set price-offered-by fput ( [breed] of second-bidder ) price-offered-by
       stop]

      [
      ;;;; else, start round 3:
      ;agent1 now gets to set the price again. This time she sets it according to the principle: My optimal price + 20% of the price difference between the intial two offers
        let optimal-price-difference abs ( optimal-price - [optimal-price] of partner ) ;now always an absolute value
        set price optimal-price + (optimal-price-difference * 0.2 ) ; consumer is first bidder in this chunk of code; we can assume he sets the lower price of the two agents, and therefore to meet towards the middle, we add the difference from the optimal price
        decide-quantity
        check-utility-and-trade
        ifelse deal > 0 [
         output-print ( word "Offer 3 made by " [ breed ] of initial-bidder " accepted.") ;we know for sure that this is merchant rn
          set price-offered-by fput ( [breed] of initial-bidder ) price-offered-by
        stop]

        [
          ;;;; else, start round 4:
          ; agent2 does the same
          set price ( [optimal-price] of second-bidder - optimal-price-difference * 0.2 )

          decide-quantity
          check-utility-and-trade
          ifelse deal > 0 [
              output-print ( word "Offer 4 made by " [ breed ] of second-bidder " accepted." )
            set price-offered-by fput ( [breed] of second-bidder ) price-offered-by
            stop]

          [
            ;;; round 5, agent 1 with 40%
            set price optimal-price + (optimal-price-difference * 0.4 )
            decide-quantity
            check-utility-and-trade
            ifelse deal > 0 [
              output-print ( word "Offer 5 made by " [ breed ] of initial-bidder " accepted." )
              set price-offered-by fput ( [breed] of initial-bidder ) price-offered-by
              stop]

            [
              ; round 6, agent2 does the same
              ;buggy-fixy: set price ( [mrs] of partner + mrs-difference * 0.4 )
              set price ( [optimal-price] of second-bidder - optimal-price-difference * 0.4 )
              decide-quantity
              check-utility-and-trade
              ifelse deal > 0 [ output-print ( word "Offer 6 made by " [ breed ] of second-bidder  " accepted." )
                set price-offered-by fput ( [breed] of second-bidder ) price-offered-by
             stop ]




              [
                ;final round - agent1 offers to meet halfway. If this is a no-deal, there will be no trade.
                set price optimal-price + optimal-price-difference * 0.5
                decide-quantity
                check-utility-and-trade
                if deal > 0
                [ output-print "Agents met halfway between their initial prices."
                set price-offered-by fput ( "met halfway" ) price-offered-by]
                if deal = 0
                [ output-print "Agents did not agree on a trading price."
                set price-offered-by fput ( "no deal" ) price-offered-by]

                ;the end

              ]
            ]
          ]
        ]
      ]
    ]
  ]



  ]


end





To decide-quantity

calculate-utility


  ;;; step 1:
  ;;;; given my a) current holding, b) the set price and c) my preferences (alpha and beta),
  ;;;; how many pieces of tableware do I wish to trade this round?

  ask active-consumer [
    ifelse  price = 0
    [ set offer 0 ] ;undgå ulovlig division. Vi kan assume at offer er 0 hvis pris er 0, idet agenter aldrig vil give væk gratis ("more is always better" -economy)

    ; else:
    [
      let budget (tableware * price ) + money  ;calculating budget based on tableware owned and price-setting and current holding of money. Price is retrieved from previous price-setting functions
      let optimal round (budget * alpha / price)  ;optimal number of tableware to HOLD given the current price
      set offer precision ( optimal - tableware ) 2  ;offer to buy the number of tableware optimal with current holding subtracted
      if offer * price > money [set offer ( money / price ) ] ;ensures that the consumer never offers more money than she currently has.
    ]
  ]


  ask active-merchant [
    ifelse price = 0
    [ set offer 0 ]

    [
      let budget ( tableware * price ) + money
      let optimal ( budget * alpha / price )
      set offer precision ( tableware - optimal ) 2
      if offer > tableware [ set offer tableware ] ; ensures that the merchant won't offer more than it currently has in its holding (can at most sell all the tableware they have)
    ]
  ]


  ;;;; step 2: making the offers sensible

  ;;;;; ensure that the number of tableware to be traded is a whole number
  ;;;;; we do so by rounding (floor, so in a negative direction)

  if quantity-options = "standard" [
  ask active-turtles with [ offer > 0 ] [
  set offer floor ( offer )
    ]
  ]

  ;;;; negative offers simply mean no trade. so we make it 0
    ask active-turtles with [ offer < 0 ]
    [      set offer 0    ]




  ;;;; step 3: Deciding on an amount
  ;;;; if we only trade 1 at a time, just set this amount
  ;;;; otherwise, choose the quantity suggested by the agent who wants to trade the fewest pieces of tableware

   ifelse quantity-options = "one tableware at a time" [ ;option A: one at a time
    ask active-turtles [set deal 1]]


    [ ;option B: Free to trade desired amount
    let merchant-offer item 0 [ offer ] of active-merchant ; defining the offer from each agent
    let consumer-offer item 0 [ offer ] of active-consumer

    set deal min list ( merchant-offer ) ( consumer-offer ) ; selecting the lowest number to trade from the list of offers
  ]


;;;;; step 4: Finalizing quantity to trade and final prize
;;;;; A merchant cannot trade more tableware than they currently hold
  ;;;;;;@i think this is REDUDANT <3 #dealmoney and #dealtableware


;  ask active-turtles [
;    ifelse tableware - deal <= 0 [ ;if the deal supersedes the current holding of tableware
;      set deal-tableware tableware] ;set the quantity to current holding of tableware, which is max possible to trade
;    [set deal-tableware deal] ;or else, stick with the agreed upon quantity
;  ]
;



end


to check-utility-and-trade

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;;; utilty-check ;;;;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ; check if we increase utility, and engage in trade if yes. Otherwise nothing happens.
  ;(set deal 0 is to allow us to prompt "trade cancelled" or so)


  ;;;; step 0: Defining variables for more easily readable calculations

  let deal-tableware ( deal )
  let deal-money ( deal * price ) ;we are defining these two variables to make the following calculations more easily understandable


  ;;;; step 1: calculating the change in utility for each agent given the planned trade
;;; @lisa: there is some problematic calculations going on with the ^s. I tried to solve it, but for now without success.


ask active-consumer [
   if deal-tableware > 0 [
     set temp-tableware ( tableware + deal-tableware )
     set temp-money ( money - deal-money )
     set temp-utility precision ( ( temp-tableware ^ alpha ) * ( temp-money ^ beta ) ) 2 ;cobb-douglas utility function
    ]
  ]

ask active-merchant [
   if deal-tableware > 0 [
     set temp-tableware ( tableware - deal-tableware )
     set temp-money ( money + deal-money )
   ;  set temp-utility precision ( ( temp-tableware ^ alpha ) * ( temp-money ^ beta ) ) 2 ;cobb-douglas utility function
       set temp-utility ( ( temp-tableware ^ alpha ) * ( temp-money ^ beta ) ) ;cobb-douglas utility function
    ]
  ]


  ;;;; step 2: if the utility is not increased for one of the agents, the trade is cancelled.

ask active-consumer [
    if temp-utility < utility [
     set deal 0
    ]
  ]

ask active-merchant [
     if temp-utility < utility [
       set deal 0
      ]
    ]


  ;;;; step 3: if the utility is increase for both agents, the trade goes through and holdings are updated.
if deal > 0 [
     ask active-consumer [
       set tableware temp-tableware
       set money temp-money
       set succesful-trades ( succesful-trades + 1 )
      ]


     ask active-merchant [
       set tableware temp-tableware
       set money temp-money
       set succesful-trades succesful-trades + 1
      ]

    conversate-trade-success
    update-price-list ;add price to list to save it, when trade is successful
    ]


  ;save the prices suggested in interactions that didn't end with a trade
  ;@ i want this for a plot. It still needs to be laid out so that it isn't plotted at every tick, but only when it's changed, ie. a new unsuccesful trade (x-coordinate = current tick and not x=1 -> x=2 osv)

  if deal = 0 [ ;@ this needs to be redone so that the set-negotiation-price doesn't run it all the time
    set unsuccesful-price price
    set recorded-time ( ticks )
    conversate-trade-failed
  ;print "no deal made - tick recorded:" print recorded-time
  ]

end



to print-trade-details

  if price-setting = "compare-all-price-settings" [
    stop]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;; output-prints ;;;;;;;;;;;;
  ;;; utility, success and quantity ;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  output-print (word "Price this round ended at " price ".")

  ;;; defining agents' change in utility given the ongoing trade

  ask active-consumer [
  let consumer-utility-difference ( temp-utility - utility )
    let merchant-utility-difference ( [temp-utility] of partner - [utility] of partner )


;;;; print-outputs depending on the success of the trade
    ;;;; if no trade happens, then calculate what the change in utility would've been given trade of 1x tableware
    if consumer-utility-difference < 0 or merchant-utility-difference < 0 or deal = 0 [
      ;; defining utility given 1x trade

      ask active-consumer [
      let one-trade-utility-consumer precision ( (  ( tableware + 1 ) ^ alpha ) * ( ( money - price ) ^ beta ) ) 2    ;a simple utility calculation given trade of 1x tableware
        let one-trade-utility-merchant precision ( (  ( [tableware] of partner - 1 ) ^ [alpha] of partner ) * ( ( ([money] of partner) + price ) ^ [beta] of partner ) ) 2 ;der må være en fejl her

      let one-trade-utility-difference-consumer precision ( one-trade-utility-consumer - utility ) 2
      let one-trade-utility-difference-merchant precision ( [one-trade-utility-merchant] of partner - [utility] of partner ) 2



      output-print (word "Unsuccesful. No trade was made." )
      output-print (word "Consumer utility would have changed with " ( one-trade-utility-difference-consumer ) " given trade with 1x of tableware.")
      output-print (word "Merchant utility would have changed with " ( one-trade-utility-difference-merchant ) " given trade with 1x of tableware.")
    ]
    ]


    ;herfra printer ikke. Kun når deal = 0.
    if deal = 1 [
      output-print (word "Successful trade! " deal "x of tableware was traded.")
      output-print (word "Consumer utility improved by " precision consumer-utility-difference 2 ". ")
      output-print (word "Merchant utility improved by "  precision merchant-utility-difference 2 ". ")
    ]

    if deal > 1 [
      output-print (word "Successful trade! " deal "x of tableware were traded.")
      output-print (word "Consumer utility improved by  " precision consumer-utility-difference 2 ". ")
      output-print (word "Merchant utility improved by  "  precision merchant-utility-difference 2 ". ")
    ]
  ]


End


to create-price-lists
  set price-list []
  set market-clearing-price-list []
  set equilibrium-price-list []
  set random-price-list []
  set negotiation-price-list []
  set price-offered-by []

end



to update-price-list


  ; in single price-setting conditions, save the agreed upon price in the list price-list
  ;  in multiple price-setting condition, save the agreed upon price in seperate lists depending on the type of price-setting used


  ifelse price-setting != "compare-all-price-settings"
  [
    set price-list fput price price-list
  ]


  ; when the active turtle-set has the trading-style market-clearing, save the agreed upon price in the list market-clearing-price-list
  ; else:
  [

    ask active-consumer with [trading-style = "market-clearing"] ;no list for market-clearing-people: apparently they don't trade in this condition
    [ set market-clearing-price-list fput price market-clearing-price-list ]


    ;print market-clearing-price-list
    ask active-consumer with [trading-style = "equilibrium"]
      [ set equilibrium-price-list fput price equilibrium-price-list ]


    ask active-consumer with [trading-style = "random"]
      [ set random-price-list fput price random-price-list ]

  ]

  ask active-consumer with [trading-style = "negotiation"]
  [set negotiation-price-list fput price negotiation-price-list
  ]


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
      ifelse tableware - tableware-broken-per-tick-consumers >= 0
      [    set tableware ( tableware - tableware-broken-per-tick-consumers ) ] ;we don't want negative holdings of tableware
      [ set tableware (tableware - tableware ) ]
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


to-report willing-to-trade?
report ( item 0 [offer] of consumers ) > 0 ;reports true if offer is more than 0
end


to-report report-offer-consumers
  ifelse ticks > 0

;;; reporter section ;;;
  [
  let quantity-offer floor ( item 0 [offer] of consumers )


 ifelse willing-to-trade?
  [report quantity-offer]
  [report "0   (not interested in buying)"]  ;only positive quantities are reported; if not, there is no chance of trading
  ; should the quantity value be added even when negative?
  ]

  ;;;; if the model has just been set up, keep this monitor blank
  [report " "] ;at the beginning, keep the monitor blank
end

to-report report-offer-merchants
  ifelse ticks > 0

  [
  let quantity-offer floor ( item 0 [ offer ] of merchants )


  ifelse willing-to-trade?
  [report quantity-offer]
  [report "0   (not interested in selling)"]
  ]

  [report " "]
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


;;@these reporters should only run in the compare-all condition

to-report mean-selling-price
if length price-list > 0 [
    report ( ( sum price-list ) / (length price-list ) )
  ]
end


; the following reporters are used only in the compare-all condition

to-report mean-market-clearing-price
  if length market-clearing-price-list > 0 [
report ( ( sum market-clearing-price-list ) / ( length market-clearing-price-list ) )
  ]
end


to-report mean-equilibrium-price
  if length equilibrium-price-list > 0 [
report ( ( sum equilibrium-price-list ) / ( length equilibrium-price-list ) )
  ]
end

to-report mean-random-price
  if length random-price-list > 0 [
report ( ( sum random-price-list ) / ( length random-price-list ) )
  ]
end


to-report total-money
report ( nr-money-merchants + nr-money-consumers )
end


to-report total-tableware
report ( nr-tableware-consumers + nr-tableware-merchants )
end

to-report frequency [an-item a-list]
    report length (filter [ i -> i = an-item] a-list)
end
@#$#@#$#@
GRAPHICS-WINDOW
460
10
897
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
0
0
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
224
261
325
321
money-merchants
50.0
1
0
Number

INPUTBOX
350
261
452
321
money-consumers
50.0
1
0
Number

INPUTBOX
223
199
325
259
tableware-merchants
50.0
1
0
Number

INPUTBOX
349
199
452
259
tableware-consumers
120.0
1
0
Number

BUTTON
11
87
74
120
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
77
87
140
120
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
1000.0
1
0
Number

SLIDER
193
113
321
146
alpha-merchants
alpha-merchants
0
0.9
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
336
110
463
143
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
217
85
345
113
Variables for the merchant breed
11
0.0
1

TEXTBOX
356
79
479
107
Variables for the consumer breed\n
11
0.0
1

MONITOR
844
452
894
497
price
precision report-price 2
17
1
11

MONITOR
1074
83
1230
128
NIL
report-mrs-merchants
17
1
11

MONITOR
920
82
1075
127
NIL
report-mrs-consumers
17
1
11

CHOOSER
8
126
188
171
price-setting
price-setting
"market-clearing" "equilibrium" "random" "negotiation" "compare-all-price-settings"
4

MONITOR
195
150
324
195
Beta for merchants
report-beta-merchants
17
1
11

MONITOR
336
147
462
192
Beta for consumers
report-beta-consumers
17
1
11

MONITOR
1081
22
1245
67
NIL
report-offer-merchants
17
1
11

MONITOR
903
24
1079
69
NIL
report-offer-consumers
17
1
11

MONITOR
934
164
1046
209
merchant-tableware
round ( nr-tableware-merchants )
17
1
11

MONITOR
951
210
1046
255
merchant-money
nr-money-merchants
17
1
11

MONITOR
1047
163
1168
208
consumer-tableware
round ( nr-tableware-consumers )
17
1
11

MONITOR
1048
211
1153
256
consumer-money
nr-money-consumers
17
1
11

MONITOR
718
452
840
497
NIL
nr-succesful-trades
17
1
11

SWITCH
14
486
378
519
dynamics?
dynamics?
1
1
-1000

SWITCH
16
543
208
576
consumers-earn-money?
consumers-earn-money?
1
1
-1000

SWITCH
14
579
194
612
tableware-production?
tableware-production?
1
1
-1000

SWITCH
14
618
199
651
tableware-breakage?
tableware-breakage?
1
1
-1000

MONITOR
1179
166
1264
211
total-tableware
round ( total-tableware )
17
1
11

SLIDER
198
580
433
613
tableware-produced-per-tick
tableware-produced-per-tick
0
20
1.2
0.1
1
NIL
HORIZONTAL

SLIDER
211
542
383
575
salary-daily
salary-daily
0
20
3.0
1
1
NIL
HORIZONTAL

MONITOR
1182
215
1251
260
total-money
round ( total-money )
17
1
11

TEXTBOX
997
150
1101
168
CURRENT HOLDINGS
11
0.0
1

TEXTBOX
966
10
1186
38
Most recent offer (quantity to buy/ sell)
11
0.0
1

TEXTBOX
961
69
1197
97
Current marginal rate of substitution (MRS)
11
0.0
1

TEXTBOX
732
532
908
560
Most recent price of tableware
11
0.0
1

PLOT
897
440
1283
651
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
"mean" 1.0 0 -14985354 true "" "if price-setting != \"compare-all-price-settings\" [\nplot mean-price ]"
"latest random" 1.0 0 -14439633 true "" "if price-setting = \"compare-all-price-settings\" [\n;if length random-price-list > 0 [\nplot item 0 random-price-list\n]\n;]"
"latest equilibrium" 1.0 0 -4079321 true "" "if price-setting = \"compare-all-price-settings\" [\n;if length equilibrium-price-list > 0 [\nplot item 0 equilibrium-price-list\n]\n;]"
"latest market-clearing" 1.0 0 -5298144 true "" "if price-setting = \"compare-all-price-settings\" [\n;if length market-clearing-price-list > 0 [\nplot item 0 market-clearing-price-list\n]\n;]"
"refused offer price" 1.0 2 -2139308 true "" "if recorded-time + 1 = ticks [\nplotxy recorded-time unsuccesful-price\n]\n;now just needs to be adjusted to plot alongside the current price\n; so xcor = ticks"
"latest negotiation" 1.0 0 -7500403 true "" "if price-setting = \"compare-all-price-settings\" [\n;if length negotiation-price-list > 0 [\nplot item 0 negotiation-price-list\n]\n;]"

SLIDER
205
618
435
651
tableware-broken-per-tick-consumers
tableware-broken-per-tick-consumers
0
10
0.4
0.1
1
NIL
HORIZONTAL

CHOOSER
9
176
189
221
quantity-options
quantity-options
"standard" "one tableware at a time"
0

MONITOR
889
686
1039
731
Market Clearing
precision mean-market-clearing-price 2
17
1
11

OUTPUT
455
502
892
619
13

SLIDER
459
448
583
481
running-speed
running-speed
0
1
0.0
0.1
1
NIL
HORIZONTAL

TEXTBOX
893
731
1263
759
missing: monitor only prices from succesful trades
11
0.0
1

TEXTBOX
893
655
1320
683
                               Average price of tableware per succesful trade\nMarket clearing                                    Equilibrium                                           Random
11
0.0
1

MONITOR
1073
683
1156
728
Equilibrium
precision mean-equilibrium-price 2
17
1
11

MONITOR
1262
683
1326
728
Random
precision mean-random-price 2
17
1
11

PLOT
898
278
1268
438
Current holdings
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
"consumers tableware" 1.0 0 -2674135 true "" "plot nr-tableware-consumers"
"merchants tableware" 1.0 0 -955883 true "" "plot nr-tableware-merchants"
"consumers money" 1.0 0 -6459832 true "" "plot nr-money-consumers"
"merchants money" 1.0 0 -1184463 true "" "plot nr-money-merchants"

TEXTBOX
1137
149
1201
168
Consumer
11
0.0
1

TEXTBOX
911
149
984
167
Merchant
11
0.0
1

SLIDER
5
385
177
418
pxcor-merchant
pxcor-merchant
0
16
16.0
1
1
NIL
HORIZONTAL

SLIDER
7
420
179
453
pxcor-shared
pxcor-shared
-16
16
1.0
1
1
NIL
HORIZONTAL

SLIDER
5
350
177
383
pxcor-consumer
pxcor-consumer
-16
0
-8.0
1
1
NIL
HORIZONTAL

TEXTBOX
24
316
174
344
temporary sliders to allocate plabels:
11
0.0
1

MONITOR
228
364
353
409
NIL
utility-merchants
17
1
11

MONITOR
229
411
353
456
NIL
utility-consumers
17
1
11

TEXTBOX
1239
91
1389
168
@question: nicer to have mrs in the other direction for merchants? ie. tableware for money. More easily comparable/ possible to see from beginning, if the wishes of the two agents match
9
0.0
1

PLOT
897
275
1308
446
Demand and Supply Plot
Price Temporary
Tableware
0.0
0.0
0.0
0.0
false
true
"" ""
PENS

MONITOR
1316
295
1399
340
NIL
total-supply
17
1
11

MONITOR
1315
341
1402
386
NIL
total-demand
17
1
11

PLOT
1289
27
1489
177
plot 1
ticks/ time
price per item
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -7500403 true "" "if item 0 price-offered-by = \"no deal\" [plot item 0 negotiation-price-list]"
"pen-2" 1.0 0 -2674135 true "" ";if price-setting = \"negotiation\" [\n;plot item 0 price-list]"

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
