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
  day-names ;;for keeping track of weekdays
]

people-own [ ;; human attributes
  age ;depends on age-distribution
  ;mental-health ;If we have time - kan evt have indflydelse på kreativity og hvorvidt man får sine social needs opfyldthttps://www.youidraw.com/apps/painter/
  social-needs ;- how much people need to socialize (bars + priv) It depends on social-needs-distribution
  ;my-social-houses ;not ready yet - Each household has a group of people (which can change over time). if a household solely consists of young then higher chance of gathering + more volume. #my-party-house depends -gust
  my-household
  my-workplace
  infected-at
  time-of-death ;;so every turtle only checks if they die ONCE every day (kinda sinister... @IBH: better solution?)
  will-show-symptoms? ;not rdy yet
  my-friends ;;agentset

  my-relatives ;;2-4 extra connections outside the agent's age group
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

  set day-names ["Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday"]

  create-schools  5 [
    set color gray
    set shape "house colonial"
    move-to max-one-of (patches with [not any? turtles-here]) [pxcor + pycor]
    set students (turtle-set)
  ]
  create-workplaces 10 [ ;@add more, to decrease number of agents in one spot? for meaningful max-here slider
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
    ;;@alderssammensætningen er stadig ret tilfældig/forsimplet og ikke baseret på statistik...
    let probability random-float 1
    if probability < 0.39                         [set placeholder 1]
    if probability >= 0.39 and probability < 0.72 [set placeholder 2]
    if probability >= 0.72 and probability < 0.84 [set placeholder 3]
    if probability >= 0.84 and probability < 0.95 [set placeholder 4]
    if probability >= 0.95 and probability < 0.99 [set placeholder 5]
    if probability >= 0.99                        [set placeholder 6]

    let household-members placeholder

    set members (turtle-set)
    hatch-people household-members [
      set shape "person"
      hide-turtle

      ;;@IBH: fix alderssammensætningen: den er stadig ret tilfældig/forsimplet og ikke baseret på statistik...
      ;;eg. a household of 5 is very likely to consist of 4 adults and a child...
      ;;(skriv: ask households [show [age-group] of members] i command center efter setup for at få et indblik i sammensætningen...)



      ;;make sure the first person created is always an adult or elder:
      ifelse not any? [members] of myself [
        while [age-group = "child"] [ set age age-distribution ]
      ]
      [
        set age age-distribution
      ]


      set social-needs social-needs-distribution
      set infected-at -1000
      set will-show-symptoms? false
      set my-household myself
      ask my-household [set members (turtle-set members myself)]
      if age < 20 [
        set my-workplace one-of schools
        ask my-workplace [set students (turtle-set students myself)]
      ]

      if age >= 20 [
        set my-workplace one-of workplaces
        ask my-workplace [set employees (turtle-set employees myself)]


        ]
      ]
    ]

  set-friend-group ;;denne funktion sætter en vennegruppe (agentset) for hver agent baseret på deres age group
  set-relatives ;;funktion, der giver alle 2-4 ekstra random connections ('relatives') uden for deres age group (my-relatives)

  ask n-of  (initial-infection-rate / 100 * count people) people [set infected-at -1 * random average-duration * 24] ;


  ask turtles [recolor]


  set time ticks mod 24 ;;every tick is one hour
  ask patches [set pcolor patch-color] ;;change colors depending on the time of day (see patch-color reporter)
  set str-time (word time ":00")
  if time < 10 [set str-time (word "0" str-time)]

  update-productivity-plot ;;initialize the productivity plot, plot the starting productivity value

end


to go
  every .01 [

    ;; update time
    set time ticks mod 24
    ask patches [set pcolor patch-color] ;;change colors depending on the time of day (see patch-color reporter)
    set str-time (word time ":00")
    if time < 10 [set str-time (word "0" str-time)]

    ;;; move people to jobs and schools:
    if time = 8 [
      if not weekend? and not close-workplaces? [
        ask workers [
          if not isolating? [ move-to my-workplace ]
        ]
      ]

      if not weekend? and not close-schools? [
          ask all-students [
            if not isolating? [ move-to my-workplace ]
          ]
         ]
    ] ;;end of if time = 8


;;socializing:


if time = 17 [
      ;;going to bars/stores:
      ;;@IBH: nu går alle på bar kl 17 - kan evt sprede det ud/gøre det mere realistik
      ifelse close-bars-and-stores?
        [ ask people [move-to my-household] ] ;;if closed
        ;;if open:
        [ ask people [
          ifelse age-group = "adult" or age-group = "young" and not isolating? ;&not at privat socialt arrangement?
            [
            ifelse weekday = "Thursday" or weekday = "Friday" ;;bigger chance of going out on these days
              [set placeholder random-float -0.75] ;;a number between -0.75 and 0 ;if we have a person with high social needs we now have a person who no matter what goes out on thursdays and fridays. @@@ - do we care though
              [set placeholder random-float -1] ;a number between -1 and 0]
            let chance placeholder
            ifelse chance + social-needs > 0 [ move-to one-of bars] [ move-to my-household ] ;;@:her kan vi ændre sandsynligheden for at gå på bar
            ;;@kan evt gøre, så de går på bar med folk fra deres vennegruppe (brug my-friends)
        ] ;^ Med de nuværende social-needs værdier har alle unge 20% chance. 70% af voksne har 14% chance og resten har 20%.
           ;Overvejer at lave en slider til både social-needs og intervallet ovenfor - for også at lave en "to report" med sandsynlighederne (lidt besværligt men tror jeg kan) -gus
            [move-to my-household] ;;if not adult

      ]
     ]
    ] ;;end of if time = 17



    ifelse weekday = "Friday" or weekday = "Saturday" [
      if time = 24 [ ask people [ move-to my-household] ]
    ]
    [
      if time = 20 [ ask people [ move-to my-household] ]
    ]


    ;;SKER HVERT TICK (no matter the time):

    ;; ask people who are infected to potentially infect others:

    ask people with [infected?] [

      ifelse isolating? ;;isolating? er true hvis de selv eller nogen fra deres husstand har symptomer
        [ ;;if isolating:
        ask other people-here with [random-float 1 < (0.2 * probability-of-infection) and not immune? and not infected?] [ ;;80% lower risk of infection if isolating
          set infected-at ticks
          ;;hvis de inficeres, sættes will-show-symptoms? med det samme:
          ifelse random-float 1 < (has-symptoms / 100)
           [set will-show-symptoms? true]
           [set will-show-symptoms? false]
        ]
      ]
      [ ;;if not isolating:
        ask other people-here with [random-float 1 < probability-of-infection and not immune? and not infected?] [ ;;normal risk of infection if not isolating
          set infected-at ticks
          ifelse random-float 1 < (has-symptoms / 100)
           [set will-show-symptoms? true]
           [set will-show-symptoms? false]
      ]
     ]


      ;;risk of infected people dying:

      ;the reporter my-survival-rate (prev. my-death-rate) reports probabilities for the whole duration of the infection
      ;we transform this value into per hour in the 10 days using the formula:
      ;                (1 - x)^n = %          or           1 - %^1/n = x
      ; in which % is survival rate for the whole period, n is iterations (duration of infection in days * 24 hours)
      ; x is the value we're looking for: probability of dying per iteration

        let my-destiny random-float 1
        if my-destiny < 1 - (my-survival-rate) ^ ( 1 / (average-duration * 24 ) ) [
          set total-deaths total-deaths + 1
          die
        ]
    ] ;;end of ask people with infected?

    ask turtles [recolor]
    if not weekend? and time = 12 [update-productivity-plot] ;;the productivity plot only updates once every weekday (see the reporter, using manual plot commands)
    if not any? people with [infected?] [stop] ;;model run stops if noone is infected
    tick
  ] ;;end of 'every .01' (the whole go procedure)
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
  report people with [age >= 20 and age <= 74]
