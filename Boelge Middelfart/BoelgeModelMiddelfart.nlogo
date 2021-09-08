extensions [csv table ]

globals [
  budget
  regn-i-simulationen

  water-pen


  start-wave ;; for drawing a wave
  end-wave ;; for drawing a wave, not sure we need it
  sea-patches
  edge-sea-patches
  land-patches
  house-patches ;for tilfredshed
  wall-patches
  mid-wall-patches

  drop-width k
  three-d?

  impact
  angle  ;; this can be used to easily create waves
  surface-tension
  friction

  minute ;keeping track of time
  hour
  day
  current-month ;only for auto-running
  current-year ;only for auto-running

  testing
  colortest
  terrainheighttest
  capacitytest
  satietytest
  satietypercenttest
  waterleveltest

  raining?
  ticks-rained
  nedbør-varighed-i-ticks

  avg-sea-level

  auto-table ;table used for auto-running a month based on data
  running-month?
  %-valgt ;saving %-ekstra-regn from interface
  hav-niveau-valgt
  periode-valgt
  total-auto-mængde
  ticks-at-start ;for plot
  colors-left ;so plot line colors don't repeat
  short-months ;used in update-time

  samlet-utilfredshed
  samlet-wall-utilfredshed
  tax-utilfredshed

  skatte-penge
]

breed [ drops drop] ;for rain animation
breed [ views view ] ;for rain animation

views-own [my-house-patches my-patches]

turtles-own [xpos ypos zpos delta-z neighbor-turtles]

patches-own [

  water-table

  depth base-height current-momentum next-momentum ;old wave stuff

  terrain-height ;baseret på kort fra DKs højdemodel
  soil-type
  satiety ;mæthedsgrad
  water-level

  my-wall-height
  my-wall-color
  my-wall-price

  missing-neighbors ;only used for edge-sea-patches
  view-patches ;patch-set for each house-patch containing all patches to the north of them (and within ? x-patches)
]

breed [momentums momentum]
momentums-own [force nearby-momentums forces-next-turn]

;to profile
;  setup                  ; set up the model
;  profiler:start         ; start profiling
;  ;start-rain ;start the rain (with interface settings) before the go to get some water in the system
;  run-period              ;start auto-raining period to get water in the system
;  repeat 100 [ go ]       ; run something you want to measure
;  profiler:stop          ; stop profiling
;  print profiler:report  ; view the results
;  profiler:reset         ; clear the data
;end

to setup-1
  set mm-per-15-min 5
  set nedbør-varighed 8
  set jordtype "Fint jord"
  set hav-niveau 0

end

to setup
  ca
  import-drawing "mf-map-kystfix-alpha55.png" ;draw city map overlay
  setup-house-patches ;used for tilfredshed
  setup-view-patches
  set-terrain-height
  setup-variables
  ask patches [recolor]
  reset-ticks
end

to setup-variables
  set minute "00"
  set day 1
  set hour 0
  set edge-sea-patches (patch-set sea-patches with [count neighbors < 8])
  ask edge-sea-patches [set missing-neighbors (8 - count neighbors)]
  ask sea-patches [
    set water-level 0 set satiety "sea" set terrain-height "sea"
    ;set pcolor white
  ] ;all land-patches automatically have water-level 0
  set raining? false
  ask patches [
    set my-wall-height "none"
  ]
  set wall-patches no-patches set mid-wall-patches no-patches
  set running-month? false
  set colors-left base-colors ;[105 65 15 44 134 25 34 4 125 115 black black black black black black] ;used for plot pens
  set short-months ["04" "06" "09" "11"] ;months with 30 days, used in update-time
  set budget 1000
end


to go
  set wall-patches (patch-set patches with [wall-patch?]) ;definerer her i stedet for reporter
  set mid-wall-patches wall-patches with [not any? neighbors with [not wall-patch?]] ;her i stedet for reporter

  set avg-sea-level mean [water-level] of sea-patches
  ask land-patches [set water-table avg-sea-level]

  if not running-month? [update-plot]

  ;MAYBE AUTO-RAIN FROM MONTH DATA:
  if running-month? [ ;if currently auto-running a month of rain:
    update-plot

    ifelse table:has-key? auto-table key-checker [ ;if the current date and time matches a time it should auto-rain:
      ;manual rain:
      let mm-rain table:get auto-table key-checker ;get the amount of rain for that hour
      ifelse mm-rain = "stop" [ ;hvis enden er nået:
        ask drops [die]
        set running-month? false ;end of the auto-running!
        stop
      ]
      [ ;if not the stopklods, but actual rain:
        ask patches [ set water-level ( water-level + ( mm-rain / 1000) ) ] ;in meters. all patches increase their water-level based on the rain this tick
        rain-animation
      ]
    ]
    [ ;if table doesn't have the current date+time:
      ask drops [die] ;remove rain animation
    ]
  ]

  ;MAYBE RAIN MANUALLY IF INTERFACE BUTTON WAS PRESSED:
  if raining? [rain-animation rainfall]

  ask land-patches [seepage] ;nedsivning  beregnet for hver patch (definition af land-patch?)
  ask patches [if water-level > 0 [move-water3]] ;afløb af vand til nabo-patches beregnet for hver patch (sea, land OG wall)
  ask patches [recolor] ;hver patch farves for at vise højden på det nuværende vandspejl

  update-samlet-utilfredshed ;så water-utilfredshed opdateres hvert tick
  update-time

  tick


  ;failsafe:
  if any? patches with [water-level < 0] [print "OH NO, A PATCH JUST HAD A NEGATIVE WATER LEVEL!" stop]
  if any? land-patches with [max-capacity < 0] [print "oh no, negative capacity!" stop]
end



to setup-house-patches ;used for tilfredshed, run in setup
  import-pcolors "mf-map-kystfix-alpha55.png" ;midlertidigt importeret for at sætte det her

  set house-patches (patch-set patches with [shade-of? pcolor yellow])

;  ask house-patches [
;    set view-patches (patch-set patches with [abs ( pxcor - [pxcor] of myself) <= 10  and pycor > [pycor] of myself] ) ;limited 'field of view'
;  ]
end

to setup-view-patches ;used for tilfredshed, run in setup
  create-views 10 [
    hide-turtle
    set my-house-patches (patch-set)
    set my-patches (patch-set)
  ]
  foreach range count views [ n ->
    let the-view one-of views with [not any? my-patches]

    ask the-view [
      let min-x -94 + n * 19
      let max-x -94 + ((n + 1) * 19)
      set my-patches patches with [pxcor >= min-x and pxcor < max-x ]
      ask my-patches [set pcolor green]
      set my-house-patches my-patches with [member? self house-patches ]
      let the-patches my-patches
      ask my-house-patches [set view-patches the-patches with [pycor > [pycor] of myself]]
    ]
  ]

