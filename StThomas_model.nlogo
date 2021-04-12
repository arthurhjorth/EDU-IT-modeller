extensions [fetch import-a csv table profiler]

globals [
  wals-list
  header-list
  lang-list
  col-lang-list
  slave-lang-list
  affiliation-list
  feature-list
  wals-table

  word-list ;;[word0 word1 word2 ... ]

  color-list ;;for plotting
  agent-color-list ;;for visualizing

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

  people ;;turtle-set so slaves and colonists can be adressed with one word

  testing
]

breed [plantations plantation]
breed [colonists colonist]
breed [slaves slave]

slaves-own [
  start-lang ;;starting language (ID code)
  start-lang-vec ;;vector with the feature values for their starting language @maybe doesn't need to be saved? although maybe for later comparison...
  my-lang-table ;;their language table! 50 entries, one for each WALS feature. Each entry is a nested list of their known values for this feature + associated odds
  my-word-table ;;their vocabulary
  closest-agent ;;turtle set (of 1 or maybe more) used in my-partner-choice
  nearby-agents ;;turtleset used in my-partner-choice
  my-weighted-prox-list ;;used for weighted-proximity
  age
  birth-month ;;so they don't all age and thereby die at the exact same time
  my-plantation ;used to choose partner
]

colonists-own [
  start-lang
  start-lang-vec
  my-lang-table
  my-word-table
  closest-agent
  nearby-agents
  my-weighted-prox-list
  age
  birth-month
  my-plantation
]

plantations-own [
  name
  members
  neighbour
]

to profile
  profiler:reset
  setup
  profiler:start
  repeat 50 [go]
  print profiler:report
end


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

  make-plantations
  populate ;;create starting population
  set people (turtle-set slaves colonists)
  ask people [ initialize-agent-variables ]
  ask people [ alocate-to-plantation ] ;
  update-feature-plot
  update-convergence-plot
end