end

to-report all-students
  report people with [age <= 20]
end

to-report working-at-home? ;;person reporter
  ;;IBH: if schools close, all adults in a household with kids also work from home, even if their workplace is open
  ifelse work-time? and age-group = "adult" and (close-workplaces? or is-homeschooling?)
    [report true]
    [report false]
end

to-report is-homeschooling? ;;person reporter
  ;;tager ikke hensyn til antal (eller alder) af børn og voksne i husstanden
  ifelse age-group = "adult" and work-time? and close-schools? and kids-in-my-household? ;;if adult + work-time + kids in the households, ALL adults there work from home
    [report true]
    [report false]
end
;;@IBH OBS: nu tager vi ikke højde for husholdninger med børn, men ingen adults! (hvis de kun bor med elders...) skal vi måske helt fjerne den sammensætning?


;;simple reporters to make code more readable:

to-report kids-in-my-household? ;;person reporter
  ifelse any? [members with [age-group = "child"]] of my-household ;;OBS: also returns true if the caller is themselves a child
    [report true]
    [report false]
end

to-report work-time? ;;reports true if it's a weekday and the time is between 8 and 16 (so people should be at work and school)
  ifelse time >= 8 and time <= 16 and weekday != "Saturday" and weekday != "Sunday"
    [report true]
    [report false]
