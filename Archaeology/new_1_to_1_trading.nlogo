globals [
  price-list
  market-clearing-price-list
  equilibrium-price-list
  random-price-list
  negotiation-price-list
  price-offered-by

  active-trading-style ;used for active-traders in compare-all

  price

  global-difference-list
  total-supply-list
  total-demand-list
  price-check-list

  deal-tableware
  suggested-quantity

  succesful-trades
  successful-trade?
  unsuccessful-price
  recorded-time

  bid-list ;for negotiation

  pot-wearout ;only for consumer
]

breed [merchants merchant]
breed [consumers consumer]

breed [buildings building] ;simply so akropolis isn't a prop :P
breed [props prop] ;just for layout
breed [banners banner] ;layout

turtles-own [
  trading-style
  alpha ;preference for tableware
  beta ;preference for money
  money
  tableware
  ;mrs ;marginal rate of substitution ;hvor mange penge er EN tallerken værd for mig? (neutralt/ligegyldigt punkt). Baseret på alpha, beta og current money og tableware.
  partner
  utility ;current utility
  offer-tableware ;used in decide-quantity
  temp-utility
]

props-own [prop-type]


to setup
  clear-all
  reset-ticks
  make-turtles price-setting ;tager price setting som input
  layout ;make the background + props
  ask traders [ set-partner ]
  ;ask traders [ update-mrs ]
  create-price-lists
  initiate-price-plot
  initiate-utility-plot
  if price-setting != "compare all price settings" [
    initiate-goods-plot
    update-goods-plot
  ]

  update-visuals
  ask (patch-set smiley-patch no-trade-patch) [set plabel "" ask props-here [die]] ;clear smiley and text when model is first set up (so no 'no trade! :(')
end


to go
  every .2 [
    trade
    print-details

    ;earn money and produce pots:
    ask consumers [set money (money + consumer-daily-earnings)]
    ask merchants [set tableware (tableware) + merchant-daily-pot-production]

    ;pot breakage (@FIX FOR COMPARE ALL?):

    set pot-wearout (pot-wearout + consumer-pot-breakage-per-day)
    let to-be-broken floor pot-wearout
    set pot-wearout pot-wearout - to-be-broken

    ask consumers [
      set tableware (tableware - to-be-broken)
      if tableware <= 0 [set tableware 0 set pot-wearout 0]
    ]


    ;tick

    update-visuals
    update-price-plot
    update-utility-plot
    if price-setting != "compare all price settings" [update-goods-plot] ;@there is code for compare all... but waaay too much - figure out what to show!

    tick
    ;ask turtles [ update-mrs ] ;only for some price-settings

  ]
end



