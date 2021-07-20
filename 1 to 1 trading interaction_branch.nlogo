globals [
  price
  price-temporary
  deal
  succesful-trades
  price-list
  market-clearing-price-list
  equilibrium-price-list
  random-price-list
  temp-closest-to-market-clearing
  total-demand
  total-supply
  active-merchant
  active-consumer
  active-turtles
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
   conversate

end


to go

  trade

  produce-tableware
  break-tableware
  earn-money
  update-price-list
  update-mrs

  check-supply-demand ;@remove later. only to see if supply and demand is as we wish
  set-total-demand-supply


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
  repeat 1 [ make-market-clearing-ppls "merchants"]
  repeat 1 [ make-market-clearing-ppls "consumers"]
  ]


  if price-setting = "equilibrium"
  [
  repeat 1 [ make-equilibrium-ppls "merchants"]
  repeat 1 [ make-equilibrium-ppls "consumers"]
  ]


  if price-setting = "random"
  [
  repeat 1 [ make-random-ppls "merchants"]
  repeat 1 [ make-random-ppls "consumers"]
  ]


  if price-setting = "compare-all-price-settings"
  [
  repeat 1 [ make-market-clearing-ppls "merchants"]
  repeat 1 [ make-market-clearing-ppls "consumers"]
   repeat 1 [ make-equilibrium-ppls "merchants"]
  repeat 1 [ make-equilibrium-ppls "consumers"]
   repeat 1 [ make-random-ppls "merchants"]
  repeat 1 [ make-random-ppls "consumers"]
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

  if fill-screen? and price-setting != "compare-all-price-settings" [ ;;; different formats
    ask wanted [
      set size 8
    ]
    ask merchants [
      setxy 10 -11
    ]
    ask consumers [
      setxy -10 -11
    ]
  ]

end



to make-market-clearing-ppls [kind]
  if kind = "merchants" [
    create-merchants 1 [
      set color red - 1
      setxy 10 8.5
      set trading-style "market-clearing"
  ]
  ]


  if kind = "consumers" [
    create-consumers 1 [
      set color red + 1.5
      setxy -10 8.5
      set trading-style "market-clearing"
  ]
  ]

end


to make-equilibrium-ppls [kind]

   if kind = "merchants" [
   create-merchants 1 [
   set color yellow - 1
   setxy 10 -2.5
   set trading-style "equilibrium"
  ]
  ]

  if kind = "consumers" [
   create-consumers 1 [
      set color yellow + 1.5
      setxy -10 -2.5
      set trading-style "equilibrium"
  ]
  ]
end


to make-random-ppls [kind]
  if kind = "merchants" [
   create-merchants 1 [
   set color green - 1
   setxy 10 -12.5
      set trading-style "random"

  ]
  ]

  if kind = "consumers" [
   create-consumers 1 [
      set color green + 1.5
      setxy -10 -12.5
      set trading-style "random"
  ]
  ]
end



to layout

  ask patches [set pcolor blue]


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;; full-screen option here ;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;;; in this setting, when a non-multiple price-setting option is chosen, the display is fit for just two agents - with no different colors


  if fill-screen? and price-setting != "compare-all-price-settings" [


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;; @ fun layout, such as ancient Greece style ;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      ask patches with [pycor < 15] [set pcolor blue - 0.5]
  ask patches with [pycor < 9] [set pcolor blue - 1]

  create-turtles 1
  ask turtles
  [set shape "building institution" ;make it acropolis
    set size 8
    setxy 0 12
    set color white]


   ; putting a visual tag to show the condition
    ask patch 1 -16 [set plabel price-setting set pcolor blue]
       ask patches with [pycor = -16] [set pcolor blue - 1.5 ]

  ]




  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;; no-fill-screen option here ;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;; this is the layout so far, with the three conditions having a slot of space in the display each.

if price-setting = "compare-all-price-settings" or not fill-screen? [


if price-setting = "market-clearing" or price-setting = "compare-all-price-settings" [

ask patch 3 5
[set plabel "Market clearing"]

  ask patches with [pycor > 4 ] [set pcolor blue + 1]
  ask patches with [pycor = 5 ] [set pcolor blue + 0.5]
  ]


  if price-setting = "equilibrium" or price-setting = "compare-all-price-settings" [
    ask patch 2 -6
    [set plabel "Equilibrium" ]

      ask patches with [pycor = -6] [set pcolor blue - 1.5 ]
  ]


if price-setting = "random" or price-setting = "compare-all-price-settings" [
  ask patch 1 -16
[set plabel "Random"

   ask patches with [pycor < -6 ] [set pcolor blue - 1 ]
  ask patches with [pycor = -16] [set pcolor blue - 2.5 ]
    ]
  ]

  ]

end


to conversate

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
  let shared-talk2 patch pxcor-shared -1 ;utility


;@actual values still need to be added

  if price-setting = "equilibrium" [
    ask c-talk1 [set plabel "my ideal price is"]
    ask m-talk1 [set plabel "my ideal price is"]
    ask shared-talk2  [set plabel "this will be the price" ]


    ask c-talk2  [set plabel "i want to buy this amount" ]
    ask m-talk2  [set plabel "i want to sell this amount" ]
    ask shared-talk2  [set plabel "we trade this amount" ]



    ask c-talk3  [set plabel "utility changed by :)" ]
    ask m-talk3  [set plabel "utility changed by :)" ]

    ]


  if price-setting = "random" [
    ask c-talk1 [set plabel "i want to trade at the rate (mrs)"]
    ask m-talk1 [set plabel "i want to trade at the rate (mrs)"]
    ask shared-talk2  [set plabel "we pick a price at random between our mrs" ]


    ask c-talk2  [set plabel "then i want to buy no more than x tableware" ]
    ask m-talk2  [set plabel "i want to sell no more than x tableware" ]
    ask shared-talk2  [set plabel "so we trade x tableware" ]



    ask c-talk3  [set plabel "utility changed by :)" ]
    ask m-talk3  [set plabel "utility changed by :)" ]

  ]





  ;;;; here we make the interaction visible in the display ;;;;;

if fill-screen? [
  ;if price-setting = "equilibrium"
  ;  [ ask patches with [ pxcor = pxcor-consumer ] and [ pycor = slot1 ]
   ;   [set plabel "my price is"]



      ;pxcor-merchant
      ; pxcor-agreement
     ;



    ]

end



;MRS beregninger med basis i bogen
;Cudos to   chap5 edgeworth box game.
  ;   set mrsCapt ( alphaCapt * captsCigs )  / ( ( 1 - alphaCapt ) * captsChocs )
  ;   set mrsSgt  ( alphaSgt * sgtsCigs  )  / ( ( 1 - alphaSgt ) *  sgtsChocs )


to update-mrs ;@@lisa: skal fikses når tableware = 0
ask merchants [
    if tableware = 0 [set mrs "no tableware left" stop]
    let nr ( alpha-merchants * money )  / ( beta * tableware )
    let rounded precision nr 3
    set mrs rounded
  ]


ask consumers [
   ; if tableware = 0 [set mrs "no tableware left" stop] ;@@lisa: ikke færdig løsning! En mulighed er at sætte en place-holder table-ware = 1
    if tableware = 0 [set mrs ( alpha-consumers * money ) / ( beta * 1 ) stop ] ;not rounded

    let nr ( alpha-consumers * money )  / ( beta * tableware )
    let rounded precision nr 3
    set mrs rounded

]

end


to set-partner
  ask consumers [
    set partner one-of merchants with [ trading-style = [ trading-style ] of self ] ] ; partner skal have samme trading-style som mig selv


  ask consumers [
   ask partner [
      set partner myself
    ]
  ]
end





to check-supply-demand ;remove this when set-market-clearing-price is a go. Otherwise we overwrite values
 ; @interferes with compare-all-prices-settings. Made a temporary switch so I can test more easily.


  ifelse check-supply-demand?
  [

  ask turtles [
      set temp-budget ( tableware * price ) + money ;essentially how much your total capital (tableware and money) is worth in money.
      set  optimal-tableware round ( temp-budget * alpha / price ) ;
      ;if optimal-tableware < 1  [
      ; set optimal-tableware 1
      ;]


;      set demand ( optimal-tableware - tableware )
;      if demand < 0 [
;        set supply abs demand ;
;        set demand 0
;      ]



      set demand ( optimal-tableware - tableware )
      if demand < 0 [
        set demand 0
      ]


      set supply ( tableware - optimal-tableware )
      if supply < 0 [
        set supply 0
      ]
   ] ;ask turtles end
  ]

  [
  ]

end


to set-total-demand-supply
  set total-demand 0
  set total-supply 0

  ask turtles [
   set total-demand total-demand + demand
   set total-supply total-supply + supply
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

  ]


  if price-setting = "equilibrium" [
    activate-equilibrium-turtles
    set-equilibrium-price
    decide-quantity
    check-utility-and-trade
  ]


  if price-setting = "random" [
    activate-random-turtles
    set-random-price
    decide-quantity
    check-utility-and-trade
  ]


  if price-setting = "compare-all-price-setting" [ ;just like the rest of them, but all of the above bundled together

;    activate-market-clearing-turtles
;    set-market-clearing-price
;    decide-quantity
;    check-utility-and-trade



    activate-equilibrium-turtles
    set-equilibrium-price
    decide-quantity
    check-utility-and-trade


    activate-random-turtles
    set-random-price
    decide-quantity
    check-utility-and-trade

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



to set-market-clearing-price

  ;;;;;;; The price where quantity demanded is equal to the quantity supplied
  ;;;;;;; No shortage or surplus exists in the market

set price-temporary 0.1
set temp-closest-to-market-clearing total-tableware

repeat 200 [
    ask active-turtles [
      set temp-budget ( tableware * price-temporary ) + money ;essentially how much your total capital (tableware and money) is worth in money.
      set  optimal-tableware round ( temp-budget * alpha / price-temporary ) ;
      ;if optimal-tableware < 1  [
      ; set optimal-tableware 1
      ;]
      set demand ( optimal-tableware - tableware )
      if demand < 0 [
        set demand 0
      ]

      set supply ( tableware - optimal-tableware )
      if supply < 0 [
        set supply 0
      ]
    ] ;ask turtles end



    ;
    if abs ( total-demand - total-supply ) < temp-closest-to-market-clearing [ ;On repeat 1 we initiate if statement when neither demand nor supply exceeds the total-tableware.
    set temp-closest-to-market-clearing ( total-demand - total-supply ) ;we update if we have a smaller total difference between supply and demand. in the end we will have the smallest possible difference (given constraints)
    set price precision price-temporary 2

    ]

    set price-temporary price-temporary + 0.1 ;if it takes a long time to run, we can update price inside the above if statement. However this seems to introduce a possible local minimum in difference btw supply and demand

  ] ;repeat 200 end


set market-clearing-price-list fput price market-clearing-price-list ;adding the price to a list - and yes, we're only interested in the final price.
  ;@lisa . I don't really understand the list stuff u made. Does this price "update" only need to be put into the list as
  ;the "final" market clearing price has been calculated? (as it is now)


  ;;;;;;;;;;;;;;;;;;;
  ;; output-prints ;;
  ;;;;;;;;;;;;;;;;;;;

  ;@ what outputs would we like?
  ; Probably an indifference plot

end



to set-equilibrium-price

 ;;;;;;;;;;;;;;;; Equilibrium ;;;;;;;;;;;;;;;;;;
; equilibrium sets the price as the  mean between the two agents' optimal prices
; the underlying assumption from economy is that negotiating will even prices out over time - and that both are equally good at negotiating
; based on equilibrum from the red cross parcel

  ask active-consumer [
     set price  precision (
                           ( ( alpha * tableware ) + [ alpha * tableware ] of partner )  /
                           ( ( beta * money ) + [ beta  * money ] of partner ) )    2 ]

  ;updating price-list
Set equilibrium-price-list fput price equilibrium-price-list ;adding the latest price - currently regardless of whether it's used succesfully or not


   ;;;;;;;;;;;;;;;;;;;
  ;; output-prints ;;
  ;;;;;;;;;;;;;;;;;;;

  ask active-consumer [
  let merchant-optimal-price ( alpha * tableware ) / ( beta * money )
  let consumer-optimal-price ( [ alpha * tableware ] of partner / [ beta  * money ] of partner ) ;@lisa: passer det her virkelig? Skal lige kigges efter.


    output-print (word "Consumer price " precision consumer-optimal-price 2 ". " )
    output-print (word "Merchant price " precision merchant-optimal-price 2 ". " )
    output-print (word "Midway meeting point " price ". " )
  ]
end



To set-random-price
  ;;;; we establish which trading rates each agent would like, and then pick a price at random in this interval
  ;;;; the underlying assumption is that over time, the prices will even out that both agents get a fair price
  ;;; furthermore, the price will play a role in how many items are traded


  let minMRS min [ mrs ] of active-turtles ;defining lowest MRS
   let maxMRS max [ mrs ] of active-turtles ;and highest MRS
    set price  minMRS + ( random ( 100 * ( maxMRS - minMRS ) ) / 100 ) ; because random produces integers


Set random-price-list fput price random-price-list

  ;;;;;;;;;;;;;;;;;;;
  ;; output-prints ;;
  ;;;;;;;;;;;;;;;;;;;


  output-print (word "Lowest MRS " precision minMRS 2 ". " )
  output-print (word "Highest MRS " precision maxMRS 2 ". " ) ;is there a smarter way to change the line than putting a new command?
  output-print (word "Random price in between " precision price 2 ". " )

End




To decide-quantity

calculate-utility


  ;;; step 1:
  ;;;; given my a) current holding, b) the set price and c) my preferences (alpha and beta),
  ;;;; how many pieces of tableware do I wish to trade this round?