end

to-report weekend?
  ifelse weekday = "Saturday" or weekday = "Sunday"
    [report true]
    [report false]
end


;; a simple population distribution from Danmarks Statistik, generalizing 3 age groups, corresponding to non-adults, adults and elders

to-report age-distribution
  ;oprindelig statistik:
  ;72% is the percentage of the population in Denmark above 17 and below 75 anno 2021 (DKs Statistik)
  ;20% below 18
  ;elders above 74, 8%
  ; lige nu vil der være omkring 30% af husholdninger med børn. Statistikken siger 28%, men måske det er tæt nok på. :)
  ; tjek med (count households with [ any? members with [ age < 18 ] ] ) / 700

  let this-number random-float 1

  ;children:

  if this-number < 0.24 [ ;;this way, around 20% of the population is below age 18
    report random 18
    report 1
  ]

  ;;adults and young:
  if this-number >= 0.24 and this-number < 0.925 [ ; this way, around 72% of the population is above 18 and below 75
    report 18 + random 57
  ]

  ;;elders:
  if this-number >= 0.925 [ ;this way, around 8% of the population above 74
    report 75 + random 26
  ]
end


to-report age-group ;;IBH: bruger de tre grupper fra DKs Statistik (ret forsimplet, men måske fint at holde det til tre): 0-17, 18-74, 75+
  if age <= 17 [ report "child" ] ;;initially 20 %
  if age > 17 and age < 28 [report "young" ] ;
  if age >= 28 and age < 75 [report "adult" ]
  if age >= 75 [ report "elder" ] ;;initially 8 %
end


to-report social-needs-distribution ;Der er noget galt med denne men kan ikke finde ud af hvad det er... -gus
  ;@LSG: Jeg har justeret parametrene til at være mere repræsentable OG mere simple (50/50 chance for hver gruppe - bortset fra unge, som alle er ens)
  ; @LSG: Evt. læg en smule random-float ind, så ikke alle agenter i samme gruppe er HELT ens

  if age-group = "child" [
    let chance random-float 1
    ifelse chance < 0.5 [ report 0.2 ] [ report 0.4] ;børn tager enten ud 20% eller 40% af tiden
  ]

  if age-group = "young" [
    report 0.5 ] ;unge tager ud halvdelen af tiden

  if age-group = "adult" [
    let chance random-float 1
    ifelse chance < 0.5 [ report 0.2 ] [ report 0.5 ] ; voksne tager enten ud 20% af tiden eller halvdelen af tiden
  ]

  if age-group = "elder" [
    let chance random-float 1
    ifelse chance < 0.5 [ report 0 ] [ report 0.2 ] ; ældre tager enten ud 20% af gange eller 0%
  ]
end

to-report my-friend-nr ;;people reporter. nr of friends (size of the agentset 'my-friend-group')

  if age-group = "child" [report 1] ;;@tweak these numbers? (can make it vary within the age-groups with random-float - but maybe not needed?)
  if age-group = "young" [report 3]
  if age-group = "adult" [report 2]
  if age-group = "elder" [report 1]
  ;;@IBH: for some reason, it looks like everybody ends up with an agentset of friends DOUBLE this number... instead of hunting down the cause, let's just roll with it for now :P
end