to trade ;THE function run in go!
  if member? price-setting ["market clearing" "equilibrium" "random"] [
    set active-trading-style price-setting
    set-price                                ; step 2
    decide-quantity                          ; step 3
    check-utility-and-trade                  ; step 4
    ;print-trade-details @


  ]

  if price-setting = "negotiation" [
    set active-trading-style price-setting
    set-price
  ]

  if price-setting = "compare all price settings" [

    print "starting"
    foreach ["market clearing" "random" "negotiation"] [
      style ->
      print "here"
      print style
      set active-trading-style style

      set-price ;@include all

      if style != "negotiation" [ ;@@@
        decide-quantity
        check-utility-and-trade ;@remove from negotiation if included here
      ]

      ask active-merchant [ update-result-label ] ;doesn't matter if it's consumer or merchant
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

to-report temporary-demand [n] ;how many plates am I missing to have my optimal nr of plates
  let demandd (temporary-optimal n - tableware)
  report ifelse-value demandd > 0 [demandd] [0]
end

to-report temporary-supply [n] ;how many excess plates have I, more than my optimal holding (at this price)
  let supplyy (tableware - temporary-optimal n)
  report ifelse-value supplyy > 0 [supplyy] [0]
end


to set-price-mar ;market clearing. from set-price, run in trade
  set global-difference-list [] ;clear, initiate
  set total-supply-list []
  set total-demand-list []

  set price-check-list map [i -> precision i 2] (range 0.1 20.1 .1) ;listen ser sådan her ud: [0.1 0.2 0.3 0.4 ... 20]
    ;n is price-temporary, i.e. each element of this price-list^^

  ask traders with [ trading-style = "market clearing" ] [

    let list-supply (map [n -> temporary-supply n] price-check-list)
    ;Save every trader's supply list in a global / total list::
        ifelse length total-supply-list > 0 [
      set total-supply-list (map + list-supply total-supply-list) ;adding the two supply lists together - so it's the TOTAL supply
    ]
    [
      set total-supply-list list-supply ;First turtle cannot map as there is nothing in the total-supply-list initially
    ]

    let list-demand (map [n -> temporary-demand n] price-check-list)
    ;Save every trader's demand list in a global / total list::
        ifelse length total-demand-list > 0 [
      set total-demand-list (map + list-demand total-demand-list) ;adding the two demand lists together - so it's the TOTAL demand
    ]
    [
      set total-demand-list list-demand ;First turtle cannot map as there is nothing in the tota-supply-list initially
    ]

    ;lav ny liste med FORSKELLEN på de to:
    ;list-supply and list-demand: for one trader, one of them will always be 0 at every price! - while the other has an actual nr! (EITHER you have too many or too few!)

    ;show (word "my sup: " list-supply) show (word "my dem: " list-demand)

    let list-forskel (map + list-supply list-demand) ;adding supply and demand FOR THIS TRADER ONLY (so just results in whichever one of the lists has the nr)

    ifelse length global-difference-list > 0 [
      set global-difference-list (map - global-difference-list list-forskel) ;second trader runs this
      ;Minus, as we want to find where the difference is the lowest. HOWEVER, if there were more than 2 agents we'd need another solution@
    ]
    [
      set global-difference-list list-forskel ;den første turtle til at gøre det (kan ikke mappe på tom liste)
    ]
  ] ;END of ask traders (EACH trader runs all of the above!)

  set global-difference-list (map abs global-difference-list)
  ;print (word "glob dif list: " global-difference-list)

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
  if price-setting != "compare all price settings" [

    ;brug global demand og supply lister
    set-current-plot "Demand and Supply Plot"
    clear-plot
    set-plot-y-range 0.1 20 ;price
    let upper-bound ( money-merchants + money-consumers + pots-merchants + pots-consumers ) / 2
    set-plot-x-range 0 upper-bound
    ;set-plot-x-range 0 200 ;tableware
    ;plotxy price-check-list total-supply-list
    ;show total-supply-list
    ;show total-demand-list

    ;(map [[a b] -> plotxy a b] price-check-list total-supply-list)

    ;PLOT SUPPLY:
    create-temporary-plot-pen "supply"
    set-current-plot-pen "supply"
    set-plot-pen-color 15

    (foreach total-supply-list price-check-list ;@switched it around, now price on y axis
      [
        [x y] ->
        plotxy x y

    ])

    ;PLOT DEMAND:
    create-temporary-plot-pen "demand"
    set-current-plot-pen "demand"
    set-plot-pen-color 105

    (foreach total-demand-list price-check-list ;@switched it around, now price on y axis
      [
        [x y] ->
        plotxy x y

    ])

  ]

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

  let minMRS min [ my-mrs ] of active-traders ;defining lowest MRS
   let maxMRS max [ my-mrs ] of active-traders ;and highest MRS
    set price  minMRS + ( random ( 100 * ( maxMRS - minMRS ) ) / 100 ) ; because random produces integers

end


to set-price-neg ;trying to be smarter
  ;if no mrs (since no tableware), set mrs to 0:
  let mer-mrs ifelse-value ([my-mrs] of active-merchant = "no tableware left") [ 0 ] [ [my-mrs] of active-merchant ] ;if the string, make it 0
  let con-mrs ifelse-value ([my-mrs] of active-consumer = "no tableware left") [ 0 ] [ [my-mrs] of active-consumer ] ;if the string, make it 0

  let mrs-difference con-mrs - mer-mrs ;consumer mrs is always highest

  let bid-list-merchant (list
    mer-mrs
    con-mrs
    precision (mer-mrs + 0.2 * mrs-difference) 2
    precision (con-mrs - 0.2 * mrs-difference) 2
    precision (mer-mrs + 0.4 * mrs-difference) 2
    precision (con-mrs - 0.4 * mrs-difference) 2
    precision (con-mrs - 0.5 * mrs-difference) 2
  )

  let bid-list-consumer (list
    con-mrs
    mer-mrs
    precision (con-mrs - 0.2 * mrs-difference) 2
    precision (mer-mrs + 0.2 * mrs-difference) 2
    precision (con-mrs - 0.4 * mrs-difference) 2
    precision (mer-mrs + 0.4 * mrs-difference) 2
    precision (con-mrs - 0.5 * mrs-difference) 2
  )

  set bid-list one-of list bid-list-consumer bid-list-merchant ;random who starts the bidding
  ;print bid-list
  set successful-trade? false ;reset before loop di doop

  foreach bid-list [
    bid ->
    if not successful-trade? [
      set price bid
      decide-quantity
      check-utility-and-trade ;this is where success-this-tick? is set

      print-details ;@why print twice??? :O
    ]
  ]





end


to set-price-neg-old ;negotiation. from set-price, run in trade

  let initial-bidder one-of active-traders ;randomly decides who opens the negotiation
  let second-bidder [partner] of initial-bidder

  ask initial-bidder [

    ;;;; round 1:
    print "round 1"
    set price my-mrs
    decide-quantity
    ;possible to make an ifelse about deal-tableware here already to save computing
    check-utility-and-trade ;write out the outputs. No interesting until the deal-tableware actually pulls through
    ifelse deal-tableware > 0 [
      if price-setting = "compare all price settings" [stop]
      output-print ( word "Offer 1 made by " ( [ breed ] of initial-bidder ) " accepted.")
      stop ] ;if the bid is accepted, exit this function


    [
      ;;;; else, start round 2:
      ;if the first deal-tableware is not accepted, partner suggests its mrs instead and the trading evaluation runs again
      print "round 2"
      set price [my-mrs] of partner
      decide-quantity
      check-utility-and-trade
      ifelse deal-tableware > 0 [
        if price-setting = "compare all price settings" [stop]
        output-print ( word "Offer 2 made by " [ breed ] of second-bidder " accepted." )
        stop]


      [
        ;;;; else, start round 3:
        print "round 3"
        ;agent1 now gets to set the price again. This time she sets it according to the principle: My optimal price + 20% of the price difference between the intial two offers
        let mrs-price-difference ( my-mrs - [my-mrs] of partner ) ;might be a positive or negative number - that is great for these calculations
        set price my-mrs + (mrs-price-difference * 0.2 ) ;this could also be the bid of the other agent depending on whether the mrs-difference is a positive or negative. In practice shouldn't matter
        decide-quantity
        check-utility-and-trade
        ifelse deal-tableware > 0 [
          if price-setting = "compare all price settings" [stop]
          output-print ( word "Offer 3 made by " [ breed ] of initial-bidder " accepted.")
          stop]

        [
          ;;;; else, start round 4:
          print "round 4"
          ; agent2 does the same
          set price ( [my-mrs] of partner + mrs-price-difference * 0.2 ) ;oops, for the merchant subtraction is needed. How can we do this smart?
          decide-quantity
          check-utility-and-trade
          ifelse deal-tableware > 0 [
            if price-setting = "compare all price settings" [stop]
            output-print ( word "Offer 4 made by " [ breed ] of second-bidder " accepted." )
            stop]

          [
            ;;; round 5, agent 1 with 40%
            print "round 5"
            set price my-mrs + (mrs-price-difference * 0.4 )
            decide-quantity
            check-utility-and-trade
            ifelse deal-tableware > 0 [
              if price-setting = "compare all price settings" [stop]
              output-print ( word "Offer 5 made by " [ breed ] of initial-bidder " accepted." )
              stop]

            [
              ; round 6, agent2 does the same
              print "round 6"
              set price ( [my-mrs] of partner + mrs-price-difference * 0.4 )
              decide-quantity
              check-utility-and-trade
              ifelse deal-tableware > 0 [
                if price-setting = "compare all price settings" [stop]
                output-print ( word "Offer 6 made by " [ breed ] of second-bidder  " accepted." )
                stop ]


              [
                ;final round - agent1 offers to meet halfway. If this is a no-deal, there will be no trade.
                print "round 7 (final)"
                set price my-mrs + mrs-price-difference * 0.5
                decide-quantity
                check-utility-and-trade
                if deal-tableware > 0
                [if price-setting = "compare all price settings" [stop]
                  output-print "Agents met halfway between their initial prices." ]
                if deal-tableware = 0
                [ if price-setting = "compare all price settings" [stop]
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


to decide-quantity
  ;;;; given my a) current holding, b) the set price and c) my preferences (alpha and beta),
  ;;;; how many pieces of tableware do I wish to trade this round?
  ;print (word "--- " price-setting " ---")
  ;print (word "price: " price)
  ask active-consumer [ ;@PROBLEMS START HERE (at least for random)
    ifelse  price = 0 [
      set offer-tableware 0 ;undgå ulovlig division. Vi kan assume at offer-tableware er 0 hvis pris er 0, idet agenter aldrig vil give væk gratis ("more is always better" -economy)
    ]
    ; if price not 0:
    [
      let budget (tableware * price ) + money  ;calculating budget based on tableware owned and price-setting and current holding of money. Price is retrieved from previous price-setting functions
      let optimal round (budget * alpha / price)  ;optimal number of tableware to HOLD given the current price
      set offer-tableware floor ( optimal - tableware )  ;offer-tableware to buy the number of tableware optimal with current holding subtracted (floor = integers rounded down)
      if offer-tableware * price > money [set offer-tableware floor ( money / price ) ] ;ensures that the consumer never offers more tableware than they can afford - instead offers the max they can afford
    ]
  ]

  ask active-merchant [
    ifelse price = 0 [
      set offer-tableware 0
    ]
    [
      let budget ( tableware * price ) + money
      let optimal ( budget * alpha / price )
      set offer-tableware floor ( tableware - optimal ) ;floor = integer rounded down
      if offer-tableware > tableware [ set offer-tableware tableware ] ; ensures that the merchant won't offer more than it currently has in its holding (can at most sell all the tableware they have)
    ]
  ]

  ;the deal-tableware is set to the lowest offer (amount of tableware):
  ;print (word "offer-tableware of C: " ([offer-tableware] of active-consumer) )
  ;print ( word "offer-tableware of M: " ([offer-tableware] of active-merchant) )

  ;show list ([offer-tableware] of active-merchant) ([offer-tableware] of active-consumer)
  set deal-tableware min list ([offer-tableware] of active-merchant) ([offer-tableware] of active-consumer) ;the min of the two offers
  if deal-tableware <= 0 [ set deal-tableware max list ([offer-tableware] of active-merchant) ([offer-tableware] of active-consumer) ] ;if <0, choose the other offer
  if deal-tableware < 0 [set deal-tableware 0] ;if still 0, set it to 0

  ;make sure consumer can afford it (if consumer's offer was negative, and merchant's was chosen - which consumer hasn't checked yet):
  if deal-tableware * price > [money] of active-consumer [
    set deal-tableware floor ( ([money] of active-consumer) / price )
  ]
  ;and likewise make sure merchant actually has the tableware! (if consumer's offer is chosen):
  if deal-tableware > [tableware] of active-merchant [
    set deal-tableware [tableware] of active-merchant
  ]

  set suggested-quantity deal-tableware ;redundant, but just adding for printing (still saved if it doesn't go through in next step)

end

to check-utility-and-trade ;@maybe make this a turtle procedure instead??? (doesn't work in set-price-neg right now)
  ;easier variable name:
  let deal-money ( deal-tableware * price )

  ; step 1: calculating the change in utility for each agent given the planned trade
  ; @lisa: there is some problematic calculations going on with the ^s. (???)
  ask active-traders [ ;merchant and consumer both do this
    set temp-utility 0 ;reset

      ifelse breed = merchants [
        let temp-tableware ( tableware - deal-tableware ) ;tableware is turtles-own
        let temp-money ( money + deal-money ) ;same for money
      ;print (word "M temp table: " temp-tableware )
      ;print (word "M temp money: " temp-money )
        set temp-utility precision ( ( temp-tableware ^ alpha ) * ( temp-money ^ beta ) ) 2 ;cobb-douglas utility
      ]
      [ ;consumer:
        let temp-tableware ( tableware + deal-tableware ) ;tableware is turtles-own
        let temp-money ( money - deal-money ) ;same for money
      ;print (word "C temp table: " temp-tableware )
      ;print (word "C temp money: " temp-money )
        set temp-utility precision ( ( temp-tableware ^ alpha ) * ( temp-money ^ beta ) ) 2 ;cobb-douglas utility
      ]
      ;show temp-utility
  ]

  ; step 2: if the utility would be decreased for any of the agents, the trade is cancelled.
  ifelse any? active-traders with [temp-utility < my-utility] [ ;@ida: ændrede det fra utility til my-utility
    set deal-tableware 0
  ]
  [
    set succesful-trades succesful-trades + 1
  ]

  ;; step 3: if the utility is increased for both agents, the trade goes through and holdings are updated.
  if deal-tableware > 0 [
    ask active-consumer [
      set tableware (tableware + deal-tableware) ;(@assumes it's always this way around, and roles aren't reversed - check!)
      set money (money - deal-money)
      set utility temp-utility ;@WE WANT TO ADD THIS HERE, RIGHT?! ;now using my-utility instead...
    ]

    ask active-merchant [
      set tableware (tableware - deal-tableware)
      set money (money + deal-money)
      set utility temp-utility ;@WE WANT TO ADD THIS HERE, RIGHT?! ;now using my-utility instead...
    ]
    update-price-list ;add price to list to save it, when trade is successful
  ]

  ;record if deal or no deal and stuff
  ifelse deal-tableware = 0 [
    set unsuccessful-price price
    set recorded-time ( ticks )
    set successful-trade? false
  ]
  [ ;if a deal:
    set successful-trade? true
  ]
end


to print-details

  ifelse deal-tableware > 0 [
    output-print (word "Agreed price: " precision price 2 "." )
    output-print (word "Amount traded: " deal-tableware "." )

    ask traders [output-print (word "My utility (" breed "): " my-utility )]
  ]
  [
    output-print (word "Suggested price: " precision price 2 ". Suggested amount: " suggested-quantity ".")
    output-print (word "Utilities would have become: " item 0 [temp-utility] of consumers " (c) & " item 0 [temp-utility] of merchants " (m)")
    ;ask traders [output-print (word "Utility would have become(" breed "): " temp-utility )]
    ]
end

to-report traders ;doesn't include akropolis ;)
  report (turtle-set merchants consumers)
end

to-report trader-patches ;for easier relative layouting of props
  report patches with [any? consumers-here or any? merchants-here]
end


to update-price-list ;run in check-utility-and-trade
  ifelse price-setting != "compare all price settings" [
    set price-list fput price price-list
  ]
  [ ;if compare all:
    print "ooone"
    ask active-consumer [
      if trading-style = "market clearing" [ set market-clearing-price-list fput price market-clearing-price-list ]
      if trading-style = "random" [set random-price-list fput price random-price-list]
      if trading-style = "negotiation" [set negotiation-price-list fput price negotiation-price-list]

    ]
    print "twooo"

  ]
end


to-report active-traders ;the ones currently trading
  ifelse price-setting = "compare all price settings" [
    report traders with [trading-style = active-trading-style]
  ]
  [
    report traders
  ]
end

to-report active-merchant
    report one-of active-traders with [breed = merchants]
end

to-report active-consumer
    report one-of active-traders with [breed = consumers]
end


;to update-mrs ;MOVED TO REPORTER INSTEAD!
;  ifelse tableware = 0 [
;    set mrs "no tableware left"
;  ]
;  [
;    set mrs precision ( (alpha * money) / (beta * tableware) ) 3
;  ]
;end




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

to initiate-utility-plot
  set-current-plot "Utility over time"
  set-plot-x-range -1 ticks

  ifelse price-setting = "compare all price settings" [

    create-temporary-plot-pen "Con mar" set-plot-pen-color red - 1
    plotxy -1 [my-utility] of one-of consumers with [trading-style = "market clearing"]
    create-temporary-plot-pen "Mer mar" set-plot-pen-color red + 1
    plotxy -1 [my-utility] of one-of merchants with [trading-style = "market clearing"]
    create-temporary-plot-pen "Con ran" set-plot-pen-color green - 1
    plotxy -1 [my-utility] of one-of consumers with [trading-style = "random"]
    create-temporary-plot-pen "Mer ran" set-plot-pen-color green + 1
    plotxy -1 [my-utility] of one-of merchants with [trading-style = "random"]
    create-temporary-plot-pen "Con neg" set-plot-pen-color violet - 1
    plotxy -1 [my-utility] of one-of consumers with [trading-style = "negotiation"]
    create-temporary-plot-pen "Mer neg" set-plot-pen-color violet + 1
    plotxy -1 [my-utility] of one-of merchants with [trading-style = "negotiation"]
  ]
  [
    create-temporary-plot-pen "Consumer" set-plot-pen-color blue
    create-temporary-plot-pen "Merchant" set-plot-pen-color orange
  ]

end

to update-utility-plot
  set-current-plot "Utility over time"

  ifelse price-setting = "compare all price settings" [
   set-current-plot-pen "Con mar" plotxy ticks [my-utility] of one-of consumers with [trading-style = "market clearing"]
   set-current-plot-pen "Mer mar" plotxy ticks [my-utility] of one-of merchants with [trading-style = "market clearing"]
   set-current-plot-pen "Con ran" plotxy ticks [my-utility] of one-of consumers with [trading-style = "random"]
   set-current-plot-pen "Mer ran" plotxy ticks [my-utility] of one-of merchants with [trading-style = "random"]
   set-current-plot-pen "Con neg" plotxy ticks [my-utility] of one-of consumers with [trading-style = "negotiation"]
   set-current-plot-pen "Mer neg" plotxy ticks [my-utility] of one-of merchants with [trading-style = "negotiation"]
  ]
  [ ;if not compare all:
    set-current-plot-pen "Consumer" plotxy ticks [my-utility] of one-of consumers with [trading-style = price-setting]
    set-current-plot-pen "Merchant" plotxy ticks [my-utility] of one-of merchants with [trading-style = price-setting]
  ]


end



to initiate-price-plot ;run in setup
  set-current-plot "Price plot"
  set-plot-x-range -1 ticks
  ;set-plot-y-range 0 3

  ifelse price-setting = "compare all price settings" [

    create-temporary-plot-pen "Market-clearing success" set-plot-pen-color red
    plotxy -1 0
    create-temporary-plot-pen "Random success" set-plot-pen-color green
    plotxy -1 0
    create-temporary-plot-pen "Negotiation success" set-plot-pen-color violet
    plotxy -1 0
  ]

  [ ;if not compare all:
    create-temporary-plot-pen "Price trade successful"
    set-plot-pen-color green

    ;@FIGURE OUT HOW TO BEST VISUALISE - LINES, DOTS, ETC !!! (change dot size???)

;    create-temporary-plot-pen "Price trade unsuccessful"
;    set-plot-pen-color red

;    create-temporary-plot-pen "Mean price successful trades" ;kvantitet?
;    ;@could make rolling window?
;    set-plot-pen-color blue
  ]
end

to initiate-goods-plot
  set-current-plot "Money & pots over time"

  ifelse price-setting = "compare all price settings" [
    create-temporary-plot-pen "Mer money mar" set-plot-pen-color red + 3
    create-temporary-plot-pen "Mer pots mar" set-plot-pen-color red + 1
    create-temporary-plot-pen "Con money mar" set-plot-pen-color red - 1
    create-temporary-plot-pen "Con pots mar" set-plot-pen-color red - 3

    create-temporary-plot-pen "Mer money ran" set-plot-pen-color green + 3
    create-temporary-plot-pen "Mer pots ran" set-plot-pen-color green + 1
    create-temporary-plot-pen "Con money ran" set-plot-pen-color green - 1
    create-temporary-plot-pen "Con pots ran" set-plot-pen-color green - 3

    create-temporary-plot-pen "Mer money neg" set-plot-pen-color violet + 3
    create-temporary-plot-pen "Mer pots neg" set-plot-pen-color violet + 1
    create-temporary-plot-pen "Con money neg" set-plot-pen-color violet - 1
    create-temporary-plot-pen "Con pots neg" set-plot-pen-color violet - 3
  ]

  [ ;if not compare all:
    create-temporary-plot-pen "Mer money" set-plot-pen-color orange
    create-temporary-plot-pen "Mer pots" set-plot-pen-color brown - 2
    create-temporary-plot-pen "Con money" set-plot-pen-color yellow
    create-temporary-plot-pen "Con pots" set-plot-pen-color brown + 1
  ]
end

to update-goods-plot
  set-current-plot "Money & pots over time"

  ifelse price-setting = "compare all price settings" [
    set-current-plot-pen "Mer money mar" plotxy ticks [money] of one-of merchants with [trading-style = "market clearing"]
    set-current-plot-pen "Mer pots mar" plotxy ticks [tableware] of one-of merchants with [trading-style = "market clearing"]
    set-current-plot-pen "Con money mar" plotxy ticks [money] of one-of consumers with [trading-style = "market clearing"]
    set-current-plot-pen "Con pots mar" plotxy ticks [tableware] of one-of consumers with [trading-style = "market clearing"]

    set-current-plot-pen "Mer money ran" plotxy ticks [money] of one-of merchants with [trading-style = "random"]
    set-current-plot-pen "Mer pots ran" plotxy ticks [tableware] of one-of merchants with [trading-style = "random"]
    set-current-plot-pen "Con money ran" plotxy ticks [money] of one-of consumers with [trading-style = "random"]
    set-current-plot-pen "Con pots ran" plotxy ticks [tableware] of one-of consumers with [trading-style = "random"]

    set-current-plot-pen "Mer money neg" plotxy ticks [money] of one-of merchants with [trading-style = "negotiation"]
    set-current-plot-pen "Mer pots neg" plotxy ticks [tableware] of one-of merchants with [trading-style = "negotiation"]
    set-current-plot-pen "Con money neg" plotxy ticks [money] of one-of consumers with [trading-style = "negotiation"]
    set-current-plot-pen "Con pots neg" plotxy ticks [tableware] of one-of consumers with [trading-style = "negotiation"]


  ]
  [
    set-current-plot-pen "Mer money" plotxy ticks [money] of active-merchant
    set-current-plot-pen "Mer pots" plotxy ticks [tableware] of active-merchant
    set-current-plot-pen "Con money" plotxy ticks [money] of active-consumer
    set-current-plot-pen "Con pots" plotxy ticks [tableware] of active-consumer


  ]

end

to update-price-plot
  ;@ADD: make a dot every time, either red or green (change size?) (instead of plot lines?)

  set-current-plot "Price plot"

  ifelse price-setting = "compare all price settings" [
    ;set-plot-x-range -1 ticks

    if length market-clearing-price-list > 0 [
      set-current-plot-pen "Market-clearing success"
      ;plotxy ticks (mean market-clearing-price-list)
      if successful-trade? [
        plotxy ticks (first market-clearing-price-list)
      ]
    ]

    if length random-price-list > 0 [
      set-current-plot-pen "Random success"
      ;plotxy ticks (mean random-price-list)
      if successful-trade? [
        plotxy ticks (first random-price-list)
      ]
    ]

    if length negotiation-price-list > 0 [
      set-current-plot-pen "Negotiation success"
      ;plotxy ticks (mean negotiation-price-list)
      if successful-trade? [
        plotxy ticks (first negotiation-price-list)
      ]
    ]

  ]
  [ ;if not compare all:
    if length price-list > 0 [ ;if it even exists
      if (max price-list > 3) [ set-plot-y-range 0 (round (max price-list) + 0.5)] ;maybe udvid the y akse
    ]


    ifelse successful-trade? [
      set-current-plot-pen "Price trade successful"
      plotxy ticks (first price-list) ;x and y, using custom function for big dots
    ]
    [
;      set-current-plot-pen "Price trade unsuccessful"
;      plotxy ticks unsuccessful-price ;x and y
    ]

    ;plot mean:
;    set-current-plot-pen "Mean price successful trades"
;    if mean-price != "no price list" [plotxy ticks mean-price]

  ]

  ;2 i 1 approach:
  ;    set-current-plot-pen "Price trade"
;    ifelse successful-trade? [
;      set-plot-pen-color green
;      plotxy ticks (first price-list) ;plot latest successful price
;    ]
;    [
;      set-plot-pen-color red
;      plotxy ticks unsuccessful-price
;    ]
end

to-report mean-price ;used in update-price-plot
  ifelse length price-list > 0 [
    report ( ( sum price-list ) / ( length price-list ) )
  ]
  [
    report "no price list"
  ]
end



;---TRADER REPORTERS

to-report my-utility ;turtle reporter ;current utility
  ; Cobb-Douglas utility function ;;;copied from red cross parcels model
  ;As i understand the utility hereby is a measure of the total quantity of tableware and money, modified by the alpha and betas. Meaning that the weight of money+tableware is modified by the alphas + betas.
  ;in short, an individual utility function dependant on alphas and betas.
  report precision ( ( tableware ^ alpha ) * ( money ^ beta ) ) 2
end

to-report my-mrs ;trader reporter
  ifelse tableware = 0 [ ;can not divide by 0!
    ;report "no tableware left"
    report precision ( (alpha * money) / (beta * 1) ) 2 ;pretend they have one pot if they don't have any
  ]
  [
    report precision ( (alpha * money) / (beta * tableware) ) 2
  ]
end


;---LAYOUT STUFF


to layout ;run in setup ;sets up the world/background
  ifelse price-setting = "compare all price settings" [
    ask patches [
      set pcolor 9 ;light grey background
      ;sky:
      if pycor > 33 [set pcolor blue - 1.5] ;top
      if pycor > (min-pycor + 45) and pycor < (min-pycor + 53) [set pcolor blue - 1.5] ;middle
      if pycor > (min-pycor + 19) and pycor < (min-pycor + 28) [set pcolor blue - 1.5] ;bottom
      ;lighter sky:
      if pycor > 34 [set pcolor blue - 1] ;top
      if pycor > (min-pycor + 46) and pycor < (min-pycor + 53) [set pcolor blue - 1] ;middle
      if pycor > (min-pycor + 20) and pycor < (min-pycor + 28) [set pcolor blue - 1] ;bottom
      ;lightest sky:
      ;if pycor > 38 [set pcolor blue] ;top
      ;if pycor > (min-pycor + 51) and pycor < (min-pycor + 53) [set pcolor blue] ;middle
      ;if pycor > (min-pycor + 25) and pycor < (min-pycor + 28) [set pcolor blue] ;bottom
      ;'horizon'/shadows of condition bars:
      ;if pycor = (min-pycor + 46) [set pcolor 1]

      ;bars for condition tags:
      if pycor > (min-pycor + 52) and pycor < (min-pycor + 56) [set pcolor 7] ;market clearing
      if pycor > (min-pycor + 25) and pycor < (min-pycor + 29) [set pcolor 7] ;random
      if pycor < (min-pycor + 3) [set pcolor 7] ;negotiation
      ;if pycor

      ;condition tags:
      if pxcor = 7 and pycor = (min-pycor + 54) [set plabel "market clearing" set plabel-color black]
      if pxcor = 3 and pycor = (min-pycor + 27) [set plabel "random" set plabel-color black]
      if pxcor = 5 and pycor = (min-pycor + 1) [set plabel "negotiation" set plabel-color black]
    ]
  ]
  [ ;IF NOT COMPARE ALL:
    ask patches [
      if pycor < (max-pycor - 50) [set pcolor 9] ;ground
      if pycor = (max-pycor - 50) [set pcolor 1] ;horizon line
      if pycor < (min-pycor + 6) [set pcolor 7] ;bottom line for label

      ;sky (bottom to top colors):
      if pycor > (max-pycor - 50) [set pcolor blue - 1.5]
      if pycor > (max-pycor - 30) [set pcolor blue - 1]
      if pycor > (max-pycor - 20) [set pcolor blue]
      if pycor > (max-pycor - 10) [set pcolor blue + 1]

      ;condition tag
      if pxcor = 7 and pycor = (min-pycor + 2) [set plabel price-setting set plabel-color black]

    ]
    ;akropolis
    create-buildings 1 [
     set shape "building institution" set size 18 set color white setxy 0 -7
    ]




  ]

  update-visuals

end

to update-visuals ;in visual interface
  ask (patch-set no-trade-patch trade-patch) [set plabel ""]

  ask banners [set label ""]
  ask props [ask in-link-neighbors [set label ""]]
  ask props [die] ;easy fix

  ask trader-patches [
    ;pot counter
    sprout-props 1 [
      set shape "pot" set color 35.5 set size 7 set heading 270 fd 13 set heading 180 fd 6 set heading 0 fd 9.5 set prop-type "plate"
      attach-banner precision ([tableware] of min-one-of traders [distance myself]) 2 ;@added precision
    ]
    ;money counter
    sprout-props 1 [
      set shape "coins" set size 9 set heading 270 fd 13 set heading 180 fd 6 set heading 0 fd 5 set prop-type "coins"
      attach-banner precision ([money] of min-one-of traders [distance myself]) 2 ;@added precision
    ]

    ;utility counter
    sprout-props 1 [
      set shape "u-shape" set size 5 set color blue set heading 270 fd 13 set heading 180 fd 7 set heading 0 fd 2 set prop-type "utility"
      attach-banner precision ([my-utility] of min-one-of traders [distance myself]) 2 ;@added precision
    ]

    ;utility smileys
;    sprout-props 1 [
;      let emotion [utility-emotion] of min-one-of traders [distance myself]
;      let index position emotion ["sad" "neutral" "happy"]
;      set shape item index ["face sad" "face neutral" "face happy"]
;      set color item index [red yellow green]
;      set size 4
;      set prop-type "smiley"
;      set heading 0 fd 4.25
;    ]

    ;MRS
    sprout-props 1 [
      set prop-type "mrs"
      set size 0
      set heading 3 fd 8
      set label "MRS:"
      set label-color black
      attach-banner ([my-mrs] of min-one-of traders [distance myself])
    ]


  ]

  ;trade or no trade label

  if price-setting != "compare all price settings" [
    ifelse deal-tableware > 0 [
      ask trade-patch [
        ;set plabel-color green - 1.5
        set plabel-color white
        let pot-or-pots ifelse-value deal-tableware = 1 ["pot"] ["pots"]
        set plabel (word "We trade " deal-tableware " " pot-or-pots ". Price for each: " precision price 2 ". " )
      ]
      ask smiley-patch [
        sprout-props 1 [  set shape "face happy" set color (green - 1) set size 4 set heading 0]
      ]

    ]
    [ ;if no trade:
      ask no-trade-patch [
        set plabel-color white
        ;set plabel-color red - 1.5
        set plabel "NO TRADE!"
      ]
      ask smiley-patch [
        sprout-props 1 [  set shape "face sad" set color (red - 1) set size 4 set heading 0]
      ]
    ]
  ]
end

to update-result-label ;trader procedure! used in compare all
  ;figure out where, based on my trading style
  let index position trading-style ["market clearing" "random" "negotiation"]
  let my-trade-patch item index (list patch 21 37 patch 21 9 patch 21 -17)
  let my-no-trade-patch item index (list patch 6 37 patch 6 9 patch 6 -17)
  let my-smiley-patch item index (list patch 0 33 patch 0 5 patch 0 -22)
  ask (patch-set my-trade-patch my-no-trade-patch) [set plabel ""] ;clear
  ask my-smiley-patch [ask buildings-here [die]] ;clear smileys

  ifelse deal-tableware > 0 [
    ask my-trade-patch [
      set plabel-color [color] of active-merchant
      set plabel-color white
      set plabel (word "We trade " deal-tableware " pots. Price for each: " precision price 2 ". " )
      ]
    ask my-smiley-patch [
      sprout-buildings 1 [set shape "face happy" set color (green - 1) set size 4 set heading 0] ;buildings so they don't get killed in update-visuals... ;)
      ]

    ]
    [ ;if no trade:
      ask my-no-trade-patch [
        set plabel-color [color] of active-merchant
        set plabel-color white
        set plabel "NO TRADE!"
      ]
      ask my-smiley-patch [
        sprout-buildings 1 [  set shape "face sad" set color (red - 1) set size 4 set heading 0]
      ]
    ]



end

to-report no-trade-patch
  report patch 6 4
end
to-report trade-patch ;not for compare all
    report patch 21 4
end
to-report smiley-patch
  report patch 0 8
end

;to-report utility-emotion ;trader reporter
;  ;@figure out cutoffs - does it even make sense?
;  if my-utility < 25 [report "sad"]
;  if my-utility >= 25 and my-utility < 75 [report "neutral"]
;  if my-utility >= 75 [report "happy"]
;end

to attach-banner [x]  ;turtle procedure. for label positioning
  ask in-link-neighbors [die] ;recreates them every time

  ifelse prop-type = "mrs" [
    hatch-banners 1 [
      set size 0
      set label-color black
      set label x
      create-link-from myself [
        tie
        hide-link
      ]
      let l length (word x)
      if l > 15 [set label "-" set l 1] ;if for example tableware=0 so mrs = "no tableware left"
      let angle 90
      let dist item l ["zero" 2 3 4 5.5 6.5 7.5 8.5 9.5] ;for label length 1, 2, 3, 4, 5, 6 ...
      reposition angle dist
    ]
  ]
  [ ;if prop type isn't mrs (so one of the three icons instead):
    hatch-banners 1 [
      set size 0
      set label-color black
      set label x
      create-link-from myself [
        tie
        hide-link
      ]
      ;determine label position (plates & money) based on label length
      let l length (word x) ;label length
      let angle item l ["zero" 95 93 92 93 93 93 93 93 93 93 93 93 93 93 93 93 93 93 93 93 93 93] ;for label length 1, 2, 3, 4, 5, 6 ...
      let dist item l ["zero" 4 5.5 6.5 7.5 8.5 9.5 9.5 9.5 9.5 9.5 9.5 9.5 9.5 9.5 9.5 9.5 9.5 9.5 9.5 9.5] ;for label length 1, 2, 3, 4, 5, 6 ...
                                                     ;95 4, 93 5.5, 93 6.5, 93 7.5, 93 8.5

      ;let angle banner-angle
      ;let dist banner-distance
      reposition angle dist
    ]
  ]


end

to reposition [angle dist]  ; banner procedure
  move-to one-of in-link-neighbors
  set heading angle
  fd dist

  ;set heading banner-angle
  ;fd banner-distance
end


to make-turtles [kind] ;run in setup
  ifelse kind = "compare all price settings" [
    ;if compare all:

    ;MARKET CLEARING
    create-consumers 1 [
      set color (my-color "market clearing") + 1.5
      setxy (min-pxcor + dist-side + 2)(min-pycor + dist-bottom + 48)
      set shape "person"
      set heading 270
      set size 12
      set alpha alpha-consumers
      set beta precision ( 1 - alpha-consumers ) 3
      set money money-consumers
      set tableware pots-consumers
      set trading-style "market clearing"
    ]
    create-merchants 1 [
      set color (my-color "market clearing") - 1.5
      setxy (max-pxcor - dist-side + 2) (min-pycor + dist-bottom + 48)
      set trading-style "market clearing"
      set shape "person-holding"
      set size 12
      set heading 90
      set alpha alpha-merchants
      set beta precision ( 1 - alpha-merchants ) 3
      set money money-merchants
      set tableware pots-merchants
      ;pot in merchant's hand (just layout):
      hatch-buildings 1 [
        set shape "pot" set size 8.5 set color 35.5
        set heading 90 fd 4.5
        set heading 0 fd 4.5
      ]
    ]

    ;RANDOM
    create-consumers 1 [
      set color (my-color "random") + 1.5
      setxy (min-pxcor + dist-side + 2)(min-pycor + dist-bottom + 21)
      set shape "person"
      set heading 270
      set size 12
      set alpha alpha-consumers
      set beta precision ( 1 - alpha-consumers ) 3
      set money money-consumers
      set tableware pots-consumers
      set trading-style "random"
    ]
    create-merchants 1 [
      set color (my-color "random") - 1.5
      setxy (max-pxcor - dist-side + 2) (min-pycor + dist-bottom + 21)
      set trading-style "random"
      set shape "person-holding"
      set size 12
      set heading 90
      set alpha alpha-merchants
      set beta precision ( 1 - alpha-merchants ) 3
      set money money-merchants
      set tableware pots-merchants
      ;pot in merchant's hand (just layout):
      hatch-buildings 1 [
        set shape "pot" set size 8.5 set color 35.5
        set heading 90 fd 4.5
        set heading 0 fd 4.5
      ]
    ]

    ;NEGOTIATION
    create-consumers 1 [
      set color (my-color "negotiation") + 1.5
      setxy (min-pxcor + dist-side + 2) (min-pycor + dist-bottom - 5) ;@check position
      set shape "person"
      set heading 270
      set size 12
      set alpha alpha-consumers
      set beta precision ( 1 - alpha-consumers ) 3
      set money money-consumers
      set tableware pots-consumers
      set trading-style "negotiation"
    ]
    create-merchants 1 [
      set color (my-color "negotiation") - 1.5
      setxy (max-pxcor - dist-side + 2) (min-pycor + dist-bottom - 5)
      set trading-style "negotiation"
      set shape "person-holding"
      set size 12
      set heading 90
      set alpha alpha-merchants
      set beta precision ( 1 - alpha-merchants ) 3
      set money money-merchants
      set tableware pots-merchants
      ;pot in merchant's hand (just layout):
      hatch-buildings 1 [
        set shape "pot" set size 8.5 set color 35.5
        set heading 90 fd 4.5
        set heading 0 fd 4.5
      ]
    ]



  ]
  [ ;if not compare all:

    create-consumers 1 [
      set color (my-color kind) + 1.5
      setxy (min-pxcor + dist-side)(min-pycor + dist-bottom) ;@check position
      set shape "person"
      set heading 270
      set size 12
      set alpha alpha-consumers
      set beta precision ( 1 - alpha-consumers ) 3
      set money money-consumers
      set tableware pots-consumers
      set trading-style kind
    ]

    create-merchants 1 [
      set color (my-color kind) - 1.5
      setxy (max-pxcor - dist-side) (min-pycor + dist-bottom)
      set trading-style kind
      set shape "person-holding"
      set size 12
      set heading 90

      set alpha alpha-merchants
      set beta precision ( 1 - alpha-merchants ) 3
      set money money-merchants
      set tableware pots-merchants

      ;pot in merchant's hand (just layout):
      hatch-buildings 1 [
        set shape "pot" set size 8.5 set color 35.5
        set heading 90 fd 4.5
        set heading 0 fd 4.5
      ]

    ]




  ]


end

to-report dist-side ;for turtle placement
  report 15
end
to-report dist-bottom ;for turtle placement
  report 14
end

to-report my-color [kind] ;from make-turtles. input = trading style
  let index position kind ["market clearing" "equilibrium" "random" "negotiation"]

  report item index [red blue green violet]
end

to-report frequency [an-item a-list]
    report length (filter [ i -> i = an-item] a-list)
end
@#$#@#$#@
GRAPHICS-WINDOW
395
10
883
499
-1
-1
5.93
1
15
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
10
15
375
60
price-setting
price-setting
"market clearing" "random" "negotiation" "compare all price settings"
3

SLIDER
10
65
190
98
alpha-consumers
alpha-consumers
0.5
0.9
0.9
0.1
1
NIL
HORIZONTAL

SLIDER
10
135
190
168
pots-consumers
pots-consumers
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
195
65
375
98
alpha-merchants
alpha-merchants
0.1
0.4
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
195
135
375
168
pots-merchants
pots-merchants
0
100
50.0
1
1
NIL
HORIZONTAL

BUTTON
10
175
190
208
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
195
175
280
208
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

SLIDER
195
100
375
133
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
10
100
190
133
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
930
395
1460
620
Demand and Supply Plot
Pots
Price
0.0
0.0
0.0
0.0
false
true
"" ""
PENS

PLOT
930
205
1460
395
Price plot
Time
Price per pot
0.0
0.0
0.0
0.0
true
true
"" ""
PENS

OUTPUT
395
500
885
585
13

SLIDER
15
280
320
313
consumer-daily-earnings
consumer-daily-earnings
0
20
0.0
1
1
NIL
HORIZONTAL

SLIDER
15
320
320
353
merchant-daily-pot-production
merchant-daily-pot-production
0
20
0.0
1
1
NIL
HORIZONTAL

SLIDER
15
360
320
393
consumer-pot-breakage-per-day
consumer-pot-breakage-per-day
0
10
0.0
0.1
1
NIL
HORIZONTAL

PLOT
930
10
1460
200
Money & pots over time
Time
Amount
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

BUTTON
290
175
375
208
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

TEXTBOX
15
230
320
251
Dynamics
18
0.0
1

TEXTBOX
15
255
390
275
Try changing these parameters while the model is running.
13
0.0
1

PLOT
15
405
385
585
Utility over time
Time
Utility
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

TEXTBOX
420
585
895
625
(text output to be deleted - unless we find it useful for something?)
14
0.0
1

TEXTBOX
65
590
355
616
(does a plot of utility over time make sense???)
13
0.0
1

TEXTBOX
955
625
1265
676
Demand & Supply plot: ONLY for Market Clearing
14
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

bee 2
true
0
Polygon -1184463 true false 195 150 105 150 90 165 90 225 105 270 135 300 165 300 195 270 210 225 210 165 195 150
Rectangle -16777216 true false 90 165 212 185
Polygon -16777216 true false 90 207 90 226 210 226 210 207
Polygon -16777216 true false 103 266 198 266 203 246 96 246
Polygon -6459832 true false 120 150 105 135 105 75 120 60 180 60 195 75 195 135 180 150
Polygon -6459832 true false 150 15 120 30 120 60 180 60 180 30
Circle -16777216 true false 105 30 30
Circle -16777216 true false 165 30 30
Polygon -7500403 true true 120 90 75 105 15 90 30 75 120 75
Polygon -16777216 false false 120 75 30 75 15 90 75 105 120 90
Polygon -7500403 true true 180 75 180 90 225 105 285 90 270 75
Polygon -16777216 false false 180 75 270 75 285 90 225 105 180 90
Polygon -7500403 true true 180 75 180 90 195 105 240 195 270 210 285 210 285 150 255 105
Polygon -16777216 false false 180 75 255 105 285 150 285 210 270 210 240 195 195 105 180 90
Polygon -7500403 true true 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 false false 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 true false 135 300 165 300 180 285 120 285

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

cloud
false
0
Circle -7500403 true true 13 118 94
Circle -7500403 true true 86 101 127
Circle -7500403 true true 51 51 108
Circle -7500403 true true 118 43 95
Circle -7500403 true true 158 68 134

coins
false
6
Circle -1184463 true false 99 114 42
Circle -1184463 true false 144 88 42
Circle -1184463 true false 144 144 42
Circle -16777216 false false 99 114 42
Circle -16777216 false false 144 88 42
Circle -16777216 false false 144 144 42

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

person-holding
false
14
Circle -16777216 true true 110 5 80
Polygon -16777216 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -16777216 true true 127 79 172 94
Polygon -16777216 true true 171 109 231 64 261 79 186 139
Polygon -16777216 true true 105 90 60 150 75 180 135 105

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

plate-round
true
1
Circle -1 true false 75 75 150
Circle -7500403 false false 75 75 150
Circle -7500403 false false 85 85 128

plate-standing
true
1
Rectangle -1 true false 111 135 180 150
Rectangle -7500403 false false 110 135 180 150

pot
true
0
Polygon -16777216 true false 180 75 120 75 150 105 180 75 165 75
Polygon -7500403 true true 120 210 90 180 90 120 120 105 180 105 210 120 210 180 180 210
Polygon -7500403 true true 150 90 120 75 120 135 180 135 180 75
Polygon -7500403 true true 195 120 225 105 240 120 240 165 210 180 210 165 225 150 225 120 210 135 210 120
Polygon -7500403 true true 105 120 75 105 60 120 60 165 90 180 90 165 75 150 75 120 90 135 90 120

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
14
Circle -16777216 true true 110 5 80
Polygon -16777216 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -16777216 true true 127 79 172 94
Polygon -16777216 true true 171 109 231 64 261 79 186 139
Polygon -16777216 true true 105 90 60 150 75 180 135 105
Circle -1 true false 205 14 76
Circle -7500403 false false 215 24 56
Circle -7500403 false false 216 25 54
Circle -7500403 false false 205 13 78

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

u-shape
false
0
Polygon -7500403 true true 150 195 105 195 90 150 90 45 120 45 120 150 120 165 150 165 180 165 180 150 180 45 210 45 210 150 195 195

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