ask active-consumer [
    let budget (tableware * price ) + money  ;calculating budget based on tableware owned and price-setting and current holding of money. Price is retrieved from previous price-setting functions
    let optimal round (budget * alpha / price)  ;optimal number of tableware to HOLD given the current price
    set offer precision ( optimal - tableware ) 2  ;offer to buy the number of tableware optimal with current holding subtracted
  ]


  ask active-merchant [
    let budget ( tableware * price ) + money
    let optimal ( budget * alpha / price )
    set offer precision ( tableware - optimal ) 2
    if offer > tableware [ set offer tableware ] ; ensures that the merchant won't offer more than it currently has in its holding (can at most sell all the tableware they have)
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
;
;  ask active-turtles
;  [ set deal-money deal-tableware * price ] ;money exchange in deal

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
     set temp-utility precision ( ( temp-tableware ^ alpha ) * ( temp-money ^ beta ) ) 2 ;cobb-douglas utility function
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
    ]


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;; output-prints ;;;;;;;;;;;;
  ;;; utility, success and quantity ;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;;; defining agents' change in utility given the trade

  ask active-consumer [
  let consumer-utility-difference ( temp-utility - utility )
    let merchant-utility-difference ( [temp-utility] of partner - [utility] of partner )


;;;; print-outputs depending on the success of the trade
    if consumer-utility-difference < 0 or merchant-utility-difference < 0 or deal = 0 [
      output-print (word "Unsuccesful. No trade was made." )
      output-print (word "Consumer utility would have changed with " precision ( consumer-utility-difference ) 2 " given trade with " deal "x of tableware.") ;@måske indstil givet handel med 1x
      output-print (word "Merchant utility would have changed with "  precision ( consumer-utility-difference ) 2 " given trade with " deal "x of tableware.")
    ]

    if deal = 1
    [output-print (word "Successful trade! " deal "x of tableware was traded.")
      output-print (word "Consumer utility improved by " precision consumer-utility-difference 2 ". ")
      output-print (word "Merchant utility improved by "  precision merchant-utility-difference 2 ". ")
    ]

    if deal > 1
    [output-print (word "Successful trade! " deal "x of tableware were traded.")
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
end



to update-price-list
  set price-list fput price price-list
  if price-setting = "random"
  [set price-list random-price-list]
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

to-report total-supplyy
  report total-supply
end

to-report total-demandd
  report total-demand
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
  let quantity-offer floor ( item 0 [offer] of consumers )


 ifelse willing-to-trade?
  [report quantity-offer]
  [report "0   (not interested in buying)"]  ;only positive quantities are reported; if not, there is no chance of trading
  ; should the quantity value be added even when negative?
end

to-report report-offer-merchants
  let quantity-offer floor ( item 0 [ offer ] of merchants )


  ifelse willing-to-trade?
  [report quantity-offer]
  [report "0   (not interested in selling)"]
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

to-report mean-market-clearing-price ;@@lisa: still missing to count succesful only + amount
  set price-list market-clearing-price-list
  if length price-list > 0 [
report ( ( sum price-list ) / ( length price-list ) )
  ]
end


to-report mean-equilibrium-price
  set price-list equilibrium-price-list
  if length price-list > 0 [
report ( ( sum price-list ) / ( length price-list ) )
  ]
end

to-report mean-random-price
  set price-list random-price-list
  if length price-list > 0 [
report ( ( sum price-list ) / ( length price-list ) )
  ]
end


to-report total-money
report ( nr-money-merchants + nr-money-consumers )
end


to-report total-tableware
report ( nr-tableware-consumers + nr-tableware-merchants )
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
199
320
259
money-merchants
50.0
1
0
Number

INPUTBOX
358
196
460
256
money-consumers
50.0
1
0
Number

INPUTBOX
219
263
321
323
tableware-merchants
50.0
1
0
Number

INPUTBOX
359
259
462
319
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
113
321
146
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
336
110
463
143
alpha-consumers
alpha-consumers
0
0.9
0.7
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
1073
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
"market-clearing" "equilibrium" "random" "compare-all-price-settings"
2

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
951
192
1089
237
merchant-tableware
round ( nr-tableware-merchants )
17
1
11

MONITOR
1071
192
1191
237
merchant-money
nr-money-merchants
17
1
11

MONITOR
951
146
1072
191
consumer-tableware
round ( nr-tableware-consumers )
17
1
11

MONITOR
1072
146
1192
191
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
0
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
968
238
1074
283
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
1.0
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
1.0
1
1
NIL
HORIZONTAL

MONITOR
1074
238
1163
283
total-money
round ( total-money )
17
1
11

TEXTBOX
1025
131
1175
149
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
"mean" 1.0 0 -5298144 true "" "plot mean-price"
"equilibrium" 1.0 2 -14454117 true "" "if equilibrium-price > 0 [\nplot equilibrium-price ]"
"random" 1.0 0 -13840069 true "" "if random-price > 0 [\nplot random-price]"
"Market clearing" 1.0 0 -1184463 true "" "if market-clearing-price > 0 [\nplot market-clearing-price]"

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
1

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
0.7
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
"total tableware" 1.0 0 -16777216 true "" "plot total-tableware"
"total money" 1.0 0 -7500403 true "" "plot total-money"
"consumers tableware" 1.0 0 -2674135 true "" "plot nr-tableware-consumers"
"merchants tableware" 1.0 0 -955883 true "" "plot nr-tableware-merchants"
"consumers money" 1.0 0 -6459832 true "" "plot nr-money-consumers"
"merchants money" 1.0 0 -1184463 true "" "plot nr-money-merchants"

TEXTBOX
955
131
1011
149
Tableware
11
0.0
1

TEXTBOX
1155
130
1228
148
Money
11
0.0
1

MONITOR
1250
160
1329
205
NIL
total-supply
17
1
11

MONITOR
1249
206
1336
251
NIL
total-demand
17
1
11

SWITCH
148
13
274
46
fill-screen?
fill-screen?
0
1
-1000

SWITCH
138
51
288
84
check-supply-demand?
check-supply-demand?
1
1
-1000

SLIDER
44
320
216
353
pxcor-consumer
pxcor-consumer
-16
0
-7.0
1
1
NIL
HORIZONTAL

SLIDER
51
371
223
404
pxcor-merchant
pxcor-merchant
0
16
13.0
1
1
NIL
HORIZONTAL

SLIDER
57
427
229
460
pxcor-shared
pxcor-shared
-5
5
3.0
1
1
NIL
HORIZONTAL

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