to make-plantations
  ;;layout the world
  ;;data from Hall (1992: 5) (modified to the csv 'percent of total enslaved')
  ;;here generalised to the whole time period...

  let plant-names ["koonings" "west eijnd" "krum" "erasmus baij" "windt" "noort" "friedrichs" "orcaen" "fransmans" "dorp" "qvarteer" "oost"]

  ;;positions:
  let plant-patches (patch-set patch -86 0 patch -63 3 patch -30 1 patch -21 17 patch -5 -16 patch -2 8 patch 26 -2 patch 53 -7 patch 54 -32 patch 80 -6 patch 83 -33 patch 110 -22) ;;12 different positions
  set plant-patches sort-on [pxcor] plant-patches ;(from left to right based on pxcor)

  create-plantations 12 [
    set color white set shape "house" set size 7
    set name first plant-names
    set plant-names but-first plant-names ;removes the first item from the name list (since it's now taken) (this code block is run by one plantation at a time)

    ;;move to spot:
    move-to first plant-patches
    set plant-patches but-first plant-patches
  ]



end

to initialize-variables ;;run in setup
  set month-names ["Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"] ;either start in dec or jan. If starting jan we have tick 1 = feb. Does it matter though?
  set lang-list table:keys wals-table ;;list of all the language IDs
  ;;@OBS: check/fix/change these language mappings!:
  set col-lang-list sublist lang-list 141 149 ;;@check if right! the list (from affiliation-list): ["Dutch" "English" "French" "Swedish" "German" "Portu." "Spanish" "Danish"]
  let slave-lang-list1 sublist lang-list 0 141 ;;@all the other languages
  set slave-lang-list remove-item 12 slave-lang-list1 ;;not including Dutch creole (cVIDd)

  set affiliation-list map first wals-list ;;list of all the language affiliations ('i.e. "Atlantic creoles"), matching the indexes in lang-list
  set agreement [] ;;global list, gonna be a nested list storing counts of successes and fails in communication

  set word-list []
  ;;nr-words is a number showing how many different word meanings agents have (for each meaning, every language will then have a unique word)
    foreach range nr-words [ ;;for the numbers 0 to one less than nr-words (e.g. if nr-words = 10, it loops through 0 to 9 - which still equals 10 unique words (0-9)
      n ->
      set word-list lput (word "word" n) word-list
    ]

  set chosen-table table:make ;;initialize the chosen-table:
  foreach feature-list [ ;;feature-list contains the 50 WALS feature names
    key -> ;;the WALS feature name - what we want to be the table key
    let value [0 0 0 0 0 0 0 0 0 0] ;;values are a list of counts for how often each value (of that index, e.g. item 1 = value '1' for that feature) has been chosen. max value = 9. ?-values = index 0.
    table:put chosen-table key value ;;table:put adds this key-value combination to the agent's table
  ]


  set color-list [0 16 106 44 56 115 26 84 6] ;;colors for plotting (ensures through indexing that the same value is always the same color)
  set agent-color-list [white 14 104 45 53] ;;@ can add more
end

to initialize-agent-variables ;;agent procedure, run in setup

  ;;distance Agent variables previously used in my-partner-choice:

;  set closest-agent min-one-of other people [distance myself] ;;agentset of the closest other agent (if tie, random one)
;  set nearby-agents other people in-radius 10 ;;@can change this proximity number. ;;nearby is an agentset of all agents within radius 10
;
;
;  ;;now for the list of all other turtles and their distances (used in weighted-proximity):
;  let turtle-distance-list [list self (round distance myself)] of other people ;;nested list of slaves + their distance to the partner-seeker. i.e.: [ [(slave 10) 119] [(slave 17) 104] ...]
;  ;;we want: the lower the distance, the higher the odds... for the weighted-one-of function, the odds have to start from 1 (no 0's)... and the higher the odds, the higher probability of being chosen!
;  ;;therefore, a little transformation:
;  let distances map last turtle-distance-list
;  let max-plus-one max distances + 1
;  let trans-distances map [i -> max-plus-one - i] distances ;;for each distance, we subtract the distance from (the max distance + 1)
;  let turtle-list map first turtle-distance-list
;  ;;NOW CREATE A NESTED LIST COMBINING TURTLE-LIST AND TRANS-DISTANCES!:
;  set my-weighted-prox-list [] ;;an agent variable
;  foreach turtle-list [
;    i ->
;    let index position i turtle-list
;    let this-trans-dist (item index trans-distances)
;    set my-weighted-prox-list lput (list i this-trans-dist) my-weighted-prox-list
;  ]

end

to go
  set people (turtle-set slaves colonists) ;;including it every tick so it updates when we add new agents to the population at some point (otherwise they wouldn't be included)

  ask people [ if closest-agent = nobody [ initialize-agent-variables ] ] ;;if their closest agent have died, update all distance-based people relations

  set fails-this-tick 0 set successes-this-tick 0

  repeat convs-per-month [ ask people [ communicate ] ] ;runtime error

  ;ask people [ communicate ] ;;procedure where agents talk to each other
  set agreement lput (list successes-this-tick fails-this-tick) agreement ;;nested list, each round updated with counts of successes and fails (nested list with the two totals)
  update-feature-plot
  update-convergence-plot

  if deaths? [
    ask people [
      get-older ;;agents get older and maybe die
    ]
  ]
  set time ticks mod 12 ;;update time
  if year = 1940 [stop]

  tick
end

to alocate-to-plantation
  move-to one-of plantations
  ask plantations [set members turtles-here] ;@@@how can i use people-here? do i have to make it a breed? (the reason is that i read that it now also sees itself as a member of itself
  ;- it seems to possibly be problematic
  ;ask plantations [set members colonists-here]

  ask plantation 0 [ ;@@@ preferably the closest plantations that are neighbours for illustrative purposes - otherwise it doesn't matter
  create-link-to plantation 1
  ]
  ask plantation 2 [
  create-link-to plantation 3
  ]
  ask plantation 4 [
  create-link-to plantation 5
  ]
  ask plantation 6 [
  create-link-to plantation 7
  ]
  ask plantation 8 [
  create-link-to plantation 9
  ]
  ask plantation 10 [
  create-link-to plantation 11
  ]
  ask plantations [ ask my-links [ hide-link ] ]
end

to populate ;;run in setup. Create starting population

  ;;@random starting language right now! (from these two lists)
  repeat nr-slaves [ make-person "slave" (one-of slave-lang-list) ]
  repeat nr-colonists [ make-person "colonist" (one-of col-lang-list) ]
end


to make-person [kind language] ;;function that creates a person and takes their starting language ID as input to give them their language feature vector


  if kind = "slave" [
    create-slaves 1 [
      ;;@can change starting age!:
      while [age <= 0] [ set age round random-normal 25 5 ] ;;mean of 30, sd of 10. everyone is at least 1 year old (normal distribution can give negative values)


      set birth-month one-of month-names

      set shape "person" set size 6 set color black
      set start-lang language
      set start-lang-vec table:get wals-table language ;;looks up their language in the wals-table and gives them the corresponding feature list

      initialize-my-tables ;;creates their language table

      ;;@just random position right now:
      move-to one-of land-patches with [not any? slaves-here]

    ]
  ]

  if kind = "colonist" [
    create-colonists 1 [
      ;;@can change starting age!:
      while [age <= 0] [ set age round random-normal 30 5 ] ;;everyone is at least 1 year old (normal distribution can give negative values)

      set birth-month one-of month-names

      set shape "person-inspecting" set size 6 set color black
      set start-lang language
      set start-lang-vec table:get wals-table language ;;looks up their language in the wals-table and gives them the corresponding feature list

      initialize-my-tables ;;creates their language table

      ;;@just random position right now:
        move-to one-of land-patches with [not any? slaves-here and not any? colonists-here]
    ]
  ]
end

to communicate ;;agent procedure run in go ;;no longer coded from the speaker's perspective! (so every agent does NOT get to be speaker every tick)
    ;;all of this is repeated 'convs-per-month' nr of times each tick (interface input) - see go

  ;;0. Find a talking buddy
  let partner my-partner-choice ;;using the agent reporter to select a partner
                                    ;;@tilføj evt: gem historie over hvem der har talt sammen?
  let partners (turtle-set self partner) ;a way to address both speaker and hearer at the same time

  ;;1. Set speaker and hearer
  let speaker "NA" let hearer "NA"
  ifelse include-status? [
    ;if status included, slaves never speak to europeans:
    let same? reduce = [breed] of partners ;boolean, reports true if the two are of same breed, false if they're of different breeds
    ifelse same? [
      ;if they're the same, it's randomly set anyway:
      ifelse random 2 = 1 [set speaker self set hearer partner] [set hearer self set speaker partner]
    ]
    [ ;if they're different, i.e. one slave and one colonist, colonist is always speaker:
      set speaker one-of partners with [breed = colonists]
      set hearer one-of partners with [breed = slaves]
    ]
  ]
  [ ;if status isn't included, speaker and hearer are set at random:
    ifelse random 2 = 1 [set speaker self set hearer partner] [set hearer self set speaker partner]
  ]

  ;;2. Choose which WALS feature(s) to exchange (the 'conversation topic')
  let chosen-features n-of nr-features-exchanged feature-list ;;can select multiple features. Randomly chosen right now (feature-list is a global variable with all 50 features)

  ;;3. Ask speaker to retrieve a specific value for each WALS feature from their language table
  let speaker-choices []
  ask speaker [
    foreach chosen-features [ ;;speaker now chooses a value for each feature in the 'conversation'
      x ->
      let speaker-input-list table:get my-lang-table x ;;the nested list of known value-odds pairs associated with the WALS feature (e.g. [[0 2] [1 4] [2 1]]
      let the-value weighted-one-of speaker-input-list ;weighted-one-of takes a nested pair list  ([[item odds] [item odds]]) and randomly picks an item based on their odds
      set speaker-choices lput the-value speaker-choices ;speaker-choices is a list with all the final chosen values
    ]
  ]

  ;;4. Likewise, ask hearer to retrieve a value for each of the WALS features
  let hearer-choices []
  ask hearer [
    foreach chosen-features [
      x ->
      let hearer-input-list table:get my-lang-table x
      let the-value weighted-one-of hearer-input-list
      set hearer-choices lput the-value hearer-choices
    ]
  ]

  ;;4.5: Potentially also retrieve a word from vocabulary
  let chosen-word "NA"
  let chosen-topics chosen-features
  if include-words? [
    ;;A. Choose which word meaning to utter:
    set chosen-word one-of word-list ;;e.g. 'word3'
    set chosen-topics lput chosen-word chosen-features ;;better name, store it ;;so the list is of ALL topics in this interaction, features and words, e.g. ["X9A" "X29A" "word3"]


    ;;A. Speaker retrieves a word from their vocabulary for this word meaning (e.g. 'cSANoword3'):
    let speaker-word "NA"
    ask speaker [
      let speaker-word-list table:get my-word-table chosen-word
      set speaker-word weighted-one-of speaker-word-list ;;using the weighted-one-of function
      set speaker-choices lput speaker-word speaker-choices ;;add the chosen word to the list with the chosen feature values (for joint comparison later)
    ]

    ;;B. Likewise, hearer retrieves a word:
    let hearer-word "NA" ;;placeholder to initiate value outside ask block
    ask hearer [
      let hearer-word-list table:get my-word-table chosen-word
      set hearer-word weighted-one-of hearer-word-list ;;using the weighted-one-of function
      set hearer-choices lput hearer-word hearer-choices ;combine into a list with both the values and the word
    ]
  ]

  ;;5. Compare the values to see if the communication was coordinated/succesful ;;(overall success if nr of matches is above the chosen threshold)

  ;;compare the two lists to make a TRUE/FALSE list to test success for each individual feature (and maybe a word)
  let outcome-list (map = speaker-choices hearer-choices) ;;this returns a list of booleans. e.g. (map = [1 0 3 cSANoword3] [1 2 1 cSANOword3]) results in the list: [true false false true]
  ;;(understood in this context means that the hearer and speaker both drew/chose the exact same value/word, nothing else matters)
  let nr-understood length filter [i -> i = true] outcome-list ;;nr of trues in the list
  let percent-understood nr-understood / length outcome-list ;;the percentage understood of the exchanged items
  let percent-needed (%-understood-for-overall-success / 100) ;;threshold from interface
  ;;check if understanding is above the threshold:
  let success? "NA" ;;placeholder to initiate variable outside ifelse blocks
  ifelse percent-understood >= percent-needed [ ;;if percent successes (for all the features and words exchanged in this interaction) is above the threshold, OVERALL SUCCESS!
    set success? true ;;measures overall success
    set success-count success-count + 1 ;;total cumulative
    set successes-this-tick successes-this-tick + 1 ;;for plotting (and agreement list)
  ]
  [ ;;if not overall success:
    set success? false
    set fail-count fail-count + 1 ;;total cumulative
    set fails-this-tick fails-this-tick + 1 ;;for plotting (and agreement list)
  ]

  ;;6. They update their language tables depending on the outcome and settings under 'Sproglæring':
  let chosen-items (map list speaker-choices hearer-choices) ;;new nested list, i.e. from [0 2 "cSANoword3"] and [1 3 cSANoword3] ---> to: [[0 1] [2 3] [cSANoword3 cSANoword3]]
    ;;^^nested list, each two-item list is the values (+ word) chosen for speaker and hearer

  ;LOOP through each topic and update hearer/speaker's odds depending on settings:
  foreach chosen-topics [
      the-topic -> ;x is either a feature ('X9A') or a word meaning ('word3')
      let pos position the-topic chosen-topics ;;the position (for mapping to chosen-items)
      let choices item pos chosen-items
      let s-choice first choices
      let h-choice last choices
      let local-success? "NA"
      ifelse s-choice = h-choice [set local-success? true] [set local-success? false] ;whether this specific item was a match ('local success')

    ;IF OVERALL SUCCESS:
    if success? [
      if if-overall-success = "Both increase all speaker's values" [
        ask partners [ increase-odds-success the-topic s-choice ] ;both increase odds for every item in every loop iteration
      ]
      if if-overall-success = "Both increase successful/matching values only" [
        if local-success? [
          ask partners [ increase-odds-success the-topic s-choice ] ;both increase odds for every matching/locally sucessful item
        ]
      ]
      if if-overall-success = "Hearer increases all speaker's values" [
        ask hearer [ increase-odds-success the-topic s-choice ] ;only hearer increases odds for every item (if not known, they LEARN it!)
      ]
      if if-overall-success = "Hearer increases successful/matching values only" [
        if local-success? [
          ask hearer [ increase-odds-success the-topic s-choice ] ;hearer increases odds for every matching/locally sucessful item
        ]
      ]
    ] ;end of if overall success

    ;IF OVERALL FAILURE:
    if not success? [
      ;check if the switch is on:
      let people-affected "NA"
      ifelse hearer-learns-from-failure? [
        ;if hearer instead learns from failure:
        set people-affected speaker
        ;if switch on, hearer instead increases ALL speaker's values:
        ask hearer [ increase-odds-unsuccess the-topic s-choice ] ;only hearer increases odds (by unsuccessful rate) for every item (if not known, they LEARN it!)
      ]
      [ ;if hearer and speaker both follow if-overall-failure:
        set people-affected partners ;speaker AND hearer
      ]

      if if-overall-failure = "Both decrease all speaker's values (if known)" [
        ask people-affected [ decrease-odds the-topic s-choice ] ;both (or just speaker, depending on switch) decrease odds for every item (that they know)
      ]
      if if-overall-failure = "Both decrease unsuccessful values only (if known)" [
        if not local-success? [
          ask people-affected [ decrease-odds the-topic s-choice ] ;both (or just speaker, depending on switch) decrease odds for every non-matching item (that they know)
        ]
      ]

      ;don't need to include code for: if if-overall-failure = "Nothing happens" - since... nothing happens ;-)

    ] ;end of if overall failure
   ] ;;end of looping through chosen-topics


  ;;7. Record what happened (what was uttered - for feature plot)
  ;('uttered' now counts both speaker's and hearer's choice/draw, no distinction in chosen-table)
  foreach chosen-items [ ;;for each of the nested lists of two spoken values/words
    val-indexes -> ;for speaker and hearer
    let topic-pos position val-indexes chosen-items ;;keep track of what feautre/word we're recording now
    foreach val-indexes [ ;;for the two: both hearer's and speaker's (a loop in a loop...)
      val-index ->


      if val-index = "?" [set val-index 0] ;;@now '?'-entries are recorded in index 0 (since there are no 0 values)
      ;;value 1 tilsvarer position 1, 2 tilsvarer position 2 osv...

      ifelse is-number? val-index [ ;;if it's a feature value:
        let old-entry table:get chosen-table (item topic-pos chosen-topics) ;;old entry, 10-item list with each nr representing the total nr of times that value (index position) has been chosen
        let new-entry replace-item val-index old-entry (item val-index old-entry + 1) ;;increases the number (count so far) at the position of the value index by 1 (for this feature)
        table:put chosen-table (item topic-pos chosen-topics) new-entry ;chosen-table is a record of all feature values uttered
      ]
      [ ;if it's non-numeric, i.e. the words! (last item if included):

        ;;@CAN ADD RECORD of all the words that have been chosen - either integrate in chosen-table or create separate structure
        ;@DO IT HERE

      ]
    ]
  ]

  ;;8. print what happened (just for testing):
;  print ""
;  print (word speaker " talked to " hearer)
;  print word "Chosen topics): " chosen-topics
;  print (word "Speaker said: " speaker-choices ", hearer said: " hearer-choices)
;  print (word "Percent understood: " percent-understood)
;  print (word "Overall succes?: " success?)
end


to-report weighted-partner-choice
  ;let partner-choice-odds [["random" random-one] ["my plantation" on-my-plantation] ["neighbour plant" neighbour-plantation] ] ;@ figure out how to have random-one be exchanged with the variable from interface
  ;let partner-choice-odds [["random" 1] ["my plantation" 2] ["neighbour plant" 3] ]

  ;weighted-one-of nested-list [[random 1] [closest-one 2] ...]
  ;weighted-one-of partner-choice-odds
  ;if random
  ;if my plantation
  ;if neighbour plant



end

to-report my-partner-choice ;;agent reporter, run in communicate. 'partner-choice' chooser in interface determines how this reporter runs
  ;;@check how papers did it
  ;;@right now only slaves. can change it to people and add:
  ;;let people (turtle-set colonists slaves)

  if partner-choice = "random" [
    report one-of other people ;;completely random partner
  ]

  if partner-choice = "closest-one" [
    report closest-agent ;;the closest agent
  ]

  if partner-choice = "nearby" [
    ;;nearby is an agentset of all agents within radius 10 (set in initialize-agent-variables)
    ifelse any? nearby-agents [
        report one-of nearby-agents ;;choose someone who's nearby
    ]
    [ ;;if nobody is nearby, simply random:
      report one-of other people
    ]
  ]

  if partner-choice = "nearby-or-random" [
    ;;e.g. 50% chance of someone nearby, 50% chance of someone random
    ifelse any? nearby-agents [
      let chance random-float 1
      ifelse chance < 0.50 [ ;;@can change this probability
        report one-of nearby-agents ;;50% chance of choosing someone nearby
      ]
      [
        report one-of other people ;;and 50% chance of choosing a rando
      ]
    ]
    [ ;;if nobody is nearby, simply random:
      report one-of other people
    ]
  ]

  if partner-choice = "weighted-proximity" [
    ;;my-weighted-prox-list is created in initialize-agent-variables
    report weighted-one-of my-weighted-prox-list ;;feed this list to the function to choose a turtle randomly, weighted by proximity (the closer, the higher odds)
  ]

  ;;@maybe ADD: based on other people's language/status/age/family ties?
end

to get-older ;;agent reporter, run in go
  if this-month = birth-month [set age age + 1] ;;get older

  ;@LEVEALDER SLIDER
  ;;; new, simple dying age for :
if age = dying-age [die]

; ;;maybe die (@change age of death?!):
; ifelse [breed = colonists] of self [
;    ;;colonist dying age:
;
;    if age > 45 and random 4 = 0 [die] ;;if they're 45 or older, 25% risk of dying every month
;  ]
;  [ ;;slave dying age:
;    if age = dying-age [die]
;
;
;  ]

end





;;---REPORTERS FOR INTERFACE:

to-report year
  report floor (ticks / 12) + 1600
end

to-report this-month ;reporting month-names
  let month ticks mod 12 ;;sets this-month from 0 to 11
  report item month month-names ;;reports the current month name from the 'month-names' list
end


to color-by-lang
  set people (turtle-set slaves colonists)
  ask people [
    let my-choice most-likely-value color-feature ;;their most likely value for this feature (highest odds)
    set color item my-choice agent-color-list ;;using the value as indexing for what color to choose from the global agent-color-list
  ]
end


;;hvor langt er deres sprog fra hinanden?
;;simpleste måde:
;;for hver feature: hvad er mode? (typetal)


;;find den value med højeste odds for hver feature - den oftest forekommende med højest værdi. og se hvor mange der har den ;;TJEK!
;;og hvor mange har den højeste sandsynlighed for at trække den?

;;hvad er den højest sandsynlige værdi for hver feature? og hvor mange andre er enige i den mode (den hyppigste)
;;lav histogram: man kan ændre, hvilken feature man ser. og så kan vi se, hvor mange forskellige værdier vi finder (til test: bare 5 features)
;;distinktion: sandsynlighed? eller egentlig talt?


to initialize-my-tables ;;agent procedure, used in make-person
  ;;every agent has ONE table for WALS features! With 50 entries!
  ;;important: every table is unique to every agent! (turtles-own) So we don't overwrite content across agents...
  ;;key = WALS-feature name
  ;;value = a nested list, each sublist with two items: a possible/known feature value + the odds for using this instance

  ;;and ONE table for the vocabulary!

  ;;1. WALS TABLE:
  let start-lang-vec-odds ( map [i -> list i start-odds] start-lang-vec ) ;;this turns start-lang-vec into a nested list where each entry is followed by its odds (we've used 40 a lot)
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

  ;;2. VOCABULARY TABLE (for 'words' - unique for each language!):
  if include-words? [

    ;;word-list looks like this: [word0 word1 word2 word3 ...] with length depending on nr-words - so these are the word meanings

    let start-word-vec map [i -> word start-lang i] word-list ;;result is the unique 'words' for each meaning for that language - e.g. [cSANoword0 cSANoword1 ...]

    let start-word-vec-odds ( map [i -> list i start-odds] start-word-vec ) ;;this turns start-word-vec into a nested list where each 'unique word' is followed by its (starting) odds
    ;;@^^right now the same starting odds for WALS features and words!
    set my-word-table table:make ;;initialize the empty table

    ;;loop to create each agent's word table:
    foreach word-list [ ;;word-list looks like this: [word0 word1 word2 word 3 ...] (length depending on nr-words)
      x ->
      let key x ;;the word name/'meaning' - what we want to be the table key (e.g. word0 might be the meaning of 'bread')
      let index position x word-list ;;the index of the current feature in feature-list (since we then want the corresponding item from start-word-vec):
      let empty-list [] ;;used so value becomes a nested list in an existing list (the structure we want, so we can later keep adding nested lists). ie. [[3 1]] instead of [3 1]
      let value lput (item index start-word-vec-odds) empty-list
      table:put my-word-table key value ;;table:put adds this key-value combination to the agent's table

      ;;to begin with, each agent only knows one possible word for each meaning - the word from their starting language!
      ;;e.g. the value entry for word0 could just look like this: [[cSANo 1]] ;;(where 1 is the odds)
  ]


  ]

end


;;--- PLOTS
to update-feature-plot ;;run in go (and setup)
  if ticks mod 6 = 0 [ ;only updates every 6 months
    set-current-plot "Feature plot" ;;the following manual plot commands will only be used on this plot
    clear-plot
    ;;interface chooser decides what feature we focus on ('plot-feature')

    if plot-this = "max value (count)" [ ;;for each possible value, counts and plots how many agents has that as their most likely choice (highest odds)

      ;;we want to visualize ALL the possible values (in the population) all the time (no change of nr of bars)!
      let values reduce sentence [known-values plot-feature] of people ;;list with all known values for all people, i.e. [3 2 1 1 3 2 1 3 2 2 3 1 1 ...]
                                                                       ;;@not including values that are possible but aren't in the population at all
      let counts table:counts values ;;we don't actually care about these counts...
      let instances sort table:keys counts ;;but we care about how many unique values there are in the population (the keys)! (this is instances), e.g. [1 2 3]
      let n length instances ;;nr of values/instances for this feature, e.g. 3


      let counts-table table:counts [most-likely-value plot-feature] of people ;;using the handy most-likely-value agent reporter
                                                                               ;;[most-likely-value plot-feature] of people is a list of all agent's top choice for the feature, e.g. [1 2 1 3 3 3]
                                                                               ;;table:counts makes it into a table where the entry is the occurences of the key in the list, e.g. {{table: [[1 2] [2 1] [3 3]]}}
                                                                               ;    let instances sort table:keys counts ;;instance = a specific value for a WALS feature (getting confusing here - the value is the table key :)) ;;so instances is a list, e.g. [1 2 3 4]
                                                                               ;    let n length instances ;;how many values there are
      set-plot-x-range 0 n ;;scales the plot to fit the number of instances/values we need to visualize
      set-plot-y-range 0 (nr-slaves + nr-colonists)
      let step 0.005 ;;tweak this to leave no gaps
                     ;;the plotting loop:
      (foreach instances range n [
        [s i] ->

        let y "NA" ;;placeholder before the ifelse that sets it
        ifelse table:has-key? counts-table s [ ;;if it has the key:
          set y table:get counts-table s ;;nr of agents with this value as their top choice (looks it up in the table)
        ]
        [ ;;if it doesn't have the key, it means no agents have it as their top value (but we still want to visualize the 0 bar, that's why we're keeping this here)
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

    if plot-this = "average probability" [ ;;for each possible value, plots the average probability of choosing that value across all agents!
                                           ;;for each value for plot-feature (the chosen WALS feature), we calculate the average probability (across agents) for each value/instance for this feature
                                           ;;using the handy 'avg-value-prob' reporter
                                           ;;we want to visualize ALL the possible values (in the population) all the time (no change of nr of bars)!

      let values reduce sentence [known-values plot-feature] of people ;;list with all known values for all people, i.e. [3 2 1 1 3 2 1 3 2 2 3 1 1 ...]
                                                                       ;;@not including values that are possible but aren't in the population at all
      let counts table:counts values ;;we don't actually care about these counts...
      let instances sort table:keys counts ;;but we care about how many unique values there are in the population (the keys)! (this is instances), e.g. [1 2 3]
      let n length instances ;;nr of values/instances for this feature, e.g. 3
      set-plot-x-range 0 n ;;scales the plot to fit the total number of instances/values
      set-plot-y-range 0 1
      let step 0.001
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

    if plot-this = "times chosen" [ ;;for each possible value, plot count of how many times it's been actually spoken/chosen in this run (CUMULATIVE!)
                                    ;;for setting the range/plotting bars
      let values reduce sentence [known-values plot-feature] of people ;;list with all known values for all people, i.e. [3 2 1 1 3 2 1 3 2 2 3 1 1 ...]
                                                                       ;;@not including values that are possible but aren't in the population at all
      let counts2 table:counts values ;;we don't actually care about these counts...
      let instances sort table:keys counts2 ;;but we care about how many unique values there are in the population (the keys)! (this is instances), e.g. [1 2 3]
      let n length instances ;;nr of values/instances for this feature, e.g. 3

      let counts-list table:get chosen-table plot-feature
      ;;chosen-table is a table with counts of how many times each value has been chosen for this feature so far, through indexing using the value nr (? = 0)
      ;;i.e.: entry (and thus chosen-list) for key "X9A" = [0 1 0 2 0 0 0 0 0 0] = value 1 has been chosen once, value 3 has been chosen twice
      ;;set-plot-y-range 0 (length agreement + 1)
      set-plot-x-range 0 n ;;scales the plot to fit the number of instances/values we need to visualize
      let step 0.02 ;;tweak this to leave no gaps
                    ;;the plotting loop:
      (foreach instances range n [
        [s i] ->
        let y item s counts-list ;;the nr of times this value has been chosen (using indexing because that's the structure of chosen-table and counts-list)
        let c item s color-list ;;so i.e. 'value 1' is always associated with item 1 in color-list (a specific color)
        create-temporary-plot-pen (word s) ;;the instance/value name made into a string
        set-plot-pen-mode 1 ;;bar mode
        set-plot-pen-color c
        let wee (range 0 y step)
        foreach (range 0 y step) [_y -> plotxy i _y]
        set-plot-pen-color black
        plotxy i y
        set-plot-pen-color c ;;to get the right color in the legend
      ])
    ]
  ] ;end of ticks mod 6

end

to update-convergence-plot ;;run in go (and setup). Visualizes convergence for the island as a whole
  if ticks mod 6 = 0 [ ;only updates every 6 months
    let proportion-list []
    foreach feature-list [
      the-feature ->
      let counts-table table:counts [most-likely-value the-feature] of people ;;e.g.: {{table: [[2 61] [1 38] [3 1]]}} ;;key = value, entry = nr of agents with this as top pick
      let counts-list table:to-list counts-table ;;make it a nested list, e.g.: [[2 61] [1 38] [3 1]]
                                                 ;;find the most common top pick (for this specific plot-feature):
      let index position (max map last counts-list) (map last counts-list) ;;example: would be 0 (since item 0 is most common top pick, with 61 agents with value 2)
      let global-top-value first item index counts-list ;;the value - e.g. 2
                                                        ;;calculate the proportion of the population with this as their top pick:
      let nr-top-pickers last item index counts-list ;;nr of agents picking this top value - e.g. 61
      let nr-agents sum map last counts-list ;;e.g. 100 (61 + 38 + 1)
      let proportion ( nr-top-pickers / nr-agents )
      ;;and THAT proportion is what we want to plot!:
      set proportion-list lput proportion proportion-list
      ;;print proportion-list
    ]
    ;;proportion-list is now: [0.37 0.6 0.99 0.55 0.43 0.56 0.42 ...] with 50 entries, one for each feature, showing the proportion of agents with the most common top pick as their top pick!

    ;;PLOTTING:
    set-current-plot "Convergence plot"
    clear-plot
    let n 50 ;;nr of bars we want (the nr of WALS features)
    set-plot-x-range 0 n
    set-plot-y-range 0 1
    let step 0.005 ; tweak this to leave no gaps
    (foreach proportion-list range n [
      [y i] ->
      ;;let c one-of base-colors ;;random colors right now
      create-temporary-plot-pen (word y) ;;the proportion, e.g. "0.37"
      set-plot-pen-mode 1 ; bar mode
                          ;;set-plot-pen-color c
      ifelse y >= 0.75 [
        set-plot-pen-color 64 ;;green
      ]
      [
        if y >= 0.50 [set-plot-pen-color 44] ;;yellow
        if y < 0.50 [set-plot-pen-color 14] ;;red
      ]
      foreach (range 0 y step) [ _y -> plotxy i _y ]
      set-plot-pen-color black
      plotxy i y
      ;;set-plot-pen-color c ; to get the right color in the legend
    ])
  ]


end



;;---USEFUL FUNCTIONS AND REPORTERS FOR HANDLING AGENTS' LANGUAGE TABLES:

to-report known-value? [feature value] ;;agent reporter (uses the agent's my-lang-table), takes a feature and value as input
  ;;reports a boolean: whether or not an agent already knows this specific value/instance of this specific WALS feature

  let item-odds-list "NA"
  ifelse is-number? value [ ;if it's a feature:
  set item-odds-list table:get my-lang-table feature ;;the list of known values and odds associated with the WALS feature
  ]
  [ ;if it's a word:
    set item-odds-list table:get my-word-table feature
  ]

  ;;now to remove the odds which we don't care about for this:
  let value-list map first item-odds-list ;;a list of all known values for this feature (with the odds removed)
  ifelse member? value value-list [report true] [report false] ;;checks whether the value of interest (input to this reporter) is in the known value list
end

to-report known-values [feature] ;;agent reporter. for a specific WALS feature, returns a list of all the values the agent knows (just the values, no odds!)
  let item-odds-list "NA"
  ifelse member? feature word-list [
    ;if it's a word:
    set item-odds-list table:get my-word-table feature
  ]
  [ ;if it's a feature:
    set item-odds-list table:get my-lang-table feature
  ]
  report map first item-odds-list
end

to-report get-odds [feature value] ;;agent reporter. Returns the agent's associated odds for a specific value/instance of a specific WALS feature
  ifelse known-value? feature value [ ;;this only runs if the value is known!
    let item-odds-list "NA"
    ifelse is-number? value [ ;if it's a feature:
      set item-odds-list table:get my-lang-table feature ;;the nested list of known value-odds pairs associated with the WALS feature
    ]
    [ ;if it's a word:
      set item-odds-list table:get my-word-table feature ;same but for the words
    ]

    ;;the nested list of known value-odds pairs associated with the WALS feature
    let the-pair filter [i -> first i = value] item-odds-list ;;locates the value-odds pair of interest, discards the rest
    report item 1 item 0 the-pair ;;returns the odds associated with this value (item 1 item 0 starter inderst - så vi vil have det andet element fra den første liste)
  ]
  [ ;;@if they don't actually know this value, instead of an error and crashing, now returns NA:
    report "NA"
  ]
end

to-report is-adult?
  ifelse age > 17 [
    report true
  ]
  [
    report false
  ]
end

to-report weighted-one-of [nested-list] ;;agent reporter, more general [[valg1 odds] [valg2 odds] [valg3 odds] ...]
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
  let the-table "NA"
  ifelse is-number? value [ ;if it's a feature:
    set the-table my-lang-table
  ]
  [ ;if it's a word:
    set the-table my-word-table
  ]

  let new-value list value odds ;;e.g. in the form [3 1] or for words: [cSANoword3 1]
  let old-entry table:get the-table feature ;;the value-odds-list (or words and odds)
  let new-entry lput new-value old-entry
  table:put the-table feature new-entry ;;table:put automatically overwrites the old entry


  ;;@now doesn't catch if they already know the value (can add that safety?) - or should only be used in conjunction with known-value?
end

;; we now have an odds-manipulator for succesful increase (successful speaker + hearer), unsuccessful increase (unsuccessful hearer) and decrease (unsuccessful speaker) - for both kids and adults.
to increase-odds-success [feature value] ;;agent reporter. increases the odds for a specific value/instance of a specific WALS feature (or word)
  ifelse known-value? feature value [

    let the-table "NA"
    ifelse is-number? value [ ;if it's a feature:
      set the-table my-lang-table
    ]
    [ ;if it's a word:
      set the-table my-word-table
    ]

    let value-odds-list table:get the-table feature ;;the nested list of known value-odds pairs associated with the WALS feature (e.g. [[0 2] [1 4] [2 1]]
    let the-pair item 0 filter [i -> first i = value] value-odds-list ;;locates the value-odds pair of interest, discards the rest (e.g. [[1 4]])
    let index position the-pair value-odds-list ;;the position of the value-odds pair
    let old-odds item 1 the-pair ;;the-pair is a non-nested list for these purposes

    let increase "NA"
    ifelse is-adult? [ ;the increase depends on whether they're a child
      set increase odds-increase-successful ;set in interface
    ]
    [
      set increase kids-odds-inc-success ;for kids, set in interface
    ]

    let new-odds old-odds + increase ;;@can maybe change this increase depending on different things?

    let new-entry replace-subitem 1 index value-odds-list new-odds ;;using the replace-subitem function, indexing from the innermost list and outwards
    table:put the-table feature new-entry ;;table:put automatically overwrites the old entry for this feature
  ]
  [ ;if they don't know it, simply learn it with starting odds of the odds increase:
    learn-value feature value odds-increase-successful
  ]
end



to increase-odds-unsuccess [feature value] ;;agent reporter. increases the odds for a specific value/instance of a specific WALS feature - now simply by 1!
  ;;@can make it so it only runs if the value is known? (like get-odds function) - but probably not necessary if we always use it together with known-value anyway!
  ifelse known-value? feature value [

    let the-table "NA"
    ifelse is-number? value [ ;if it's a feature:
      set the-table my-lang-table
    ]
    [ ;if it's a word:
      set the-table my-word-table
    ]

    let value-odds-list table:get the-table feature ;;the nested list of known value-odds pairs associated with the WALS feature (e.g. [[0 2] [1 4] [2 1]]
    let the-pair item 0 filter [i -> first i = value] value-odds-list ;;locates the value-odds pair of interest, discards the rest (e.g. [[1 4]])
    let index position the-pair value-odds-list ;;the position of the value-odds pair
    let old-odds item 1 the-pair ;;the-pair is a non-nested list for these purposes

    let increase "NA"
    ifelse is-adult? [ ;the increase depends on whether they're a child
      set increase odds-increase-unsuccessful ;set in interface
    ]
    [
      set increase kids-odds-inc-unsuccess ;for kids, set in interface
    ]

    let new-odds old-odds + increase
    let new-entry replace-subitem 1 index value-odds-list new-odds ;;using the replace-subitem function, indexing from the innermost list and outwards
    table:put the-table feature new-entry ;;table:put automatically overwrites the old entry for this feature
  ]
  [ ;if they don't know it, simply learn it with starting odds of the odds increase:
    learn-value feature value odds-increase-unsuccessful
  ]
end



to decrease-odds [feature value] ;;agent reporter. decreases the odds for a specific value/instance of a specific WALS feature - now simply by -1! (but never to 0)
  if known-value? feature value [ ;only runs if the value is known

    let the-table "NA"
    ifelse is-number? value [ ;if it's a feature:
      set the-table my-lang-table
    ]
    [ ;if it's a word:
      set the-table my-word-table
    ]

    let value-odds-list table:get the-table feature ;;the nested list of known value-odds pairs associated with the WALS feature (e.g. [[0 2] [1 4] [2 1]]
    let the-pair item 0 filter [i -> first i = value] value-odds-list ;;locates the value-odds pair of interest, discards the rest (e.g. [[1 4]])
    let index position the-pair value-odds-list ;;the position of the value-odds pair
    let old-odds item 1 the-pair ;;the-pair is a non-nested list for these purposes

    let decrease "NA"
    ifelse is-adult? [ ;the decrease depends on whether they're a child
      set decrease odds-decrease ;set in interface
    ]
    [
      set decrease kids-odds-dec ;for kids, set in interface
    ]

    let new-odds old-odds + decrease
    if new-odds < 1 [
      set new-odds 1
    ] ; the minimum odds for a known value is 1. If the new-odds results in a value of less than 1, 1 is put in its place. This is a simple fix, so we can decrease with a number bigger than 1.

    ;  if old-odds > 1 [ ;;odds can never get below 1
    ;  if old-odds > 3 [ ;;odds can never get below 3 ; this is to avoid 0-values when decrease is at -3
    ;    let new-entry replace-subitem 1 index value-odds-list new-odds ;;using the replace-subitem function, indexing from the innermost list and outwards
    ;    table:put the-table feature new-entry ;;table:put automatically overwrites the old entry for this feature

  ] ;end of if known-value?

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
  let prob-list [my-value-prob plot-feature value] of people ;;list of all agent's probs for this value, e.g. [0.9595959595959596 0.9770114942528736 1 ...]
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

;;@NEW SHEETS where ?-values have been replaced with 0's!: https://docs.google.com/spreadsheets/d/1znq4HicKo-HyFHaqe_ykKX5iduJ1Ky1xXuPdxafLs0E/edit#gid=1492588531
;;new downloadable link: https://docs.google.com/spreadsheets/d/1znq4HicKo-HyFHaqe_ykKX5iduJ1Ky1xXuPdxafLs0E/gviz/tq?tqx=out:csv

to import-csv
  fetch:url-async "https://docs.google.com/spreadsheets/d/1znq4HicKo-HyFHaqe_ykKX5iduJ1Ky1xXuPdxafLs0E/gviz/tq?tqx=out:csv" [
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

;;@ALTERNATIVT KAN FILEN HENTES LOKALT MED DENNE FUNKTION (men den skal vælges manuelt hver gang...) :
to test-fetch-user-file-verbose-syntax
  clear-all
  fetch:user-file-async [text -> show text]
end






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
  ask patches with [pycor < -82] [set pcolor red]
end

to color-map
  ask patches with [pcolor = red] [set pcolor blue - 2 + random-float 2]
  ask patches with [pcolor = green] [set pcolor green + 0.2 + random-float 0.8]
end
@#$#@#$#@
GRAPHICS-WINDOW
230
10
960
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
725
530
788
563
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
790
530
853
563
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
235
305
292
350
Month
this-month
17
1
11

MONITOR
290
305
347
350
Year
year
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
110
345
220
390
partner-choice
partner-choice
"random" "closest-one" "nearby" "nearby-or-random" "weighted-proximity" "(fra min plantage)" "(fra tilfældig anden plantage)" "(fra naboplantage)"
0

INPUTBOX
10
145
75
205
nr-slaves
50.0
1
0
Number

PLOT
985
240
1205
480
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
985
190
1077
235
plot-feature
plot-feature
"X9A" "X10A" "X18A" "X27A" "X28A"
0

CHOOSER
1080
190
1205
235
plot-this
plot-this
"max value (count)" "average probability" "times chosen"
0

TEXTBOX
1215
255
1395
476
- max value (count): hvor mange der har den value som top choice\n\n- average probability: gennemsnitlig sandsynlighed over alle agenter for at vælge præcis den value for den feature\n\n- times chosen: kumulativ optælling af, hvor mange gange den værdi er valgt (af hearer eller speaker) for den værdi\n\n
12
0.0
1

BUTTON
1035
480
1155
513
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
940
515
1240
545
Denne knap kan bruges til at opdatere plottet, hvis du ændrer plot-feature eller plot-this, mens modellen ikke kører.
11
0.0
1

BUTTON
755
435
850
468
NIL
color-by-lang
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
755
390
850
435
color-feature
color-feature
"X9A" "X10A"
0

TEXTBOX
860
391
980
456
@coloring by most likely value for that feature now (colors match the ones in feature plot)
11
0.0
1

TEXTBOX
100
505
155
523
Samtaler
14
0.0
1

TEXTBOX
55
310
160
328
Partner-selektion
14
0.0
1

TEXTBOX
415
360
495
378
Sproglæring
14
0.0
1

TEXTBOX
815
365
895
390
Visualisering
14
0.0
1

SLIDER
5
525
145
558
nr-features-exchanged
nr-features-exchanged
1
10
3.0
1
1
NIL
HORIZONTAL

SWITCH
10
30
130
63
include-words?
include-words?
0
1
-1000

TEXTBOX
80
125
150
143
Demografi
14
0.0
1

INPUTBOX
70
65
130
125
start-odds
40.0
1
0
Number

SLIDER
285
430
440
463
odds-increase-successful
odds-increase-successful
0
3
1.0
1
1
NIL
HORIZONTAL

SLIDER
285
530
440
563
odds-decrease
odds-decrease
-3
0
-1.0
1
1
NIL
HORIZONTAL

INPUTBOX
75
145
140
205
nr-colonists
50.0
1
0
Number

TEXTBOX
1020
595
1425
640
Satterfield 2008 outcome: hvor meget ændrer grammatik og lexicon sig på individ- og alle-niveau? hvor stor ændring? (ikke hvilken retning) eller hvor langt er agenterne fra deres startsprog?
11
0.0
1

TEXTBOX
1200
550
1495
595
Som i Parkvall 2013: vis i %: hvor meget minder agenternes sprog/wals-features om Dutch creole? (cVIDd) (kan evt. også farve dem)
11
0.0
1

INPUTBOX
10
65
70
125
nr-words
10.0
1
0
Number

PLOT
1290
10
1525
185
Convergence plot
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

TEXTBOX
1295
185
1520
245
convergence plot:\nfor each WALS feature, shows the proportion of agents that have the most common max value as their max value for that feature
11
0.0
1

MONITOR
1215
65
1285
110
Successes
success-count
17
1
11

MONITOR
1215
110
1285
155
Failures
fail-count
17
1
11

TEXTBOX
95
10
170
28
Sprog
14
0.0
1

TEXTBOX
135
75
210
125
start-odds are for both words and features
11
0.0
1

SWITCH
10
210
100
243
deaths?
deaths?
1
1
-1000

TEXTBOX
1410
295
1640
520
@not coded yet:\n- include-kids?\n- newcomers? and distribution-method\n- odds i partner-selektion\n- learning-update\n- global-chooser\n@also add: 1) 17 plantation districts + tilknyttelse, 2) starttilstand ift. sluttilstand (tilføj på convergence plot), 3) over-chooser som pre-setter parametre\n\nPLOT FOR ORD (fx 10 mest brugte ord)
13
12.0
1

SWITCH
100
210
190
243
children?
children?
0
1
-1000

SWITCH
110
245
215
278
newcomers?
newcomers?
0
1
-1000

TEXTBOX
40
425
190
443
Tilføj odds for hver mulighed:
11
0.0
1

INPUTBOX
10
440
80
500
random-one
2.0
1
0
Number

INPUTBOX
80
440
145
500
on-my-plantation
3.0
1
0
Number

INPUTBOX
145
440
210
500
neighbour-plantation
1.0
1
0
Number

INPUTBOX
10
335
100
395
convs-per-month
2.0
1
0
Number

TEXTBOX
110
390
260
416
(@slet partner-choice når odds-tilgangen er kodet)
11
0.0
1

SWITCH
145
525
265
558
include-status?
include-status?
1
1
-1000

SLIDER
440
430
595
463
kids-odds-inc-success
kids-odds-inc-success
0
5
2.0
1
1
NIL
HORIZONTAL

SLIDER
440
530
595
563
kids-odds-dec
kids-odds-dec
-3
0
-1.0
1
1
NIL
HORIZONTAL

SLIDER
10
615
240
648
%-understood-for-overall-success
%-understood-for-overall-success
0
100
60.0
5
1
%
HORIZONTAL

TEXTBOX
95
595
170
613
Forståelse
14
0.0
1

CHOOSER
285
385
595
430
if-overall-success
if-overall-success
"Both increase all speaker's values" "Both increase successful/matching values only" "Hearer increases all speaker's values" "Hearer increases successful/matching values only"
0

CHOOSER
715
480
860
525
choose-preset
choose-preset
"As Parkvall 2013" "As Satterfield 2008" "try this 1" "try this 2" "No Preset"
0

SLIDER
285
615
465
648
odds-increase-unsuccessful
odds-increase-unsuccessful
0
3
1.0
1
1
NIL
HORIZONTAL

SLIDER
465
615
645
648
kids-odds-inc-unsuccess
kids-odds-inc-unsuccess
0
5
5.0
1
1
NIL
HORIZONTAL

TEXTBOX
15
650
255
706
Hvor mange % af de udvekslede features og ord hearer skal forstå for at interaktionen er overall successful (forståelse = eksakt match)
11
0.0
1

SLIDER
10
245
102
278
dying-age
dying-age
0
100
50.0
1
1
NIL
HORIZONTAL

TEXTBOX
710
575
895
631
Parkvall: kun hearer opdaterer, ingen decrease, success er ca fail x2. kun en feature.
11
0.0
1

CHOOSER
10
280
215
325
distribution-method
distribution-method
"random plantation" "plantation with least similar speakers" "plantation with most similar speakers"
1

SWITCH
285
575
465
608
hearer-learns-from-failure?
hearer-learns-from-failure?
0
1
-1000

TEXTBOX
285
370
385
388
If overall success:
12
0.0
1

TEXTBOX
285
470
435
488
If overall failure:
12
0.0
1

CHOOSER
285
485
595
530
if-overall-failure
if-overall-failure
"Nothing happens" "Both decrease all speaker's values (if known)" "Both decrease unsuccessful values only (if known)"
1

TEXTBOX
470
570
660
610
If off, hearer follows 'if-overall-failure'. If on, hearer instead increases ALL speaker's values:
11
0.0
1

TEXTBOX
95
560
270
585
If on: colonists are always speakers in colonist-slave interactions
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

person-inspecting
false
0
Circle -7500403 true true 109 7 80
Polygon -7500403 true true 125 90 120 195 105 300 105 300 135 300 149 215 165 300 195 300 195 300 180 195 175 91
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 172 83 250 146 210 150 150 105
Polygon -7500403 true true 251 146 180 197 174 167 230 131
Polygon -7500403 true true 130 80 60 135 82 157 142 112
Polygon -7500403 true true 19 109 79 154 92 130 41 88

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