end

to set-terrain-height
  import-pcolors "mf-terrain-grayscale.png"
  ask patches with [pcolor = white] [set pcolor sky] ;the sea
  ask patches with [pcolor = 89.9] [set pcolor 9.8] ;the extreme values, only a few patches
  ask patches with [pcolor = 39.9] [set pcolor 9.8]
  ;meget specifik finpudsning:
  let also-seapatches (patch-set patch 0 -2)
  ask also-seapatches [set pcolor sky]

  let kystklo-patches (patch-set patch 7 9 patch 12 9 patch 13 8 patch 15 8)
  ask kystklo-patches [set pcolor pink]

  set sea-patches patches with [pcolor = sky]
  set land-patches patches with [pcolor != sky]
  ;now pcolors range from 1.5 to 9.8 ...
  ;and the terrain should be from around 13.5 to 1.5 meters...

  ;@fix hvide i kloen (skal laves på kortet)

  ask land-patches [ set pcolor scale-color gray pcolor 12 3 ] ;invert dark and light colors
  ask kystklo-patches [set pcolor 2.4444444444444438 set terrain-height pcolor] ;manual kystklo-fixes
  ask land-patches [
    set terrain-height pcolor ;@but make sure the color is right!

    ;Transformation of the color into HEIGHT so it fits reality approximately:
    set terrain-height ((terrain-height * 1.3) - 1.5)

    set pcolor white
  ]
end

to show-test ;for testing height colors in set-terrain-height
  ;if not member? (patch mouse-xcor mouse-ycor) sea-patches [
    if mouse-inside? [
      ask patch mouse-xcor mouse-ycor [set colortest pcolor]
    ]

    if mouse-inside? [
      ask patch mouse-xcor mouse-ycor [set terrainheighttest terrain-height]
    ]

    if mouse-inside? [
      ask patch mouse-xcor mouse-ycor [
      ifelse member? self sea-patches [
        set capacitytest "sea"
      ]
      [
        set capacitytest max-capacity
      ]
    ]
    ]

    if mouse-inside? [
      ask patch mouse-xcor mouse-ycor [
      ifelse member? self sea-patches [
        set satietytest "sea"
      ]
      [
        set satietytest satiety
      ]
    ]
    ]

    if mouse-inside? [
      ask patch mouse-xcor mouse-ycor [
      ifelse member? self sea-patches [
        set satietypercenttest "sea"
      ]
      [
        set satietypercenttest satiety-percent
      ]
    ]
    ]

    if mouse-inside? [
      ask patch mouse-xcor mouse-ycor [set waterleveltest water-level]
    ]

  ;]
end



to-report patch-type-here
  ifelse mouse-inside? [
      if member? patch mouse-xcor mouse-ycor sea-patches [ ;SEA-PATCHES
        ifelse member? patch mouse-xcor mouse-ycor wall-patches
          [report (word "Mur (" [my-wall-height] of patch mouse-xcor mouse-ycor " m) i havet")] ;wall
          [report "Hav"] ;no wall
      ]
      if member? patch mouse-xcor mouse-ycor land-patches [ ;LAND-PATCHES
        ifelse member? patch mouse-xcor mouse-ycor wall-patches
          [report (word "Mur (" [my-wall-height] of patch mouse-xcor mouse-ycor " m), terrænhøjde " precision [terrain-height] of patch mouse-xcor mouse-ycor 2 " m")] ;wall
          [report (word "Land, terrænhøjde " precision [terrain-height] of patch mouse-xcor mouse-ycor 2 " m")] ;no wall
      ]

    ]
  [
    report "" ;if mouse not inside
  ]
end

to-report wl-here ;water-level
  ifelse mouse-inside? [
    report (word precision ([water-level] of patch mouse-xcor mouse-ycor * 1000) 4 " mm") ;@i millimeter
  ]
  [
    report ""
  ]
end

to-report unique-pcolor-nr ;to check granularity loss through using scale-color to manipulate terrain map
  ;set testing [pcolor] of patches
  ;report length table:keys table:counts testing
  report "commented out"
end

to color-correct-map
  ask patches with [shade-of? pcolor blue] [set pcolor blue]
  ask patches with [shade-of? pcolor red] [set pcolor brown]
  ask patches with [shade-of? pcolor orange] [set pcolor brown]
  ask patches with [shade-of? pcolor yellow] [set pcolor white]
  ask patches with [shade-of? pcolor brown] [set pcolor orange]
  ask patches with [shade-of? pcolor orange] [set pcolor 18]
  repeat 4 [ ask patches with [ count neighbors4 with [shade-of? pcolor blue ] >= 3 ] [set pcolor blue] ]
end

;---IMPORTANT WATER PROCEDURES:

to seepage ;(land-)patch procedure, nedsivning af vand i patches per tick. Run in go.
  ;REDUCER MÆTHEDSGRAD (RYGER UD AF SYSTEMET):
  let amount-norm ( seepage-m-per-s * seconds-per-tick ) ;kommer udelukkende an på jordtypen nu
                                                         ;@nu er det 0.9 meter for den hurtigste jordtype, 0.00009 m for den langsomste... (med et kvarter per tick, UDEN mæthed og vandspejl indregnet) ...
  if satiety > 0 [set satiety (satiety - amount-norm)] ;@hvis dette er det samme som den almindelige nedsivning (dog uden højde for mæthed), svarer det vel bare til at sende det videre til en 'ekstra patch'?
  if satiety < 0 [set satiety 0] ;satiety = hvor mange meter vand patchen indeholder (som er nedsivet)

  ;hver patch skal have en kapacitet af vand som er proportionel med højden på patchen og på porøsiteten (der kan vi bare bruge nedsivningskoefficienten).
  ;Baseret på hvor fuld den er kan vi så bestemme hvor hurtigt vand kan sive ind i den.
  ;Hvis du bare skriver det som en netlogo funktion så kan vi senere beslutte os for om den skal være lineær eller 1 / x så nedsivningen falder afh. af hvor fuld af vand patchen er.

  ;NEDSIVNING AF VAND (baseret på jordtype og mæthed) (@hvad med vandspejlets højde?):
  let amount-seeped amount-norm * (1 - satiety-percent) ;jo mere mæt, jo mindre siver ned ;@simpel lineær nu
  if amount-seeped > water-level [set amount-seeped water-level] ;amount-seeped må ikke være større end water level!!!

  ;OPDATÉR MÆTHEDSGRAD:
  set satiety ( satiety + amount-seeped ) ;satiety = simply how many meters of water is currently absorbed in the patch ;there's also satiety-percent reporter
  if satiety > max-capacity [ ;if capacity is reached:
    let extra (satiety - max-capacity)
    set satiety max-capacity
    set amount-seeped ( amount-seeped - extra ) ;remove the extra from amount-seeped so it stays part of the current water-level
  ]

  ;UPDATE WATER LEVEL:
  if water-level != 0 [ set water-level ( water-level - amount-seeped ) ]
  if water-level < 0 [set water-level 0]