to set-friend-group ;;run in setup
  ;;IBH: jeg har tweaket koden fra det her link, så den virker med ny NetLogo-syntaks + vores populations-struktur:
  ;;https://stackoverflow.com/questions/32967388/netlogo-efficient-way-to-create-fixed-number-of-links
  ;;det er lidt komplekst, men burde virke

  ;;my-friend-nr is a reporter showing (@HALF OF!) how many friends this person will end up with


  ;;assumption: people are only friends with people in their own age group. Therefore we need to repeat this method once for each age group:

  foreach ["child" "young" "adult" "elder"] [ a -> ;;the loops goes through the code below once for each age category, replacing 'a' with the age group
    let pairs [] ;; pairs will hold the pairs of turtles to be linked
    while [ pairs = [] ] [ ;; we might mess up creating these pairs (by making self loops), so we might need to try a couple of times
      let half-pairs reduce sentence [ n-values my-friend-nr [ self ] ] of people with [age-group = a] ;; create a big list where each turtle appears once for each friend it wants to have
      set pairs (map list half-pairs shuffle half-pairs) ;; pair off the items of half-pairs with a randomized version of half-pairs
      ;;so we end up with a list like: [[ person 0 person 5 ] [ person 0 person 376 ] ... [ person 1 person 18 ]]
      ;;make sure that no turtle is paired with itself:
      if not empty? filter [ i -> first i = last i ] pairs [
        ;;print word "failure " a ;;this line used to troubleshoot (you can see how many times it needs repeating)
        set pairs [] ;;so if this list of self-pairs is not empty, we start over and try again (since some people were paired with themselves)
      ]
    ] ;;end of while pairs = []

    ;; now that we have pairs that we know work, create the links:
    foreach pairs [
      x -> ;;x is each item in the nested 'pairs'-list, i.e. each pair such as [person 1 person 7]
      ask first x [
        create-link-with last x [ ;;create-link-with is undirected
        hide-link ;;we don't want to visualise the links
        ]
      ]
    ]
    ;;print word "success " a ;;this line used to troubleshoot
    ] ;;end of the foreach loop

  ;;ask turtles to add their links to their friends!:
  ask people [
    set my-friends link-neighbors with [age-group = [age-group] of self] ;;my-friends is an agentset containing their friends (person variable)
    ;;link-neighbors assumption: if I'm your friend, you're also my friend :))
  ]
end

to set-relatives ;;run in setup
  let relative-nr 2 ;;udover deres vennegruppe, laver hver agent TO random forbindelser til folk fra andre aldersgrupper
    ;;(siden alle gør det, giver det hver agent MINDST to ekstra forbindelser uden for husholdningen på tværs af aldersgrupper (ekstra familie or whatever)
    ;;@no upper bound... but should be okay? the random max seems to lie around 8 relatives

  ;;everyone creates two random connections:
  ask people [
    let candidates other people with [age-group != [age-group] of myself]
    create-links-with n-of relative-nr other candidates [ hide-link ]
    set my-relatives link-neighbors with [age-group != [age-group] of myself]
  ]
end


to-report infected?
  report ticks >= infected-at and ticks <= infected-at + incubation-time + (average-duration * 24) ;infected-duration er sum af inkubationstid og sygetid (average duration)
end


to-report currently-symptomous? ;andel af inficerede med symptomer justeres på slider. Symptomer kommer efter inkubationstid, og stopper ved slutning af sygdomsforløb
  report infected-at != -1000 and ticks > ( infected-at + incubation-time) and will-show-symptoms? and ticks < (infected-at + incubation-time + average-duration)
end


;;should I go out?
to-report isolating? ;;people reporter
  ;;ifelse currently-symptomous? or ( any? [members] of my-household with [currently-symptomous?] )
  ifelse currently-symptomous? or ( any? [members with [currently-symptomous?]] of my-household )
    [report true]
    [report false]
end


to-report days-infected
  ifelse infected?
    [] ;;@
    [report 0]
end

to-report my-survival-rate
  ;;@could add 'deathliness of virus' to the interface, and a chooser 'depends-on-age?'

  ;; Probability of surviving the whole duration of infection
  ;;LSG: From what I've managed to find, the mortality rates in all groups except for elder is very low - <1% - do we want to add a low value?
  ;; https://www.ssi.dk/aktuelt/nyheder/2020/9500-danske-covid-19-patienter-kortlagt-for-forste-gang
  ;@revisit probabilities

  if age-group = "child" [report 1 - 0.0005] ;subtracting from 1 to get survival rate rather than mortality rate
  if age-group = "young" [report 1 - 0.0005]
  if age-group = "adult" [report 1 - 0.013]
  if age-group = "elder" [report 1 - 0.25]
end

to-report immune? ;;@nu antager vi, at alle bliver immune
  report has-been-infected? and infected-at + average-duration * 24 < ticks
end

to-report has-been-infected?
  report infected-at != -1000
end

to-report day
  report floor (ticks / 24)
end

to-report weekday ;;now the simulation always starts on a Monday
  let this-weekday day mod 7 ;;sets this-day from 0 to 6 (uses the day-reporter above)
  report item this-weekday day-names   ;;reports the current weekday name from the 'day-names' list
end

to-report productivity ;;people reporter for productivity plot (this reports the productivity of a single agent)
  ifelse age-group = "adult" or age-group = "young" [

    ifelse is-homeschooling? [
      report productivity-while-homeschooling / 100 ;;even if working from home AND homeschooling, we only calculate the homeschooling productivity
    ]
    [ ;;if not homeschooling:
      ifelse working-at-home? [
        report home-productivity / 100 ;;if working from home
      ]
      [ ;;if not working at home and not homeschooling (and adult or young):
        report 1
      ]
    ]
  ]
  [ ;;if not adult or young:
    report 0 ;;assumption: nu antages det, at børn og ældre ikke bidrager til produktiviteten...)
  ]

  ;;@include expenses-per-infection somewhere in these calculations? or in another economy plot?
