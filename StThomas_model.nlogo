extensions [fetch import-a csv table]

globals [
  wals-list
  header-list
  lang-list
  feature-list
  wals-table

  color-list ;;for plotting

  sea-patches
  land-patches

  time
  month-names

  chosen-table ;;table: keys = WALS features, entries = lists of ALL the values chosen (speaker or hearer) (no distinguishing between ticks/turns, just one long list for each feature)
  agreement ;;nested list with entry for each tick, counting successes and fails for each turn
  success-count ;;total cumulative count
  fail-count ;;total cumulative count
  fails-this-tick
  successes-this-tick
]

breed [plantations plantation]
breed [colonists colonist]
breed [slaves slave]

slaves-own [
  start-lang ;;starting language (ID code)
  start-lang-vec ;;vector with the feature values for their starting language @maybe doesn't need to be saved? although maybe for later comparison...
  my-lang-table ;;their language table! 50 entries, one for each WALS feature. Each entry is a nested list of their known values for this feature + associated odds
]

colonists-own [
  start-lang
  start-lang-vec
  my-lang-table
]



to setup
  clear-all
  reset-ticks

  ;;create the map:
  ;;import-pcolors "stthomas.png"

  import-img ;;function that fetches the image online
  initialize-map ;coloring functions do not apply in Netlogo Web, although they function if I run them elsewhere, e.g. directly in Command Center or in the go-procedure
                 ; "ERROR. ITEM expected input to be a string or list but got the number 0 instead."

  ;;get the data files and initialize variables:
  import-csv ;;gets WALS data from url, makes it into a table
  initialize-variables ;;moved down to its own procedure so setup isn't too cluttered

  ;;layout the world:
  create-plantations 10 [
    set color white set shape "house" set size 6
    move-to one-of land-patches ;;@randomly placed right now
  ]

  populate ;;create starting population
  update-feature-plot
end


to initialize-variables ;;run in setup
  set month-names ["Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"] ;either start in dec or jan. If starting jan we have tick 1 = feb. Does it matter though?
  set lang-list table:keys wals-table ;;list of all the language IDs
  set agreement [] ;;global list, gonna be a nested list storing counts of successes and fails in communication

  set chosen-table table:make ;;initialize the spoken-table:
  foreach feature-list [ ;;feature-list contains the 50 WALS feature names
    key -> ;;the WALS feature name - what we want to be the table key
    let value [] ;;values are now empty lists, will be filled with ALL values ever chosen (by speaker OR hearer) for that feature in a given run
    table:put chosen-table key value ;;table:put adds this key-value combination to the agent's table
  ]


  set color-list [0 16 106 56 44 115 26 84 6] ;;colors for plotting (ensures through indexin that the same value is always the same color)
end

to go
  set fails-this-tick 0 set successes-this-tick 0
  ask slaves [ communicate ] ;;procedure where agents talk to each other
  set agreement lput (list successes-this-tick fails-this-tick) agreement ;;nested list, each round updated with counts of successes and fails (nested list with the two totals)
  update-feature-plot
  set time ticks mod 12 ;;update time
  if year = 1940 [stop]

  tick
end


to populate ;;run in setup. Create starting population
  repeat nr-of-agents [ make-person (one-of lang-list) ] ;;random language
end


to make-person [language] ;;function that creates a person and takes their starting language ID as input to give them their language feature vector
  create-slaves 1 [
    set shape "person" set size 6 set color black
    set start-lang language
    set start-lang-vec table:get wals-table language ;;looks up their language in the wals-table and gives them the corresponding feature list

    initialize-my-table ;;creates their language table

    move-to one-of land-patches ;;@just random position right now
  ]
end

to communicate ;;agent procedure run in go
  ;;@example of simple communication using the custom table functions and procedures - we can always expand on this:
;;coded from the speaker's perspective (so every agent gets to be speaker every tick right now)

    ;;1. Speaker chooses a hearer
  let partner my-partner-choice ;;agent reporter
  ;;let partner one-of other slaves ;;partner is a turtles-own variable, it stores their conversation partner
                                    ;;@random now, i.e. the same agent can be hearer multiple times, or not at all, in any given round
                                    ;;@gem evt historie over hvem der har talt sammen?

    ;;2. Choose which WALS feature to exchange (the 'conversation topic')
    let chosen-feature one-of feature-list ;;randomly chosen right now (feature-list is a global variable with all 50 features)

    ;;3. Speaker retrieves a specific value/instance of this WALS feature from their language table (to begin with they only know one instance anyway)
    let speaker-input-list table:get my-lang-table chosen-feature ;;the nested list of known value-odds pairs associated with the WALS feature (e.g. [[0 2] [1 4] [2 1]]
    let speaker-value weighted-one-of speaker-input-list ;;weighted-one-of takes a nested pair list  ([[item odds] [item odds]]) and randomly picks an item based on their odds

    ;;4. Speaker asks hearer to retrieve a value for the WALS feature
    let hearer-value "NA" ;;placeholder to initiate value outside ask block
    ask partner [
      let hearer-input-list table:get my-lang-table chosen-feature
      set hearer-value weighted-one-of hearer-input-list ;;@OBS: how do we want to handle '?'-entries?! (not accounted for right now)
    ]

    ;;5. Compare the values to see if the communication was coordinated/succesful
    let success? "NA" ;;placeholder to initiate variable outside ifelse blocks
    ifelse speaker-value = hearer-value [ ;;@now simple binary decision understood/not understood - could add nuance somehow?
      set success? true
      set success-count success-count + 1 ;;total cumulative
      set successes-this-tick successes-this-tick + 1 ;;for plotting (and agreement list)
    ;;lav global liste ('agreement'), for hvert go laver vi ny liste, smider alle tingene ind - så det bliver en liste af lister
      ;;hver liste er success/failure for hvert tick
                                        ;ET tal per tick, en liste per tick. agreement = [[5 6] [2 5]]
    ]
    [
      set success? false
      set fail-count fail-count + 1 ;;total cumulative
      set fails-this-tick fails-this-tick + 1 ;;for plotting (and agreement list)
    ]

    ;;6. Speaker updates their language table depending on the outcome ;;@HOW DO WE WANT TO DO THIS?
    ifelse success? [
      increase-odds chosen-feature speaker-value ;;function increases the odds for this value of this feature (right now simply +1)
    ]
    [ ;;if unsuccessful, odds decrease:
      decrease-odds chosen-feature speaker-value ;;function decreases the odds (now simply -1, but never lower than 1...) ;;@add complete unlearning? but only if they know other values! hmmm...
    ]

    ;;7. Speaker asks hearer to update their language table ;;@HOW DO WE WANT TO DO THIS?
    ask partner [
      ifelse success? [
        increase-odds chosen-feature speaker-value ;;function increases the odds for this value of this feature (right now simply +1)
      ]
      [ ;;if unsuccessful communication:
        ifelse known-value? chosen-feature speaker-value [
          ;;hearer increases their odds if they already know speaker's value (but hearer just didn't pick it this time):
          increase-odds chosen-feature speaker-value
        ]
        [ ;;hearer simply learns the value if they don't already know it:
          learn-value chosen-feature speaker-value 1 ;;@now simply with starting odds of 1
        ]
      ]
    ]
    ;;@overvej: lær mere af succes end ikke-succes?

  ;;8. Record what happened

  let old-entry table:get chosen-table chosen-feature ;;old entry (list of all values ever chosen)
  let new-chosen list speaker-value hearer-value ;;two-item list of the new two items chosen
  let new-entry reduce sentence list old-entry new-chosen ;;the same as just lputting these new two items to the old-entry list
  table:put chosen-table chosen-feature new-entry


    ;(9. output-print what happened (just for testing):
;    output-print ""
;    output-print (word self " talked to " partner)
;    output-print word "Chosen feature: " chosen-feature
;    output-print (word "Speaker said: " speaker-value ", hearer said: " hearer-value)
;    output-print (word "Successful?: " success?)
end

to-report my-partner-choice ;;agent reporter, run in communicate. 'partner-choice' chooser in interface determines how this reporter runs
  ;;@check how papers did it
  ;;@right now only slaves. can change it to people and add:
  ;;let people (turtle-set colonists slaves)

  if partner-choice = "random" [
    report one-of other slaves ;;completely random partner
  ]

  if partner-choice = "closest-one" [
    report min-one-of slaves [distance myself] ;;the closest agent (if tie, random one of these)
  ]

  if partner-choice = "nearby" [
    let nearby other slaves in-radius 10 ;;@can change this proximity number. ;;nearby is an agentset of all agents within this radius
    ifelse any? nearby [
        report one-of nearby ;;choose someone who's nearby
    ]
    [ ;;if nobody is nearby, simply random:
      report one-of other slaves
    ]
  ]

  if partner-choice = "nearby-or-random" [
    ;;e.g. 50% chance of someone nearby, 50% chance of someone random
    let nearby other slaves in-radius 10 ;;@can change this proximity number. ;;nearby is an agentset of all agents within this radius
    ifelse any? nearby [
      let chance random-float 1
      ifelse chance < 0.50 [ ;;@can change this probability
        report one-of nearby ;;50% chance of choosing someone nearby
      ]
      [
        report one-of other slaves ;;and 50% chance of choosing a rando
      ]
    ]
    [ ;;if nobody is nearby, simply random:
      report one-of other slaves
    ]
  ]

  if partner-choice = "weighted-proximity" [
    let turtle-distance-list [list self (round distance myself)] of other slaves ;;nested list of slaves + their distance to the partner-seeker. i.e.: [ [(slave 10) 119] [(slave 17) 104] ...]
    ;;we want: the lower the distance, the higher the odds...
    ;;for the weighted-one-of function, the odds have to start from 1 (no zeros)... and the higher the odds, the higher probability of being chosen!
    ;;therefore, a little transformation:
    let distances map last turtle-distance-list
    let max-plus-one max distances + 1
    let trans-distances map [i -> max-plus-one - i] distances ;;for each distance, we subtract the distance from (the max distance + 1)
    let turtle-list map first turtle-distance-list
    ;;NOW CREATE A NESTED LIST COMBINING TURTLE-LIST AND TRANS-DISTANCES!:
    let input-list []
    foreach turtle-list [
      i ->
      let index position i turtle-list
      let this-trans-dist (item index trans-distances)
      set input-list lput (list i this-trans-dist) input-list
    ]

    report weighted-one-of input-list ;;feed this list to the function to choose a turtle randomly, weighted by proximity (the closer, the higher odds)
  ]

  ;;@maybe ADD: based on other people's language?

end

;;---REPORTERS FOR INTERFACE:

to-report year
  report floor (ticks / 12) + 1600
end

to-report this-month ;reporting month-names
  let month ticks mod 12 ;;sets this-month from 0 to 11
  report item month month-names ;;reports the current month name from the 'month-names' list
end


;;hvor langt er deres sprog fra hinanden?
;;simpleste måde:
;;for hver feature: hvad er mode? (typetal)


;;find den value med højeste odds for hver feature - den oftest forekommende med højest værdi. og se hvor mange der har den ;;TJEK!
;;og hvor mange har den højeste sandsynlighed for at trække den?

;;hvad er den højest sandsynlige værdi for hver feature? og hvor mange andre er enige i den mode (den hyppigste)
;;lav histogram: man kan ændre, hvilken feature man ser. og så kan vi se, hvor mange forskellige værdier vi finder (til test: bare 5 features)
;;distinktion: sandsynlighed? eller egentlig talt?


to initialize-my-table ;;agent procedure, used in make-person
  ;;every agent has ONE table! With 50 entries!
  ;;important: every table is unique to every agent! (turtles-own) So we don't overwrite content across agents...
  ;;key = WALS-feature name
  ;;value = a nested list, each sublist with two items: a possible/known feature value + the odds for using this instance

  let start-lang-vec-odds ( map [i -> list i 40] start-lang-vec ) ;;this turns start-lang-vec into a nested list where each entry is followed by its odds (@@@initialized as 40?)

  set my-lang-table table:make ;;initialize the empty table

  ;;loop to create each agent's language table based on their language vector:
  foreach feature-list [ ;;feature-list contains the 50 WALS feature names
    x ->
    let key x ;;the WALS feature name - what we want to be the table key
    let index position x feature-list ;;the index of the current feature in feature-list (since we then want the corresponding item from start-lang-vec):
    let empty-list [] ;;used so value becomes a nested list in an existing list (the structure we want, so we can later keep adding nested lists). ie. [[3 1]] instead of [3 1]
    let value lput (item index start-lang-vec-odds) empty-list
    table:put my-lang-table key value ;;table:put adds this key-value combination to the agent's table

    ;;to begin with, each agent only knows one possible feature value (so e.g. the value entry for feature X9A could just look like this: [0 1] ;;(where 1 is the odds)
  ]
end


;;--- PLOTS
to update-feature-plot ;;run in go
  set-current-plot "Feature plot" ;;the following manual plot commands will only be used on this plot
  clear-plot
  ;;interface chooser decides what feature we focus on ('plot-feature')

  if plot-this = "max value (count)" [ ;;for each possible value, counts and plots how many agents has that as their most likely choice (highest odds)
    let counts table:counts [most-likely-value plot-feature] of slaves ;;using the handy most-likely-value agent reporter
    ;;[most-likely-value plot-feature] of slaves is a list of all agent's top choice for the feature, e.g. [1 2 1 3 3 3]
    ;;table:counts makes it into a table where the entry is the occurences of the key in the list, e.g. {{table: [[1 2] [2 1] [3 3]]}}
    let instances sort table:keys counts ;;instance = a specific value for a WALS feature (getting confusing here - the value is the table key :)) ;;so instances is a list, e.g. [1 2 3 4]
    let n length instances ;;how many values there are
    set-plot-x-range 0 n ;;scales the plot to fit the number of instances/values we need to visualize
    let step 0.02 ;;tweak this to leave no gaps
    ;;the plotting loop:
    (foreach instances range n [
      [s i] ->
      let y table:get counts s
      ;;let c hsb (i * 360 / n) 50 75 ;;colors ;;@@@FIX these colors so they stay consistent i.e. when going from 2 to just 1 value! (make separate list?)
      let c item s color-list ;;so i.e. 'value 1' is always associated with item 1 in color-list (a specific color)
      create-temporary-plot-pen (word s) ;;the instance/value name made into a string
      set-plot-pen-mode 1 ;;bar mode
      set-plot-pen-color c
      foreach (range 0 y step) [_y -> plotxy i _y]
      set-plot-pen-color black
      plotxy i y
      set-plot-pen-color c ;;to get the right color in the legend
    ])

  ]

  if plot-this = "average probability" [ ;;for each possible value, plots the average probability of choosing that value across all agents!
    ;;for each value for plot-feature (the chosen WALS feature), we calculate the average probability (across agents) for each value/instance for this feature
    ;;using the handy 'avg-value-prob' reporter
    ;;we want to visualize ALL the possible values (in the population) all the time (no change of nr of bars)!

    let values reduce sentence [known-values plot-feature] of slaves ;;list with all known values for all slaves, i.e. [3 2 1 1 3 2 1 3 2 2 3 1 1 ...]
                                                                     ;;@not including values that are possible but aren't in the population at all
    let counts table:counts values ;;we don't actually care about these counts...
    let instances sort table:keys counts ;;but we care about how many unique values there are in the population (the keys)! (this is instances), e.g. [1 2 3]
    let n length instances ;;nr of values/instances for this feature, e.g. 3
    set-plot-x-range 0 n ;;scales the plot to fit the total number of instances/values
    let step 0.02
    ;;the plotting loop:
    (foreach instances range n [
      [s i] ->
      ;;let y table:get counts s ;;@CHANGE THIS TO THE AVERAGE PROBABILITY FOR THIS VALUE
      let y avg-value-prob plot-feature s ;;uses the reporter 'avg-value-prob' with the current feature and instance/value as input - so y is the average probability across agents

      let c item s color-list
      create-temporary-plot-pen (word s)
      set-plot-pen-mode 1
      set-plot-pen-color c
      foreach (range 0 y step) [_y -> plotxy i _y]
      set-plot-pen-color black
      plotxy i y
      set-plot-pen-color c
      ])

  ]

  if plot-this = "times chosen" [ ;;for each possible value, plot count of how many times it's been actually spoken/chosen in this run (CUMULATIVE!
    ;;for setting the range/plotting bars
    let values reduce sentence [known-values plot-feature] of slaves ;;list with all known values for all slaves, i.e. [3 2 1 1 3 2 1 3 2 2 3 1 1 ...]
                                                                     ;;@not including values that are possible but aren't in the population at all
    let counts2 table:counts values ;;we don't actually care about these counts...
    let instances sort table:keys counts2 ;;but we care about how many unique values there are in the population (the keys)! (this is instances), e.g. [1 2 3]
    let n length instances ;;nr of values/instances for this feature, e.g. 3


    let counts table:counts table:get chosen-table plot-feature ;;table with counts of how many times each value has been chosen for this feature so far
                                                                ;;i.e.: {{table: [[2 386] [1 997] [3 415]]}}
    set-plot-x-range 0 n ;;scales the plot to fit the number of instances/values we need to visualize
    let step 0.02 ;;tweak this to leave no gaps
    ;;the plotting loop:
    (foreach instances range n [
      [s i] ->
      let y "NA" ;;placeholder before the ifelse statement that sets it
      ifelse table:has-key? counts s [ ;;if it has the key:
       set y table:get counts s ;;how many times this value has been spoken (looks it up in the table)
      ]
     [ ;;if it doesn't have the key, it means it hasn't been spoken yet:
       set y 0
      ]

      let c item s color-list ;;so i.e. 'value 1' is always associated with item 1 in color-list (a specific color)
      create-temporary-plot-pen (word s) ;;the instance/value name made into a string
      set-plot-pen-mode 1 ;;bar mode
      set-plot-pen-color c
      foreach (range 0 y step) [_y -> plotxy i _y]
      set-plot-pen-color black
      plotxy i y
      set-plot-pen-color c ;;to get the right color in the legend
    ])




  ]


end



;;---USEFUL FUNCTIONS AND REPORTERS FOR HANDLING AGENTS' LANGUAGE TABLES:

to-report known-value? [feature value] ;;agent reporter (uses the agent's my-lang-table), takes a feature and value as input
  ;;reports a boolean: whether or not an agent already knows this specific value/instance of this specific WALS feature
  let value-odds-list table:get my-lang-table feature ;;the list of known values and odds associated with the WALS feature

  ;;now to remove the odds which we don't care about for this:
  let value-list map first value-odds-list ;;a list of all known values for this feature (with the odds removed)
  ifelse member? value value-list [report true] [report false] ;;checks whether the value of interest (input to this reporter) is in the known value list
end

to-report known-values [feature] ;;agent reporter. for a specific WALS feature, returns a list of all the values the agent knows (just the values, no odds!)
  let value-odds-list table:get my-lang-table feature
  report map first value-odds-list
end

to-report get-odds [feature value] ;;agent reporter. Returns the agent's associated odds for a specific value/instance of a specific WALS feature
  ifelse known-value? feature value [ ;;this only runs if the value is known!
    let value-odds-list table:get my-lang-table feature ;;the nested list of known value-odds pairs associated with the WALS feature
    let the-pair filter [i -> first i = value] value-odds-list ;;locates the value-odds pair of interest, discards the rest
    report item 1 item 0 the-pair ;;returns the odds associated with this value (item 1 item 0 starter inderst - så vi vil have det andet element fra den første liste)
  ]
  [ ;;@if they don't actually know this value, instead of an error and crashing, now returns NA:
    report "NA"
  ]
end

to-report weighted-one-of [nested-list] ;;agent reporter, more general
                                               ;;for a nested list (first = item, second = odds), based on the odds, returns one of the items (randomness involved each time)
  let odds-list map last nested-list ;;list of just the odds
  let odds-total sum odds-list ;;all the odds added together
  let roll (random odds-total) + 1 ;;we roll the dice (+1 so the result is a number from 1 to odds-total)

  let total 0 ;;initialize variables used in loop
  let final-choice "NA"

  foreach nested-list [
   i -> ;;loop through each value-odds-pair, e.g. i = [0 1]
   set total total + item 1 i ;;keep adding up the odds with your odds total so far
    if roll <= total and final-choice = "NA" [ ;;once we reach the item where the cumulative sum of odds so far is higher than (or equals) the roll, this is the value we choose!
      set final-choice item 0 i
    ]
  ]

  report final-choice ;;the value that was chosen (weighted based on the odds - but random each time due to the roll!)
end

to learn-value [feature value odds] ;;agent reporter. Adds a new value/instance + associated odds for a specific WALS feature to the agent's my-lang-table
  let new-value list value odds ;;e.g. in the form [3 1]
  let old-entry table:get my-lang-table feature ;;the value-odds-list
  let new-entry lput new-value old-entry
  table:put my-lang-table feature new-entry ;;table:put automatically overwrites the old entry
  ;;@now doesn't catch if they already know the value (can add that safety?) - or should only be used in conjunction with known-value?
end

to increase-odds [feature value] ;;agent reporter. increases the odds for a specific value/instance of a specific WALS feature - now simply by 1!
  ;;@can make it so it only runs if the value is known? (like get-odds function) - but probably not necessary if we always use it together with known-value anyway!
  let value-odds-list table:get my-lang-table feature ;;the nested list of known value-odds pairs associated with the WALS feature (e.g. [[0 2] [1 4] [2 1]]
  let the-pair item 0 filter [i -> first i = value] value-odds-list ;;locates the value-odds pair of interest, discards the rest (e.g. [[1 4]])
  let index position the-pair value-odds-list ;;the position of the value-odds pair
  let old-odds item 1 the-pair ;;the-pair is a non-nested list for these purposes
  let new-odds old-odds + 1 ;;@can maybe change this increase depending on different things?
  let new-entry replace-subitem 1 index value-odds-list new-odds ;;using the replace-subitem function, indexing from the innermost list and outwards
  table:put my-lang-table feature new-entry ;;table:put automatically overwrites the old entry for this feature
end

to decrease-odds [feature value] ;;agent reporter. decreases the odds for a specific value/instance of a specific WALS feature - now simply by -1! (but never to 0)
  ;;@can make it so it only runs if the value is known? (like get-odds function) - but probably not necessary if we always use it together with known-value anyway!
  let value-odds-list table:get my-lang-table feature ;;the nested list of known value-odds pairs associated with the WALS feature (e.g. [[0 2] [1 4] [2 1]]
  let the-pair item 0 filter [i -> first i = value] value-odds-list ;;locates the value-odds pair of interest, discards the rest (e.g. [[1 4]])
  let index position the-pair value-odds-list ;;the position of the value-odds pair
  let old-odds item 1 the-pair ;;the-pair is a non-nested list for these purposes
  let new-odds old-odds - 1 ;;@can maybe change this decrease depending on different things?
  if old-odds > 1 [ ;;odds can never get below 1
    let new-entry replace-subitem 1 index value-odds-list new-odds ;;using the replace-subitem function, indexing from the innermost list and outwards
    table:put my-lang-table feature new-entry ;;table:put automatically overwrites the old entry for this feature
  ]
end

to-report my-value-prob [feature value] ;;agent reporter, takes a WALS feature and value/instance, calculates the probability that an agent chooses this value (odds --> probability)
  ;;returns 0 if they don't know the value!
  let value-odds-list table:get my-lang-table feature ;;the nested list of known value-odds pairs associated with the WALS feature, e.g. [[0 2] [1 4] [2 1]]
  let odds-list map last value-odds-list ;;list of just the odds, e.g. [2 4 1]
  let odds-total sum odds-list ;;the sum of all the odds
  ifelse length ( filter [i -> first i = value] value-odds-list ) = 0 [
    report 0
  ]
  [;;if they do know the value:
    let the-pair item 0 filter [i -> first i = value] value-odds-list ;;locates the value-odds pair of interest, discards the rest, e.g. [1 4]) ;;(item 0 since it's a nested list)
    let the-odds item 1 the-pair ;;just the odds number
    let probability the-odds / odds-total ;;total sum of odds divided by the odds of interest = probability!
    report probability ;;a number between 0 and 1, indicating the percentage chance
                       ;;giver sandsynligheden for at agenten vælger netop denne value for denne feature
  ]
end

to-report most-likely-value [feature] ;;agent reporter, takes a WALS feature and reports the value with the highest odds for this agent for this feature
  let value-odds-list table:get my-lang-table feature
  let odds-list map last value-odds-list
  let max-odds max odds-list ;;the highest odds number

  let index "NA" ;;initialize it outside of the ifelse block
  ifelse frequency max-odds odds-list > 1 [ ;;how to handle tie-breaks if there are more than one odds of this value (frequency is a reporter):
    let position-list []
    while [frequency max-odds odds-list > 0] [ ;;as long as there's still occurences of the max value in the list
      let an-index position max-odds odds-list ;;return the position of the FIRST occurence only
      set position-list lput an-index position-list ;;add it to the list of positions
      set odds-list replace-item an-index odds-list "wee" ;;replace the value at the position - so indexing is intact, but it isn't counted next time

    ]
    set index one-of position-list ;;choose one of the max value positions at random
    ;;print "a tie!" ;;so we can get a feel for how often this happens...
  ]
  [ ;;if there's only one instance of the max odds:
    set index position max-odds odds-list ;;simply save: what number in the list was it?
  ]
  let the-pair item index value-odds-list ;;use this index to locate the value-odds pair with the highest odds
  let the-value first the-pair
  report the-value
end

;;@could maybe write a function to determine the odds increase/decrease depending on lots of things
  ;;how do we want to do this? more inputs? what to include?


;;--- NON-AGENT REPORTERS:

to-report avg-value-prob [feature value] ;;reports the average probability across agents for choosing this value for this feature
                                   ;;my-value-prob [feature value] ;;using the my-value-prob agent reporter
  let prob-list ( reduce sentence [my-value-prob plot-feature 1] of slaves ) ;;list of all agent's probs for this value, e.g. [0.9595959595959596 0.9770114942528736 1 ...]
  report mean prob-list ;;the average probability of choosing this value for this feature, across agents
end


;;---BASIC USEFUL REPORTERS:

to-report replace-subitem [index2 index1 lists value] ;;OBS: I changed it around to fit NetLogo logic! begins from the INSIDE! index2 is the innermost index, index1 is the list position!
  let old-sublist item index1 lists
  report replace-item index1 lists (replace-item index2 old-sublist value)
end

to-report frequency [the-item the-list]
    report length filter [i -> i = the-item] the-list
end

;;---IMPORTING DATA FILES:

;;using this guide: https://www.mail-signatures.com/articles/direct-link-to-hosted-image/#google-drive
;;trying with Google Drive:
;;link to just the image: https://drive.google.com/file/d/1b9i6SpS2BCsYk80N8FLGd_dorG0_5Y5p/view?usp=sharing
;;using this downloadable link template: https://drive.google.com/uc?export=download&id=DRIVE_FILE_ID
;;from this guide: https://www.labnol.org/internet/direct-links-for-google-drive/28356/
;;result: https://drive.google.com/uc?export=download&id=1b9i6SpS2BCsYk80N8FLGd_dorG0_5Y5p

;;trying with imgur works!

;;trying with Google slides (guide: https://www.labnol.org/internet/direct-links-for-google-drive/28356/):
;;template: https://docs.google.com/presentation/d/FILE_ID/export/png?pageid=p1
;;slides link: https://docs.google.com/presentation/d/1MzR9xRm1d4FTTP9kcAgdfIPvJUZ2JCp99CfH5DGcvTk/edit?usp=sharing (work out sizing!)
;;  fetch:url-async "https://docs.google.com/presentation/d/1MzR9xRm1d4FTTP9kcAgdfIPvJUZ2JCp99CfH5DGcvTk/export/png?pageid=p1" [ ;;@DOESN'T WORK

to import-img
  ;;fetch:url-async "https://drive.google.com/uc?export=download&id=1b9i6SpS2BCsYk80N8FLGd_dorG0_5Y5p" [
  fetch:url-async "https://i.imgur.com/Vh9k5AI.png" [ ;;works! (but NL web? hmmm)

    p ->
    import-a:pcolors p
  ]
end

;;following this guide to use Google sheets to host a downloadable csv url: https://www.megalytic.com/knowledge/using-google-sheets-to-host-editable-csv-files
;;link to the sheets: https://docs.google.com/spreadsheets/d/1OGV8slI_8c7p-oCiaybl-lCDb6V1rhk6WCmaMrDNXys/edit?usp=sharing
;;downloadable link used here to import: https://docs.google.com/spreadsheets/d/1OGV8slI_8c7p-oCiaybl-lCDb6V1rhk6WCmaMrDNXys/gviz/tq?tqx=out:csv
;;we can always change this url if/when we find a better way to host the csv files online

to import-csv
  fetch:url-async "https://docs.google.com/spreadsheets/d/1OGV8slI_8c7p-oCiaybl-lCDb6V1rhk6WCmaMrDNXys/gviz/tq?tqx=out:csv" [
    text ->
    let whole-file csv:from-string text ;;this gives us ONE long list of single-item lists
    ;;now to convert it:
    set wals-list []
    set wals-list ( map [i -> csv:from-row reduce word i] whole-file ) ;;a full list of lists (every sheets row is an item)
    ;;explanation: 'reduce word' makes every nested list in the list one string entry instead of a single-item list
    ;;'csv:from-row' makes each item a netlogo spaced list instead of a comma separated string
  ]

  set header-list item 0 wals-list ;;the headers from the csv ('Affiliation', 'ID', followed by feature names) (matching the values in wals-list) ;;probably don't need this?
  set feature-list but-first but-first header-list ;;removes first two items - now only the feature names (matching the positions for values in wals-table)
  set wals-list but-first wals-list ;;now wals-list only contains affiliation, language ID, and associated feature lists (and not the header-list which was item 0)

  ;;now to make the table:
  set wals-table table:make ;;initialize the empty table

  ;;loop to create the wals table based on the list:
  foreach wals-list [ ;;wals-list is a list of lists
    x -> ;;x is each sublist in the form ["Atlantic creoles" "cSANo" 1 1 1 1 3 1 1 1 8 ... ]
    let key item 1 x ;;item 1 in this sublist is the language ID - what we want to be the table key
    let value but-first but-first x ;;the table value should be just the numbered feature list, without the affiliation and language ID
    table:put wals-table key value ;;table:put adds this key-value combination to the table
  ]
end

;;@Ida's notes about how to handle the data:
;;- how to get a particular feature value for a particular language from the WALS table:
  ;;let lang-vec table:get wals-table "cSANo" ;;write the language ID code here
  ;;output-print item 0 lang-vec ;;write the feature as the item position (in relation to feature-list!)


;;---GRAPHICS:

to initialize-map
  streamline-map
  set sea-patches patches with [pcolor = red] ; defining the global variables
  set land-patches patches with [pcolor = green]
  color-map
end

to streamline-map ; this is manipulating the map into 2 colors
ask patches with [shade-of? pcolor sky] [set pcolor red]
  ask patches with [shade-of? pcolor turquoise] [set pcolor green]
  ask patches with [shade-of? pcolor white] [set pcolor green]
  ask patches with [ shade-of? pcolor blue ] [set pcolor red]
  ask patches with [pcolor != green and pcolor != red] [set pcolor green]
  ask patches with [ count neighbors with [ pcolor = red ] >= 7 ] [set pcolor red]
  ask patches with [ count neighbors with [ pcolor = green ] >= 7 ] [set pcolor green]
  ask patches with [ count neighbors with [ pcolor = green ] >= 7 ] [set pcolor green]
end

to color-map
  ask patches with [pcolor = red] [set pcolor blue - 2 + random-float 2]
  ask patches with [pcolor = green] [set pcolor green + 0.2 + random-float 0.8]
end
@#$#@#$#@
GRAPHICS-WINDOW
225
10
955
357
-1
-1
2.0
1
10
1
1
1
0
0
0
1
-180
180
-84
84
0
0
1
ticks
30.0

BUTTON
30
120
93
153
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
100
120
163
153
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

MONITOR
500
360
557
405
Month
this-month
17
1
11

MONITOR
560
360
617
405
Year
year
17
1
11

MONITOR
1290
10
1370
55
NIL
success-count
17
1
11

MONITOR
1290
60
1370
105
NIL
fail-count
17
1
11

PLOT
965
10
1285
185
Communication outcomes (per tick)
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
"Successes" 1.0 0 -14439633 true "" "plot successes-this-tick"
"Failures" 1.0 0 -5298144 true "" "plot fails-this-tick"

CHOOSER
85
25
215
70
partner-choice
partner-choice
"random" "closest-one" "nearby" "nearby-or-random" "weighted-proximity"
0

INPUTBOX
10
20
80
80
nr-of-agents
100.0
1
0
Number

PLOT
1070
255
1290
495
Feature plot
Values
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

CHOOSER
1070
205
1162
250
plot-feature
plot-feature
"X9A" "X10A" "X18A" "X27A" "X28A"
0

CHOOSER
1165
205
1290
250
plot-this
plot-this
"max value (count)" "average probability" "times chosen"
2

TEXTBOX
1300
200
1485
406
@max value (count): hvor mange der har den value som top choice. ret nice, kan se hvordan én overtager\n\n@average probability: ikke så interessant, mean ligger bare stabilt? (fordi: nu er avg prob 0 for dem, der ikke kender værdien!)\n\n@times chosen: cool cumulative overview\n\n
12
0.0
1

TEXTBOX
1315
415
1485
480
@men fordi der er så mange features (50) og de kun vælger én hver gang, tager det lang tid at se forandring for bare en enkelt!
11
0.0
1

BUTTON
1120
495
1240
528
NIL
update-feature-plot
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
1250
515
1485
555
(button useful if changing plot-this while the model is paused) (otherwise this command is run every tick in go)
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