end

to-report max-capacity ;patch reporter. Mætheds/vand-kapacitet (målt i hvor mange meter vand den kan holde?)
  ;jordtype og højde
  let scaler 2 ;@fix this scale
  let capacity-multiplier (terrain-height - avg-sea-level * 2 ) / terrain-height

  let final-max-capacity (terrain-height * seepage-m-per-s ) * capacity-multiplier * 500

  report ifelse-value (final-max-capacity > 0) [final-max-capacity] [0]
;
;
;
;  ifelse ( (terrain-height - avg-sea-level * 1.4) * seepage-m-per-s * scaler ) > 0 [
;    report (terrain-height - avg-sea-level) * seepage-m-per-s * scaler ;jo hurtigere nedsivning, jo grovere jord, og jo større kapacitet før mæthed...
;  ]
;  [
;    report 0 ;så den ikke bliver negativ...
;  ]


  ;@er forholdet rigtigt? skal tallet tweakes? ;@enhed??? i meter???
  ;@LIGE NU ALT FOR LAV!!!
  ;@fix
end

to-report current-capacity
  ;
end

to-report satiety-percent ;patch reporter
  ifelse max-capacity = 0 [report 0] [report satiety / max-capacity]
  ;@anden måde at beregne det på?
end

to move-water3 ;; all patches goer det her

    let distributor-height my-water-height
    let patch-fall-list [list self (water-distance-to distributor-height)] of neighbors with [my-water-height < distributor-height]
                     ;e.g [ [(patch 13 2) -0.17] [(patch 15 2) -0.0011] ... ]

    if length patch-fall-list != 0 [ ;if anyone's lower:

      let fall-list map last patch-fall-list
      let total-fall sum fall-list
      let avg-fall total-fall / ( length fall-list ) ;average fall/difference down to all the neighbors with lower total water levels (negative number!)

      ;TAG HØJDE FOR KANT-SEA-PATCHES, de skal desuden sende vand videre ud i 'intetheden'/til patches ude af systemet:
      if member? self edge-sea-patches [
        let outside-patch list no-patches avg-fall ;@hvor stort skal 'faldet' ud til intetheden være? (nu bare gennemsnittet ned til andre lavere patches)
        repeat 12 [set patch-fall-list lput outside-patch patch-fall-list] ;missing-neighbors is the nr of outside neighbors ;@nu bare tilfældigt 12 - send en masse videre ud! (tilfører ekstra vand!)
      ]

      ;@BEREGN HVOR MEGET VAND DER I ALT SKAL FLYTTES
      let excess-water (abs avg-fall)  ;@FIX OG TWEAK - HVOR MEGET VAND SKAL FLYTTES?

      if excess-water > water-level [set excess-water water-level] ;@men hvad med sea-patches tæt på land hvis sea-level er højt?

      ;FORDEL VANDET PROPORTIONELT TIL NABO-PATCHES (som ligger lavere)
      let water-moved 0 ;keeping track of it (if it doesn't end up being exactly excess-water, so all water stays in the system)
      foreach patch-fall-list [ ;loop over hver (lavere) nabo
        pair ->
        let the-patch item 0 pair let the-fall item 1 pair
        let prorated-value (the-fall / total-fall) * excess-water ;let proratedValue (basis / basisTotal) * prorationAmount
        ask the-patch [ set water-level (water-level + prorated-value) ] ;if an outside sea-patch, the-patch is an empty patch-set, and the water just disappears out of the system
        set water-moved (water-moved + abs prorated-value) ;keeping track
      ]
      set water-level (water-level - water-moved) ;the original patch now lowers its level accordingly
      if water-level < 0 [set water-level 0] ;pga små decimal-forskelle med floats, sikrer her, at water-level aldrig går i minus
                                             ;print (word "and after: " water-level)
    ]

  ;tag højde for WALL-PATCHES OMGIVET AF ANDRE WALL-PATCHES (så vandet ikke bliver liggende ovenpå):
  if member? self mid-wall-patches and water-level > 0 [
    if any? neighbors with [not member? self mid-wall-patches] [
      ask one-of neighbors with [not member? self mid-wall-patches] [ set water-level water-level + [water-level] of myself ] ;just move all water to a non-mid-patch...
      set water-level 0 ;and call it a day ;)
    ]
  ]
end