end


to update-productivity-plot ;;run only at 12 every weekday! (see go procedure where this is called)
  set-current-plot "Productivity (average per person)"
  set-current-plot-pen "productivity"

  ;; AH: only calculating this for people who work
  let total-productivity sum [productivity] of workers ;;uses the productivity reporter above, sums for all people
  plot total-productivity / count workers ;;so the productivity plot plots the AVERAGE productivity (not affected by deaths...)
end



to-report patch-color ;;depends on the time of day
  if time = 0 or time >= 23 or time <= 4 [report 100] ;;nat
  if time >= 5 and time <= 10 [report 97] ;;morgen
  if time >= 11 and time <= 16 [report 95] ;;dag
  if time >= 17 and time <= 22 [report 103] ;;aften
end


;;plot reporters (hvor er folk?):
to-report people-at-home
  report count people-on households
end

to-report people-at-work
  report count people-on workplaces
end

to-report people-at-school
  report count people-on schools
end

to-report people-at-bar
  report count people-on bars
end

to-report people-at-visit
  report 0 ;;at a household, but not their own
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
17.5
.1
1
%
HORIZONTAL

SLIDER
5
480
230
513
home-productivity
home-productivity
0
200
83.0
1
1
% (of normal)
HORIZONTAL

MONITOR
485
10
594
55
Time of the Day
str-time
0
1
11

PLOT
775
10
1180
205
Infection rates
hours since start
% infected
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"% infected" 1.0 0 -16777216 true "" "plot ( count people with [infected?] / count people ) * 100"

PLOT
775
400
1180
595
Productivity (average per person)
NIL
NIL
0.0
10.0
0.0
2.0
true
false
"" ""
PENS
"productivity" 1.0 0 -16777216 true "" ""

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
1
1
-1000

SLIDER
5
515
230
548
productivity-while-homeschooling
productivity-while-homeschooling
0
100
75.0
1
1
%
HORIZONTAL

SLIDER
5
550
230
583
expenses-per-infection
expenses-per-infection
0
100
64.0
1
1
NIL
HORIZONTAL

TEXTBOX
40
455
190
473
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
0.02
0.00117
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
69.0
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
5.0
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
360
10
410
55
Day
Day
17
1
11

PLOT
775
205
1180
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
690
10
765
55
NIL
total-deaths
17
1
11

MONITOR
615
10
690
55
NIL
count people
17
1
11

PLOT
1210
10
1495
160
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

MONITOR
410
10
485
55
Weekday
weekday
17
1
11

SLIDER
10
225
235
258
max-people-restriction
max-people-restriction
0
100
25.0
1
1
NIL
HORIZONTAL

TEXTBOX
1185
485
1285
526
Productivity updates every weekday at 12:00.
11
0.0
1

SLIDER
10
407
232
440
has-symptoms
has-symptoms
0
100
73.0
1
1
%
HORIZONTAL

PLOT
1185
205
1495
400
Where are people currently?
Tid
Antal
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Home" 1.0 0 -13345367 true "" "plot people-at-home"
"Work" 1.0 0 -2674135 true "" "plot people-at-work"
"School" 1.0 0 -955883 true "" "plot people-at-school"
"Bar" 1.0 0 -13840069 true "" "plot people-at-bar"

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