to move-water ;patch procedure, sker efter seepage procedure (random rækkefølge af patches), run in go (for patches with water-level != 0)
  ;AFLØB AF VAND TIL NABO-PATCHES
  ;BEREGN GENNEMSNITLIGT FALD FRA MIT VAND TIL NABO-PATCHES' VAND (hvis lavere):

  if member? self land-patches or wall-patch? [ ;LAND-PATCHES AND WALL-PATCHES (in sea or on land):

    let distributor-height my-water-height
    let patch-fall-list [list self (water-distance-to distributor-height)] of neighbors with [my-water-height < distributor-height] ;også sea-patches! ;e.g [ [(patch 13 2) -0.17] [(patch 15 2) -0.0011] ... ]

    if length patch-fall-list != 0 [ ;if anyone's lower:
      let fall-list map last patch-fall-list
      let total-fall sum fall-list
      let avg-fall total-fall / ( length fall-list ) ;average fall/difference down to all the neighbors with lower total water levels (negative number!)

      ;TAG HØJDE FOR KANT-SEA-PATCHES, de skal desuden sende vand videre ud i 'intetheden'/til patches ude af systemet:
      if member? self edge-sea-patches [
        let outside-patch list no-patches avg-fall ;@hvor stort skal 'faldet' ud til intetheden være? (nu bare gennemsnittet ned til andre lavere patches)
        repeat missing-neighbors [set patch-fall-list lput outside-patch patch-fall-list] ;missing-neighbors is the nr of outside neighbors
      ]

      ;@BEREGN HVOR MEGET VAND DER I ALT SKAL FLYTTES
      let excess-water (abs avg-fall) / 2 ;@FIX OG TWEAK - HVOR MEGET VAND SKAL FLYTTES?
      if excess-water > water-level [set excess-water water-level] ;@men hvad med sea-patches tæt på land hvis sea-level er højt?

      ;FORDEL VANDET PROPORTIONELT TIL NABO-PATCHES (som ligger lavere)
      let water-moved 0 ;keeping track of it (if it doesn't end up being exactly excess-water, so all water stays in the system)
      foreach patch-fall-list [ ;loop over hver (lavere) nabo
        pair ->
        let the-patch item 0 pair let the-fall item 1 pair
        let prorated-value (the-fall / total-fall) * excess-water ;let proratedValue (basis / basisTotal) * prorationAmount
                                                                  ;show (word "fall: " the-fall ", prorated-value: " prorated-value)
        ask the-patch [ set water-level (water-level + prorated-value) ] ;if an outside sea-patch, the-patch is an empty patch-set, and the water just disappears out of the system
        set water-moved (water-moved + abs prorated-value) ;keeping track
      ]
      ;print (word "water moved: " water-moved) print (word "distributor level before: " water-level)
      set water-level (water-level - water-moved) ;the original patch now lowers its level accordingly
      if water-level < 0 [set water-level 0] ;pga små decimal-forskelle med floats, sikrer her, at water-level aldrig går i minus
                                             ;print (word "and after: " water-level)
    ]
  ]

  if member? self sea-patches and not wall-patch? [ ;SEA-PATCHES:
    let sea-neighbors (patch-set self neighbors with [member? self sea-patches and not wall-patch?])
    let avg-water-level mean [water-level] of sea-neighbors
    ask sea-neighbors [set water-level avg-water-level]
  ]

end

to start-rain ;button in interface
  let this-duration round ( nedbør-varighed * 4) ;dette regnskyls varighed i ticks
  show this-duration

  ifelse raining? [
    ;if it was already raining:
    set nedbør-varighed-i-ticks ( nedbør-varighed-i-ticks + this-duration )
  ]
  [ ;hvis det ikke allerede regnede:
    set nedbør-varighed-i-ticks this-duration
    set ticks-rained 0
  ]
  set raining? true
  let total-rain mm-per-15-min * nedbør-varighed * 4




  set regn-i-simulationen (word total-rain " mm regn over " nedbør-varighed " timer")

end

to rainfall ;patch procedure. køres i go if raining? = true (aktiveret med knap i interface via start-rain procedure), fortsætter herefter selv i den bestemte varighed
  ;fra interface: bruger mængde og varighed

  ask patches [ ;@ALLE - både sea-, land- og wall-patches
    set water-level ( water-level + ( mm-per-15-min / 1000) ) ;in meters. all patches increase their water-level based on the rain this tick
  ]
  set ticks-rained ( ticks-rained + 1 )
  if ticks-rained = nedbør-varighed-i-ticks [ ;when the rainfall is over
    set raining? false
    set ticks-rained 0
    ask drops [die]
  ]
end

to rain-animation ;run in go if it's raining
  if vis-regn? [

  ifelse count drops = 0 [ ;if it's the first rain tick:
    ask n-of (count patches / 30) patches [
      sprout-drops 1 [
        set shape "drop" set size 2 set color [110 160 255 100] ;RGBA color (last number is alpha to make it semi-transparent)
          ;[170 220 255 100] ;old color
        set heading 180
      ]
    ]
  ]
  [ ;if they're already created:
    ask drops [
      fd 4
      if ycor = min-pycor [ setxy xcor max-pycor ]
    ]
  ]

  ]
end

to oversvøm ;forever button in interface, can try to raise the sea level (tidligere hæv-havet) ...
  ;@bare animation, disconnected fra den dynamiske model... kun farver, ikke egentlig forandring i water-level! (der har vi hæv-havet i stedet)
  every 0.1 [ update-samlet-utilfredshed ]

  ask patches [
    ifelse member? self wall-patches [
      ifelse member? self land-patches and my-wall-height + terrain-height < hav-stigning and any? neighbors with [shade-of? pcolor sky or pcolor = 102] [
        set pcolor 102 ;dark blue for oversvømmede wall-patches
      ]
      [
        ifelse member? self sea-patches and my-wall-height < hav-stigning and any? neighbors with [shade-of? pcolor sky or pcolor = 102]
          [set pcolor 102] ;wall-patches in the sea
          [set pcolor my-wall-color] ;wall-patches not underwater
      ]
    ]
      [
        ifelse member? self sea-patches [ ;sea-patches
          set pcolor sky
        ]
        [ ;land-patches:
          ifelse terrain-height < hav-stigning and count (neighbors with [shade-of? pcolor sky]) > 1 [ ;>1 for at undgå, at det sniger sig 'over mure' gennem hjørne-naboer hvis ikke helt lukket
            set pcolor sky
          ]
          [
            set pcolor white ;if landpatch and not underwater
          ]
        ]
      ]
    ]
  display
end

to hæv-havet
  ask sea-patches  [
   set water-level hav-niveau
  ]
end


to wave ;@VENT MED BØLGER
  ;fra interface: brug bølgehøjde og styrke
  ;bølgen har en højde

  ;hvis den kommer henover en bølgebryder, ryger vandet om på den anden side




end

;---BØLGEBRYDER-STUFF

to build-wall ;forever button in interface
  set wall-patches (patch-set patches with [wall-patch?])

  ifelse can-afford wall-cost [ ;hvis de har råd (wall-cost er reporter)
    if mouse-down? [
      ask patch mouse-xcor mouse-ycor [ ;både land-patches og sea-patches!
          set my-wall-height mur-højde ;fra interface
          set water-level 0 ;@(men hvad hvis hav-niveauet allerede er højere? tag højde for det!)
          let color-index position my-wall-height [0.5 1 1.5 2 2.5 3 3.5 4]
          let wall-color item color-index [pink magenta violet orange brown red 13 2]
          set my-wall-color wall-color
          set my-wall-price wall-cost ;reporter - jo højere, jo dyrere
          recolor display
      ]
    ]
  ]
  [ ;if can't afford:
    if mouse-down? [
      ;do nothing
    ]
  ]

  if not mouse-inside? [update-wall-utilfredshed] ;opdaterer først, når de er færdige med at tegne
end

to erase-wall ;viskelæder
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      if wall-patch? [
        set water-level 0
        set my-wall-height "none"
        recolor display
        set wall-patches other wall-patches ;removes self from the patch-set
      ]
    ]
  ]

  if not mouse-inside? [update-wall-utilfredshed]
end

to remove-all-walls ;interface-knap
  ask wall-patches [
    set water-level 0 ;now a sea-patch ;@set water-level hav-niveau i stedet???
    ;set pcolor sky
    set my-wall-height "none"
    recolor display
  ]
  set samlet-wall-utilfredshed 0
  set wall-patches no-patches
end

;--MONEY STUFF:

to get-more-money ;button in interface
  set skatte-penge skatte-penge + 2000 ;@tweak how much money they get

  update-tax-utilfredshed ;people get angry :(
  update-samlet-utilfredshed
end

to-report money-spent
  report sum [my-wall-price] of wall-patches
end

to-report money-left
  report (Budget + skatte-penge) - money-spent
end

to-report any-money-left?
  report money-left > 0
end

to-report can-afford [price]
  report money-left >= price
end

to-report wall-cost
  report mur-højde * 10 ;@højere mure er dyrere
end

;--UTILFREDSHED stuff:

to-report wall-utilfredshed ;house-patch reporter
  ifelse any? view-patches with [member? self wall-patches] [
      report ( count view-patches with [member? self wall-patches and total-wall-height > [terrain-height] of myself ] ) / 10 ;@change divisor?
    ]
  [
    report 0
  ]
end

to update-wall-utilfredshed ;only updated when a wall is built or removed (to optimise)
  set samlet-wall-utilfredshed sum [wall-utilfredshed] of house-patches
  update-samlet-utilfredshed
end

to update-tax-utilfredshed
  set tax-utilfredshed tax-utilfredshed + (count house-patches / 4) ;svarer til at alle bliver 0.25 mere utilfredse per penge-opkrævning
end

to-report water-utilfredshed ;house-patch reporter ;@OPTIMÉR: hvornår/hvordan skal denne køres for at opdatere utilfredshed ift. vand???
  ifelse member? self house-patches [

    ifelse water-level > 0.2 or pcolor = sky ;tweak water-level for utilfredshed
      [report 3] ;@tweak, nu bare binær 0 eller 3. ;pcolor = sky fanger 'oversvøm'-animationen, som bare farver, men ikke opdaterer water-level
      [report 0]
  ]
  [ ;if not house-patch:
    report 0
  ]
end

to update-samlet-utilfredshed ;monitor in interface ;@FIX!!!
  set samlet-utilfredshed round (samlet-wall-utilfredshed + tax-utilfredshed + sum [water-utilfredshed] of house-patches) ;walls + taxes + water
  ;@procentvis eller noget i stedet for bare additive?
end

;---VISUALS:

to recolor ;patch procedure, reflekterer vandspejlets højde
  ;@SKAL DE FARVES EFTER DEN TOTALE HØJDE? (terræn + water-level eller sea-level + water-level) - eller bare vandspejlet???
  ;@undgå sort og hvid...

  (ifelse
    wall-patch? [ ;WALL-PATCHES:
      ifelse water-level > 0
          [set pcolor 104] ;vand ovenpå nu bare visualiseret med EN blå farve
          [set pcolor my-wall-color]
    ]
    member? self sea-patches [ ;SEA-PATCHES:
      set pcolor (scale-color sky water-level 12 -1) ;@water-level eller my-water-height??? ;@tweak scale-color, not the same as on land?
    ]
    member? self land-patches [ ;LAND-PATCHES:
     ifelse water-level = 0
        [set pcolor white]
        [
        set pcolor scale-color sky water-level 0.8 -0.05
      ] ;@tweak this scale (water-level is in meters)
  ])

  ;if pcolor = 90 [set pcolor 92] ;avoid black
end


;---INTERFACE STUFF:

to update-time ;run in go
  ;MINUTES:
  let index position minute ["15" "30" "45" "00"]
  let new-index (index + 1) mod 4
  set minute item new-index ["15" "30" "45" "00"]

  ;HOUR:
  if minute = "00" and ticks > 0 and ticks-since-start > 0 [set hour hour + 1]
  if hour = 24 [set hour 0]

  ;DAY:
  ;if ticks mod (24 * 4) = 0 [set hour 0] ;here it loops around from 23 to 0 ;use ticks-since-start?
  if str-time = "00:00" and ticks > 0 and ticks-since-start > 0 [set day day + 1]

  if running-month? [ ;month and year are only used if we're auto-running a specific period
    ;MONTH:
    if (current-month = "02" and (day = 29)) or (current-month = one-of short-months and day = 31) or day = 32 [
      ;(@^^February and leapyears NOT taken into account right now, feb 29th is skipped!)
      let month-index position current-month ["01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12"]
      let new-month-index (month-index + 1) mod 12
      set current-month item new-month-index ["01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12"]
      set day 1 ;back to the first of the new month

     ;YEAR:
      if current-month = "01" [set current-year current-year + 1] ;only runs if the month was just changed to 01
    ]
  ]



end

to-report str-time ;for interface
  let str-hour hour
  if str-hour < 10 [set str-hour (word "0" hour )]
  report (word str-hour ":" minute)
end

to-report str-day ;always two-digit. Not for interface, but for table-lookup with run-period
  let day-nr day
  if day-nr < 10 [set day-nr (word "0" day-nr)] ;e.g. 03 instead of 3
  report day-nr
end

to-report Måned ;just for interface for auto-running, making it clear how far it is
  ifelse running-month? [
    report current-month
  ]
  [
    report " - "
  ]
end
to-report År ;just for interface for auto-running, making it clear how far it is
  ifelse running-month? [
    report current-year
  ]
  [
    report " - "
  ]
end


to-report seepage-m-per-s ;(jordens hydrauliske ledeevne)
  ;baseret på https://www.plastmo.dk/beregnere/faskineberegner.aspx
  if jordtype = "Groft sand" [report 0.001] ;10^-3
  if jordtype = "Fint sand" [report 0.0001] ;10^-4
  if jordtype = "Fint jord" [report 0.00001] ;10^-5
  if jordtype = "Sandet ler" [report 0.000001] ;10^-6
  if jordtype = "Siltet ler" [report 0.0000001] ;10^-7
  if jordtype = "Asfalt" [report 0] ;ingen nedsivning
end

to-report nedsivningsevne-interface ;as string (so shown as decimal nr)
  ;baseret på https://www.plastmo.dk/beregnere/faskineberegner.aspx
  if jordtype = "Groft sand" [report "0.001 m/sek"] ;10^-3
  if jordtype = "Fint sand" [report "0.0001 m/sek"] ;10^-4
  if jordtype = "Fint jord" [report "0.00001 m/sek"] ;10^-5
  if jordtype = "Sandet ler" [report "0.000001 m/sek"] ;10^-6
  if jordtype = "Siltet ler" [report "0.0000001 m/sek"] ;10^-7
  if jordtype = "Asfalt" [report "Ingen nedsivning"] ;ingen nedsivning
end


;TING TIL BEREGNINGER

to-report seconds-per-tick ;skift evt tidsenhed her
  report 900 ;hvis hvert tick er 15 minutter
end

to-report minutes-per-tick
  report ( seconds-per-tick / 60 )
end

to-report my-water-height ;patch reporter
  ifelse
    terrain-height = "sea" [
      ifelse wall-patch?
        [report my-wall-height + water-level] ;wall-patches in the sea (@NOT dependant on sea-level)
        [report water-level] ;sea-patches. grund-hav-niveau + regnvand. sea-patches have no terrain-height
  ]
  [ ;land-patches:
    ifelse wall-patch?
      [report terrain-height + my-wall-height + water-level] ;wall-patches on land
      [report water-level + terrain-height] ;land-patches
  ]
end

to-report total-wall-height ;wall-patch reporter. WITHOUT water level
  ifelse terrain-height = "sea"
  [ ;wall-patches in the sea:
    report my-wall-height
  ]
  [ ;wall-patches on land
    report my-wall-height + terrain-height
  ]
end


to-report sea-level
  report hav-niveau ;@bare slider i interface... skal det 'fryses', så det ikke konstant kan ændres?
end

to-report wall-patch?
  report my-wall-height != "none" ;my-wall-height is a patch variable
end

to-report water-distance-to [input-height] ;patch reporter. given a water level, reports the distance from the patch's own total water height (terrain-height + water-level) to this input level
  report my-water-height - input-height
  ;difference in meters. negative = the patch's level is lower than the input nr.
end

to-report terrain-difference-to [input-terrain-height] ;patch reporter. given a terrain level, reports the distance from the patch's own terrain height to this input height
  report terrain-height - input-terrain-height
  ;in meters. negative = the ptach's level is lower than the input number.
end


;---DATA-IMPORT OG AUTO-KØRSEL

to-report import-month-old [filename] ;works for the Google sheets version
  let file csv:from-file (word filename ".csv") ;this gives us ONE long list of single-item lists (each list containing one string)
  let nice-file map [i -> csv:from-row reduce word i] file ;a full list of lists (every sheets row is an item)
                                                                  ;explanation: 'reduce word' makes every nested list in the list one string entry instead of a single-item list
                                                                  ;'csv:from-row' makes each item a netlogo spaced list instead of a comma separated string
  report nice-file
  ;result: [["02-05-2021 07:00" 0.4 4] ["02-05-2021 08:00" 0.1 1] ["02-05-2021 09:00" 0.2 2] ... ]
  ;data fra: https://www.dmi.dk/friedata/observationer/
end

to-report import-month [filename] ;trying with the directly downloaded and merged files! ;dates are now in the format "YYYY-MM-DD TT:TT"
  report csv:from-file (word filename ".csv")
  ;result: [["2021-01-06 04:00" 0.1] ["2021-01-06 05:00" 0.1] ... ]
  ;data fra: https://www.dmi.dk/friedata/observationer/
end

to-report get-year [date-time] ;for the format "YYYY-MM-DD TT:TT"
  report substring date-time 0 4
end
to-report get-month [date-time] ;for the format "YYYY-MM-DD TT:TT"
  report substring date-time 5 7 ;always two digits
end
to-report get-date [date-time] ;for the format "YYYY-MM-DD TT:TT"
  report substring date-time 8 10 ;always two digits
end
to-report get-time [date-time] ;for the format "YYYY-MM-DD TT:TT"
  report substring date-time 11 16 ;full time 5 digits, i.e. "07:00", matching str-time
end
to-report get-hour [date-time] ;for the format "YYYY-MM-DD TT:TT"
  report substring date-time 11 13 ;always two digits
end

to-report date-check?
  let f substring fra-dato 0 4
  let t substring til-dato 0 4
  ; is it before 2020 or after june 2021?
  if not (f = "2020" or f = "2021") and (t = "2020" or t = "2021") [user-message "Datoen skal være efter 2020." report false]
  set f runresult substring fra-dato 5 7
  set t runresult substring til-dato 5 7
  ; is it a real month?
  if f > 12 or t > 12 [report false]
  let fdato runresult substring fra-dato 8 10
  let tdato runresult substring til-dato 8 10
  ; is it a day in the month?
  if fdato > max-month-day f or tdato > max-month-day t [user-message "Dette er ikke et rigtigt tal for dag i denne måned." report false]
  ; is the to-date later than from-date?
  let fromdate-number run-result (word substring fra-dato 0 4 substring fra-dato 5 7 substring fra-dato 8 10)
  let todate-number run-result (word substring til-dato 0 4 substring til-dato 5 7 substring til-dato 8 10)
  if todate-number < fromdate-number [user-message "Til-dato er før fra-dato." report false]
  report true
end

to-report max-month-day [month-no]
  if month-no = 1 [report 31]
  if month-no = 2 [report 28]
  if month-no = 3 [report 31]
  if month-no = 4 [report 30]
  if month-no = 5 [report 31]
  if month-no = 6 [report 30]
  if month-no = 7 [report 31]
  if month-no = 8 [report 31]
  if month-no = 9 [report 30]
  if month-no = 10 [report 31]
  if month-no = 11 [report 30]
  if month-no = 12 [report 31]
end

to run-period
  if not date-check? [
    stop
  ]
  reset-ticks
  ask patches [set water-level 0] ;reset, alt vand i systemet fjernes
  hæv-havet ;hav-niveauet sættes til det valgte
  ;let data import-month-old periode ;import month data from csv. periode is the interface chooser

  ;saving the variables so any interface changes won't confuse plot pen names or other stuff:
  set periode-valgt (word fra-dato " - " til-dato) ;e.g. "2010-01-17 - 2010-01-29". for plot pen names and monitor
  set %-valgt %-ekstra-regn set hav-niveau-valgt hav-niveau

  let all-data import-month "regn-2010-2015-2020-2021" ;csv with ALL month rain data combined
                                                       ;@OBS: hvis vi får for meget data, kan vi evt. optimere tidsforbrug ved kun at loade det nødvendige her!
  ;show all-data
  ;LOOP over data to create table:
  let first-entry? true
  let first-rain-day "none" let first-rain-hour "none" let last-rain-day-and-time "none"
  let reached-startpoint? false let reached-endpoint? false
  set auto-table table:make ;initialize empty table
  show 1

  foreach all-data [ ;each entry is in the form ["2010-01-11 21:00" 1.1] ;liste med dato + nedbør per time (i mm)
    x ->
    let full-date item 0 x ;e.g. "2010-01-11 21:00"
    let just-date substring full-date 0 10 ;e.g. "2010-01-11"

    if just-date = fra-dato [ set reached-startpoint? true] ;when to begin loading rows to table...
    if just-date = til-dato [set reached-endpoint? true] ;...and when to stop. så intervallet er eksklusiv til-dato

    if reached-startpoint? and not reached-endpoint? [

      let the-month get-month full-date ;e.g. "01"
      let the-day get-date full-date ;e.g. "11"
      let the-hour get-hour full-date ;e.g. 21
      let the-time get-time full-date ;e.g. "21:00"
      let the-year get-year full-date
      ;let key (word the-year the-day the-time) ;e.g. "1121:00" - this is the key for the table entry
      let key full-date
      let the-rain (item 1 x) * ( 1 + (%-valgt / 100) ) ;e.g. 1.1 * 1.15 ;tilføjer scaler

      if the-rain != 0 [ ;only keeping the times it actually rained
        table:put auto-table key the-rain ;table, key, value
        if first-entry? [set first-rain-day the-day set first-rain-hour the-hour set current-year read-from-string the-year set current-month the-month set first-entry? false] ;used further down to start at this day&time

        set last-rain-day-and-time key ;overwrites hver gang, så sidste version er altså den sidste
      ]
    ]
  ] ;end of loop
  show 2

  ;byg en 'stopklods' ind i tabellen kvarteret efter det sidste regn-entry:
  let stop-day-and-time but-last but-last last-rain-day-and-time ;removing "00"
  set stop-day-and-time (word stop-day-and-time "15") ;changing it to a quarter past the last rain key, e.g. "2010-12-29 23:15"
  table:put auto-table stop-day-and-time "stop" ;indbygget stopklods (tjekkes i go)

  show 3
  ;reset time to the first rain occurence for that period:
  if first first-rain-day = "0" [set first-rain-day but-first first-rain-day] ;e.g. "06" becomes "6"
  if first first-rain-hour = "0" [set first-rain-hour but-first first-rain-hour]

  set day read-from-string first-rain-day
  set hour read-from-string first first-rain-hour
  set minute "00"
  set ticks-at-start ticks ;when the auto-sim began (for update-plot)
  setup-plot-pen
  set running-month? true ;now go will auto-rain by matching current time to auto-table
end

to-report key-checker ;the current year+date+time in the same format as in auto-table. Used in go to check if there's a rain entry (when auto-running a period)
  ;format: "2020-09-08 02:00"
  ifelse running-month? [
    report (word current-year "-" current-month "-" str-day " " str-time)
  ]
  [
    report "nope"
  ]
end

to-report data-time [input]
  let tidspunkt input
  repeat 11 [set tidspunkt but-first tidspunkt] ;now only "07:00" left, or "13:00"
  report tidspunkt
  ;then check if this matches str-time
end

to-report auto-interface
  ifelse running-month? [
    ;let auto-mængde precision (sum map [i -> item 1 i * ( 1 + (%-valgt / 100) )] import-month periode-valgt) 2 ;total rainfall for the auto-running period
    ;@change to get it directly from auto-table
    let auto-mængde precision (sum table:values auto-table) 2

    report (word "KØRER NU: " periode-valgt ". I alt " auto-mængde " mm nedbør (inkl. " %-valgt " % ekstra).")
  ]
  [
    report "Vælg en periode og tryk på knappen for at køre perioden med automatisk nedbør."
  ]
end


;---PLOT
to setup-plot-pen2 ;run in run-period (so new line starts plotting every time it's run)
  set-current-plot "Gennemsnitlig vandstand på land"
  let pen-name (word regn-i-simulationen ", " jordtype ", " hav-niveau " m hav")
  set water-pen pen-name
  create-temporary-plot-pen pen-name
  set-plot-pen-color first colors-left
  set-current-plot "Indbyggernes utilfredshed"
  create-temporary-plot-pen (word periode-valgt " " %-valgt " % og havvandstand " hav-niveau-valgt)
  set-plot-pen-color first colors-left
  set colors-left but-first colors-left
end


;---PLOT
to setup-plot-pen ;run in run-period (so new line starts plotting every time it's run)
  set-current-plot "Gennemsnitlig vandstand på land"
  create-temporary-plot-pen (word periode-valgt " " %-valgt " % og havvandstand " hav-niveau-valgt)
  set-plot-pen-color first colors-left


  set-current-plot "Indbyggernes utilfredshed"
  create-temporary-plot-pen (word periode-valgt " " %-valgt " % og havvandstand " hav-niveau-valgt)
  set-plot-pen-color first colors-left



  set colors-left but-first colors-left
end

to update-plot ;run in go
  ifelse running-month? [

    set-current-plot "Gennemsnitlig vandstand på land"
    set-current-plot-pen (word periode-valgt " " %-valgt " % og havvandstand " hav-niveau-valgt)
    if ticks-since-start = 0 [plot-pen-up plotxy 0 0 plot-pen-down] ;undgår grim linje tilbage gennem plottet, hvis den samme pen restartes
    plotxy ticks-since-start (mean [water-level] of land-patches)

    set-current-plot "Indbyggernes utilfredshed"
    set-current-plot-pen (word periode-valgt " " %-valgt " % og havvandstand " hav-niveau-valgt)
    if ticks-since-start = 0 [plot-pen-up plotxy 0 0 plot-pen-down] ;undgår grim linje tilbage gennem plottet, hvis den samme pen restartes
    plotxy ticks-since-start samlet-utilfredshed

  ]
  [ ;if not auto-running month:
    set-current-plot "Gennemsnitlig vandstand på land"
    create-temporary-plot-pen water-pen ;if it already exists, it just sets it as the current one
    plotxy ticks (mean [water-level] of land-patches)

    set-current-plot "Indbyggernes utilfredshed"
    create-temporary-plot-pen "Utilfredshed"
    plotxy ticks samlet-utilfredshed
  ]
end

to-report ticks-since-start
  report ticks - ticks-at-start
end




;GAMLE TING FRA BØLGEMODELLEN:

to release-drop    [drop-xpos drop-ypos]    ;Turtle procedure for releasing a drop onto the pond
  if (((xpos - drop-xpos) ^ 2) + ((ypos - drop-ypos) ^ 2) <= ((.5 * drop-width) ^ 2))
[set delta-z (delta-z + (k * ((sum [zpos] of neighbor-turtles) -
        ((count neighbor-turtles) * zpos) - impact)))]
;  show delta-z
end

to compute-delta-z    ;Turtle procedure
   set k (1 - (.01 * surface-tension))        ;k determines the degree to which neighbor-turtles'
  set delta-z (delta-z + (k * ((sum [zpos] of neighbor-turtles) - ((count neighbor-turtles) * zpos))))
end

to update-position-and-color  ;Turtle procedure
  set zpos ((zpos + delta-z) * (.01 * friction))    ;Steal energy by pulling the turtle closer
  set color scale-color blue zpos 100 -100            ;to ground level
  ifelse three-d?
   [
     let y (zpos + (ypos * sin angle))
     let x (xpos + (ypos * cos angle))
     ifelse patch-at (x - xcor) (y - ycor) != nobody
      [ setxy x y show-turtle ]
      [ hide-turtle ]]
   [
     ifelse patch-at (xpos - xcor) (ypos - ycor) != nobody
      [ setxy xpos ypos
      show-turtle ]
      [ hide-turtle ]]
end

to old-make-wave
  let wave-strength random 80 ;interface slider instead
  ask sea-patches with [pycor = 54] [ask turtles-here [set zpos wave-strength]]
end
@#$#@#$#@
GRAPHICS-WINDOW
275
45
1073
459
-1
-1
4.18
1
10
1
1
1
0
0
0
1
-94
94
-48
48
1
1
1
ticks
30.0

BUTTON
15
410
262
446
Simuler 48 timer
if ticks >= 192 [reset-ticks]\nif ticks = 0 [\nask patches [set water-level 0] \nhæv-havet\nstart-rain\nsetup-plot-pen2 \n]\nrepeat 192 [go]\n
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
30
30
257
66
(Gen)Start Opgave 1
setup\nsetup-1
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
15
295
115
340
Jordtype
Jordtype
"Groft sand" "Fint sand" "Fint jord" "Sandet ler" "Siltet ler" "Asfalt"
2

SLIDER
1080
255
1365
288
hav-niveau
hav-niveau
0
12
1.4
.1
1
m
HORIZONTAL

MONITOR
660
50
715
95
Tid
str-time
17
1
11

MONITOR
120
295
265
340
Jordens nedsivningsevne
nedsivningsevne-interface
17
1
11

SLIDER
15
105
265
138
mm-per-15-min
mm-per-15-min
0
25
24.0
.5
1
mm
HORIZONTAL

SLIDER
15
145
265
178
nedbør-varighed
nedbør-varighed
0
24
4.0
.25
1
timer
HORIZONTAL

MONITOR
535
50
660
95
Dag i Simulationen
1 + round (ticks / (24 * 4))
17
1
11

BUTTON
1390
210
1655
243
Byg Mur
build-wall
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
615
10
705
43
Vis højdekort
clear-drawing\nimport-drawing \"mf-heightline-ref-alpha55.png\"
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
710
10
790
43
Skjul kort
clear-drawing
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
530
10
610
43
Vis bykort
clear-drawing\nimport-drawing \"mf-map-kystfix-alpha55.png\"
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
1390
130
1655
163
mur-højde
mur-højde
0.5
4
2.5
0.5
1
m
HORIZONTAL

BUTTON
1520
245
1655
278
Fjern Alle Mure
remove-all-walls
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
275
460
1075
735
Gennemsnitlig vandstand på land
tid
Gns Oversvømmelse (m)
0.0
10.0
0.0
1.0E-6
true
true
"" ""
PENS

BUTTON
10
655
175
688
Vis oversvømmelse
oversvøm
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
15
185
120
218
vis-regn?
vis-regn?
0
1
-1000

BUTTON
1390
245
1520
278
Fjern Mure
erase-wall
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
1390
165
1470
210
Beløb brugt
money-spent
17
1
11

MONITOR
1470
165
1560
210
Beløb tilbage
money-left
17
1
11

TEXTBOX
1390
70
1550
125
Opg 3: Højvandsmure
17
0.0
1

TEXTBOX
75
80
220
100
Opg 1: Nedbør
17
0.0
1

TEXTBOX
105
270
205
291
Jordtype
17
0.0
1

TEXTBOX
50
345
300
363
Hav-vandstand/stormflod
17
0.0
1

TEXTBOX
1405
495
1650
515
Indbyggernes utilfredshed
17
0.0
1

TEXTBOX
1080
95
1400
131
Opg 2: Kør automatisk nedbørs-periode
17
0.0
1

BUTTON
1080
290
1365
360
1. Sæt Periode
run-period\nask patches [set water-level 0]\n
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
10
690
175
723
hav-stigning
hav-stigning
0
12
0.0
0.5
1
NIL
HORIZONTAL

TEXTBOX
20
565
305
601
Hold musen over kortet for at tjekke terrænhøjde og vandstand forskellige steder.
13
0.0
1

MONITOR
15
470
270
515
 Type & højde
patch-type-here
17
1
11

MONITOR
15
515
270
560
Vandstand
wl-here
17
1
11

TEXTBOX
20
445
195
466
Tjek forhold
17
0.0
1

MONITOR
1400
645
1665
690
Samlet utilfredshed
samlet-utilfredshed
17
1
11

TEXTBOX
15
630
165
651
Oversvømmelse
17
0.0
1

SLIDER
1080
220
1365
253
%-ekstra-regn
%-ekstra-regn
0
1000
0.0
5
1
%
HORIZONTAL

SLIDER
15
370
265
403
hav-niveau
hav-niveau
0
2.5
1.4
.1
1
m
HORIZONTAL

BUTTON
1390
280
1655
321
Opkræv Ekstra Skatter til Mur
get-more-money
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1560
165
1655
210
NIL
skatte-penge
0
1
11

PLOT
1400
525
1665
650
Indbyggernes utilfredshed
tid
utilfredshed
0.0
10.0
0.0
10.0
true
false
"" ""
PENS

INPUTBOX
1080
160
1210
220
fra-dato
2020-06-04
1
0
String

INPUTBOX
1215
160
1365
220
til-dato
2020-06-05
1
0
String

MONITOR
1200
435
1257
480
NIL
Måned
17
1
11

MONITOR
1255
435
1335
480
NIL
År
17
1
11

MONITOR
15
220
265
265
NIL
regn-i-simulationen
0
1
11

TEXTBOX
2585
140
2735
241
Vigtige pointer:\n1. Oversvømmelse på er ikke lineær med mængden af vand fra hav og luft\n2. Stormflod og nedbør interagerer
12
0.0
1

BUTTON
1080
30
1365
63
(Gen)Start Opgave 2
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
1080
360
1365
435
2. Kør Periode
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
1145
435
1202
480
NIL
str-day
0
1
11

TEXTBOX
1120
140
1280
158
Datoformat: åååå-mm-dd
12
0.0
1

BUTTON
1385
30
1655
63
(Gen)Start opgave 3
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

SLIDER
1395
330
1655
363
mm-per-15-min
mm-per-15-min
0
25
24.0
.5
1
mm
HORIZONTAL

SLIDER
1395
365
1655
398
nedbør-varighed
nedbør-varighed
0
24
4.0
.25
1
NIL
HORIZONTAL

SLIDER
1395
400
1655
433
hav-niveau
hav-niveau
0
2.5
1.4
.1
1
m
HORIZONTAL

CHOOSER
1395
435
1655
480
Jordtype
Jordtype
"Groft sand" "Fint sand" "Fint jord" "Sandet ler" "Siltet ler" "Asfalt"
2

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

drop
false
0
Circle -7500403 true true 73 133 152
Polygon -7500403 true true 219 181 205 152 185 120 174 95 163 64 156 37 149 7 147 166
Polygon -7500403 true true 79 182 95 152 115 120 126 95 137 64 144 37 150 6 154 165

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
