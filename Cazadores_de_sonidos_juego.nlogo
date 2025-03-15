breed [ bats bat]
breed [birds bird]
breed [apple-trees apple-tree]
breed [trees tree]
breed [houses house]
breed [targets target]
breed [crowns crown]

globals [
    ;;Global variables related to landscape creation
  //////
  seed-orchard
  prop-urban
  urban-pixels
  city-size
  n-cities
  nbirds
  nbats
  ;;correlated-random walk parameters
  K;
  m;
  mu;
  sd;
]

patches-own [
 orchard-id;
 visit-bird
 visit-bat
 habitat;
 id;
 edge;
 height;
 house-free
 tree-free
 bird-free
 bat-free
]

birds-own[
  xc;
  yc;
  nforest;
  nurban;
  norchard; ,
  nclose;
  visits
]


bats-own[
  xc;
  yc;
  nforest;
  nurban;
  norchard;
  nclose;
  visits
]

targets-own
[target-id who-visited]
;;;;FUNCTIONS;;;
to-report partial-sums [lst]
report butfirst reduce [[result-so-far next-item] -> lput (next-item + last
result-so-far) result-so-far] fput [0] lst
end

;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;
;;;SETUP PROCEDURE;;;
;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;

to ver_paisaje
   ca
  ask patches [set habitat "" set visit-bird 0 set visit-bat 0]
   create-orchards
   create-edge-buffer
   set prop-urban Zonas-urbanas
   set nbirds 5
   set nbats 5
   create-urban
  ask patches with [habitat =  ""]
  [set habitat "forest" set pcolor 58]
  put-trees
  put-houses
  locate-birds
  locate-bats
  ask birds [set visits []]
  ask bats [set visits[]]
end

to create-orchards
   ask patches with [pxcor = 0 and pycor = 0]
                    [set habitat "orchard" set pcolor 28 set  orchard-id 1
                      sprout-targets 1 [set size 50 set shape "apple2" set target-id 1]
                      ask patches in-radius 20 [set habitat "orchard" set pcolor 28 set  orchard-id 1]]
  ask patches with [pxcor = -125 and pycor = 125]
                    [set habitat "orchard" set pcolor 28 set  orchard-id 2
                      sprout-targets 1 [set size 50 set shape "apple2" set target-id 2]
                      ask patches in-radius 20 [set habitat "orchard" set pcolor 28 set  orchard-id 2]]
  ask patches with [pxcor = 125 and pycor = 125]
                    [set habitat "orchard" set pcolor 28 set  orchard-id 3
                      sprout-targets 1 [set size 50 set shape "apple2" set target-id 3]
                      ask patches in-radius 20 [set habitat "orchard" set pcolor 28 set  orchard-id 3]]
  ask patches with [pxcor = 125 and pycor = -125]
                    [set habitat "orchard" set pcolor 28 set  orchard-id 4
                      sprout-targets 1 [set size 50 set shape "apple2" set target-id 4]
                      ask patches in-radius 20 [set habitat "orchard" set pcolor 28 set  orchard-id 4]]
   ask patches with [pxcor = -125 and pycor = -125]
                    [set habitat "orchard" set pcolor 28 set  orchard-id 5
                      sprout-targets 1 [set size 50 set shape "apple2"set target-id 5]
                      ask patches in-radius 20 [set habitat "orchard" set pcolor 28 set  orchard-id 5]]

   ;;identify edges and create a buffer
   ask patches with [habitat = "orchard"][
  let my-neigh [habitat] of neighbors
  let boundary length filter [ ?1 -> ?1 = "" ] my-neigh
   ifelse boundary > 0
  [set edge "yes" set pcolor black]
    [set edge "no"]
  ]
  ask patches with [habitat = "orchard" and edge = "yes"]
  [
     ask other patches in-radius 20 with [habitat = ""]
     [set pcolor 58
       set bird-free "no" set bat-free "no"]
  ]

end


to create-edge-buffer
  ask patches with [pxcor < -225 or pxcor > 225 ]
  [set bird-free "no" set bat-free "no"]
    ask patches with [pycor < -225 or pycor > 225 ]
    [set bird-free "no" set bat-free "no"]
end

to create-urban
  let free-area count patches with [habitat = ""]
  set urban-pixels  round(free-area * (prop-urban * 0.01) * 0.7);; Just to make some forest available always
 ;; print urban-pixels
  set   city-size []
  repeat 200
  [let radio round random-normal 20 5
   let n round((radio ^ 2 * 3.14) * 0.8)
  set city-size fput n  city-size] ;
  set city-size filter [ ?1 -> ?1 > 10 ^ 2 * 3.14 ] city-size ;
  let cum-urban partial-sums city-size
  set cum-urban filter [?1 -> ?1 <= urban-pixels] cum-urban
  set n-cities length(cum-urban)
  if (n-cities = 0)
  [ set n-cities 1]
  create-cities
end


to create-cities
    ;;; Create cities
   let counter 1
  repeat n-cities
  [
      let tmp item counter city-size
      let tmp2 sqrt (tmp / 3.14)
     let seed one-of patches with [habitat = ""]
      ask seed
    [ set id counter
      set pcolor yellow
      set habitat "urban"
      ask patches in-radius tmp2
      [
        if habitat = ""
        [set id counter set pcolor yellow set habitat "urban"]
        ]
      ;;;identify edges
     ask patches with [id = [id] of myself][
      let my-neigh [id] of neighbors
       let boundary length filter [ ?1 -> ?1 = 0 ] my-neigh
       ifelse boundary > 0
       [set edge "yes"
         set height 10000]
       [set edge "no"]
      ]
  ];; end of ask seed
    ;;expand edges
    while [count patches with [id = counter ] < (tmp + 1) and count patches with [id > 0 ] < urban-pixels]
      [
        diffuse height 0.1
        ask patches with [ height > 0 ] [
          if habitat = ""
          [set pcolor yellow set id counter set habitat "urban"]
           ]
      ]
 ;;;;Finish with this city
    set counter (counter + 1)
  ]
end

to put-houses
  let tmp count patches with [habitat = "urban"]
  let tmp2 round (tmp * 0.0005)
  ask n-of tmp2 patches with [habitat = "urban"]
  [sprout-houses 1
    [ set size 20 set shape "house2"]]

end


to put-trees
  let tmp count patches with [habitat = "forest"]
  let tmp2 tmp * 0.002
  ask n-of tmp2 patches with [habitat = "forest" and tree-free = 0]
  [sprout-trees 1
    [ set size 20 set shape "tree2"
  ]
    ask patches in-radius 10 [set tree-free "no"]
  ]

end

to locate-birds
   repeat nbirds
  [
   let p one-of patches with [habitat = "forest" and bird-free = 0]
   ifelse p = nobody
    [stop]
    [ ask p
      [
         sprout-birds 1
          [set size 70 set shape "bird3"]
           ask patches in-radius 50 [set bird-free "no"]
      ]
    ]
  ]
  ask birds[set nurban 0 set nforest 0 ]

end


to locate-bats
   repeat nbats
  [
   let p one-of patches with [habitat = "urban" and bat-free = 0]
   ifelse p = nobody
    [stop]
    [ ask p
      [
         sprout-bats 1
          [set size 70 set shape "bat"]
           ask patches in-radius 50 [set bat-free "no"]
      ]
    ]
  ]
   ask bats[set nurban 0 set nforest 0 ]
end


;;;Functions related to correlated random walk. Based on Viktoriia Radchuk, Thibault Fronville, Uta Berger (2023, December 18). “Correlated Random Walk (NetLogo)” (Version 1.0.0). CoMSES Computational Model Library. Retrieved from: https://doi.org/10.25937/rm0p-mm61

to-report calc_turnangle_circ
  ; turning angle - implementation #2: drawing from von Mises
  ; simulation algorithm (Fisher "Statistical Analysis of circular data", 1993. p. 49);
  let a (1 + sqrt( 1 + 4 * K ^ 2))
  ;  show word "a" a
  let b (a - sqrt( 2 * a)) / ( 2 * K )
  ;  show word "b" b
  let r ( 1 + b ^ 2) / ( 2 * b )
  ;  show word "r" r
  let turnang 0
  let step4 0
  while [step4 = 0]
    [
      ;; step 1
      let U1 random-float 1
      ;      show word "U1 is" U1
      let z (cos ((pi * U1 ) * 180 / pi))  ;;;  should be transformed into degrees for Netlogo
      ;      show word "z is" z
      let f (1 + r * z) / ( r + z )
      ;      show word "f is" f
      let c (K * (r - f))
      ;        show word "c is" c

      ; step 2
      let U2 random-float 1
      ;      show word "U2" U2

      ifelse
        ( c * ( 2 - c) - U2) > 0
        [
          ;        show word "cond 2 satisfied" (c * ( 2 - c) - U2)
          let U3 random-float 1
          if ( U3 - 0.5 ) < 0
          [
            set turnang ((- acos (f) * pi / 180) + m)
          ]
          if ( U3 - 0.5) > 0
          [
            set turnang (acos (f) * pi / 180 ) + m
          ]
        ;            show word "turnangle" turnangle
          if is-number? turnang [ set step4 1]
        ]
        [
          if  ((ln ( c / U2 )) + 1 - c)  >= 0

          [
            let U3 random-float 1
            if ( U3 - 0.5 ) < 0
            [
              set turnang ((- acos (f)  * pi / 180) + m)
            ]

            if ( U3 - 0.5) > 0
            [
              set turnang (acos (f) * pi / 180) + m
            ]
            ;            show word "turnangle" turnangle
            if is-number? turnang [set step4 1  ]
          ]
        ]
    ]

  ;  show word "turnangle before transform" turnangle
  if turnang < 0 [set turnang turnang + 2 * pi]
  if turnang > ( 2 * pi) [set turnang turnang - 2 * pi]
  ;  show word "final turnangle in radians" turnangle
  let turndegrees turnang * (180 / pi)
  ;  show word "final turnangle in degrees" turndegrees
  report turndegrees
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,
;;;;;GO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to A-jugar
  reset-ticks
  ask houses[hide-turtle]
  ask trees[hide-turtle]
  set K  2
  set m  -0.2
  set mu 1.5
  set sd 0.5
  while [ticks < 750]
  [
    ask birds [move-birds]
    ask bats [move-bats]
    ask birds [track-visits-birds]
    ask bats [track-visits-bats]
    tick
  ]
end




to move-birds
  ask birds
        [ set xc xcor
          set yc ycor]
  ;;Mover either in a random walk or within preferred habitat
      ifelse random-float 1 < 0.7
    ;;within forests
  [

     let p one-of patches in-radius 10 with [habitat = "forest" or habitat  = "orchard"] ;
     ifelse p = nobody
     [ fd 1
       set xc [pxcor] of patch-here
       set yc [pycor] of patch-here
       setxy xc yc
    ]
     [ set xc [pxcor] of p
       set yc [pycor] of p
       setxy xc yc
    ]
   ]
    ;;; correlated random walk
  [
  let turnangle calc_turnangle_circ
  set heading heading + turnangle
            ;            show word "my new heading is " heading
            ;            ;; choosing the move length
  let moveleng exp (random-normal mu sd)
  set xc xc + (moveleng * (sin heading))
  set yc yc + (moveleng * (cos heading))
            ;            show word "I would end up at this x" xc
            ;            show word "I would end up at this y" yc
  ifelse xc < -250 or xc > 250 or yc < -250 or yc > 250
    [ask birds [face patch 0 0 fd 10]]
    [setxy xc yc]
  ]
  ask patch-here [set visit-bird (visit-bird + 1)]
 ; pen-down
   let tmp [habitat] of patch-here
     ifelse tmp = "urban"
    [set nurban  nurban + 1]
    [set nforest nforest + 1]
  ;;close or within orchard?
    if [habitat] of patch-here = "orchard"
      [set norchard norchard + 1]
       let tmp_close one-of patches in-radius 10 with [habitat = "orchard"] ;
       if tmp_close != nobody
      [set nclose nclose + 1 ]
end


to move-bats
  ask bats
        [ set xc xcor
          set yc ycor
  ]
  ifelse random-float 1 < 0.7
  [ let p one-of patches in-radius 10 with [habitat = "urban" or habitat = "orchard"]
     ifelse p = nobody
     [ move-to one-of neighbors
       set xc [pxcor] of patch-here
       set yc [pycor] of patch-here
       setxy xc yc]
     [ set xc [pxcor] of p
       set yc [pycor] of p
       setxy xc yc]
  ]
  [
  let turnangle calc_turnangle_circ
  set heading heading + turnangle
            ;            show word "my new heading is " heading
            ;            ;; choosing the move length
  let moveleng exp (random-normal mu sd)
  set xc xc + (moveleng * (sin heading))
  set yc yc + (moveleng * (cos heading))
            ;            show word "I would end up at this x" xc
            ;            show word "I would end up at this y" yc
  ifelse xc < -250 or xc > 250 or yc < -250 or yc > 250
    [ask bats [face patch 0 0 fd 10]]
    [setxy xc yc]
  ]
    ask patch-here [set visit-bat (visit-bat + 1)]
 ; pen-down

   let tmp [habitat] of patch-here
     ifelse tmp = "urban"
    [set nurban  nurban + 1]
    [set nforest nforest + 1]
  ;;close or within orchard?
    if [habitat] of patch-here = "orchard"
       [set norchard norchard + 1
        ask patch-here [set visit-bat (visit-bat + 1)]
        ]
       let tmp_close one-of patches in-radius 10 with [habitat = "orchard"] ;
       if tmp_close != nobody
      [set nclose nclose + 1 ]
end


to track-visits-birds
  ask birds [
    let p [habitat] of patch-here
  if p = "orchard"
  [ let tmp [visits] of myself
    let tmp2 [orchard-id] of patch-here
    let tmp3 fput tmp2 tmp
    set visits tmp3
  ]
  ]
end


to track-visits-bats
  ask bats [
    let p [habitat] of patch-here
  if p = "orchard"
  [ let tmp [visits] of myself
    let tmp2 [orchard-id] of patch-here
    let tmp3 fput tmp2 tmp
    set visits tmp3
  ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;,
;;PUNTAJES




to donde-estuvieron
  ask patches [set visit-bird visit-bird * 100 set visit-bat visit-bat * 100]
    repeat 4 [diffuse visit-bird 0.5]
    repeat 4 [diffuse visit-bat 0.5]
  ;let a min [visit-bird] of patches with [visit-bird  > 0]
  ;let b min[visit-bat] of patches
  ;let tmp1 list a b
  ;set tmp1 min(tmp1)
  ; set a max [visit-bird] of patches
  ;set b max[visit-bat] of patches
  ;let tmp2 list a b
  ;set tmp2 max(tmp2)
  ask patches with [visit-bird > 0][set pcolor  95]
   ask patches with [visit-bat > 0][set pcolor 1]
end

to quien-visito-que
  ;; Dar la puntuación de los animales
  ask patches [set pcolor black]
  ask birds with  [norchard > 0] [set shape "bird2"]
    ask birds with  [norchard = 0 and nclose > 0] [set shape "bird1"]
  ask bats with  [norchard > 0] [set shape "bat2"]
    ask bats with  [norchard = 0 and nclose > 0] [set shape "bat1"]
  ;; Dar la puntuación de los orchards
  ask targets [set who-visited 0]
  ;;Rellenar visitas de birds
   let tmp []
  ask birds
  [
   set visits remove-duplicates visits
   if(length(visits) > 0)
    [
      let counter 0
      repeat length(visits)
      [
        let tmp2 item counter visits
        set tmp  fput tmp2 tmp
      ]
    ]
  ]
 set tmp remove-duplicates tmp
 if (length(tmp) > 0)
 [
    let counter 0
     repeat length(tmp)
    [
      let tmp2 item counter tmp
      ask targets with [target-id = tmp2]
      [ set who-visited who-visited + 1]
      set counter (counter + 1)
    ]
  ]
;;Rellenar las visitas de bats
     set tmp []
  ask bats
  [
   set visits remove-duplicates visits
   if(length(visits) > 0)
    [
      let counter 0
      repeat length(visits)
      [
        let tmp2 item counter visits
        set tmp  fput tmp2 tmp
      ]
    ]
  ]
 set tmp remove-duplicates tmp
 if (length(tmp) > 0)
 [
    let counter 0
     repeat length(tmp)
    [
      let tmp2 item counter tmp
      ask targets with [target-id = tmp2]
      [ set who-visited who-visited + 2]
      set counter (counter + 1)
    ]
  ]
  ask targets with [who-visited = 1] [set shape "apple_bird"]
    ask targets with [who-visited = 2] [set shape "apple_bat"]
    ask targets with [who-visited = 3] [set shape "apple_both"]
end


to puntos
 ;;Movement
  let puntos_bird []
  let puntos_bat []
  let move_bird count(patches with [visit-bird > 0])
  let move_bat count(patches with [visit-bat > 0])
  ifelse(move_bird > move_bat)
  [set puntos_bird fput 2 puntos_bird
  set puntos_bat fput 0 puntos_bat]
  [set puntos_bat fput 2 puntos_bat
  set puntos_bird fput 0 puntos_bird]
 ;;Visit to orchards
  let tmp count birds with [norchard > 0]
  set tmp tmp * 2
  set puntos_bird lput tmp puntos_bird
  set tmp count bats with [norchard > 0]
  set tmp tmp * 2
  set puntos_bat lput tmp puntos_bat
  ;;Close to orchards
  set tmp count birds with [norchard = 0 and nclose > 0]
  set tmp tmp
  set puntos_bird lput tmp puntos_bird
  set tmp count bats with [norchard = 0 and nclose > 0]
  set tmp tmp
  set puntos_bat lput tmp puntos_bat
  ;;Orchard visited
  set tmp count targets with [who-visited = 1]
  let tmp2 count targets with [who-visited = 3]
  set tmp tmp + tmp2
  set puntos_bird lput tmp puntos_bird
  set tmp count targets with [who-visited = 2]
  set tmp2 count targets with [who-visited = 3]
  set tmp tmp + tmp2
  set puntos_bat lput tmp puntos_bat
  output-print word "Puntos pájaros " sum(puntos_bird)
  output-print word "Puntos murciélagos " sum(puntos_bat)
  ask birds [hide-turtle]
  ask bats [hide-turtle]
  ask targets [hide-turtle]
  ifelse(sum(puntos_bird) = sum(puntos_bat))
  [
    ask patches with [pxcor = -110 and pycor = 0]
    [sprout-birds 1 [set size 200 set shape "bird3"]
    ]
    ask patches with [pxcor = 0 and pycor = 150]
   [sprout-crowns 1 [set size 100 set shape "corona"]
   ]
    ask patches with [pxcor = 100 and pycor = 0]
    [sprout-bats 1 [set size 200 set shape "bat"]
    ]
  ]
  [
     ifelse(sum(puntos_bird) > sum(puntos_bat))
  [
    ask patches with [pxcor = 0 and pycor = 0]
    [sprout-birds 1 [set size 300 set shape "bird3"]
    ]
    ask patches with [pxcor = -90 and pycor = 100]
    [sprout-crowns 1 [set size 100 set shape "corona"]
    ]
  ]
  [ ask patches with [pxcor = 0 and pycor = 0]
    [sprout-bats 1 [set size 300 set shape "bat"]
    ]
    ask patches with [pxcor = 5 and pycor = 130]
    [sprout-crowns 1 [set size 100 set shape "corona"]
    ]
  ]
  ]
end


to prueba
  ask patches with [pxcor = -110 and pycor = 0]
    [sprout-birds 1 [set size 200 set shape "bird3"]
    ]
    ask patches with [pxcor = 0 and pycor = 150]
   [sprout-crowns 1 [set size 100 set shape "corona"]
   ]
    ask patches with [pxcor = 100 and pycor = 0]
    [sprout-bats 1 [set size 200 set shape "bat"]
    ]
   ; ask patches with [pxcor = 5 and pycor = 180]
   ; [sprout-crowns 1 [set size 100 set shape "corona"]
   ; ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
719
520
-1
-1
1.0
1
10
1
1
1
0
0
0
1
-250
250
-250
250
1
1
1
ticks
30.0

BUTTON
50
60
152
93
NIL
Ver_paisaje
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
29
141
201
174
Zonas-urbanas
Zonas-urbanas
0
100
50.0
1
1
NIL
HORIZONTAL

BUTTON
55
213
122
246
NIL
A-jugar\n
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
760
20
882
53
NIL
Donde-estuvieron
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
750
190
990
244
14

BUTTON
760
130
822
163
NIL
Puntos
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
760
80
877
113
NIL
Quien-visito-que
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

--Spanish

Cazadores de sonidos es un juego pensado para el público en general cuya finalidad es ilustrar cómo las preferencias por distintos tipos de hábitas modifican el movimiento de los animales y por tanto su distribución en el paisaje. Dos equipos van a luchar por conseguir el mayor número de grabaciones de sonidos de las especies que persiguen. Para ello van a poder modificar el paisaje en donde colocan sus grabadoras.

--English
Sound hunters is game designed to illustrate how habitat preferences can modify animal movement across the landscape, and hence, their distribution.Two teams will fight for attaining a greater number of recordings of sounds of a target species. To this end they will be able to modify the landscape in which acoustic loggers are placed.


## HOW IT WORKS

--Spanish
En el modelo tanto aves y murciélagos siguen una "correlated random walk" a la hora de moverse pero tienen preferencia por ciertos tipos de hábitat. Esto genera cambios en la trayectoria de movimiento modificando su distribución den el paisaje.

Hay dos equipos de jugadores buscando grabar sonidos de dos tipos de especies (1) un ave forestal (ej. herrerillo, Cyanistes caeruleus) y (2)  un  murciélago asociado a zonas urbanas (ej. murciélago enano, Pipistrellus pipistrellus). Cada grupo, por turno,s va a modificar las características del paisaje, colocar grabadores de sonidos en las 5 pumaradas de manzana. Luego aves y murciélagos van a moverse a partir de posiciones aleatorias. Después se contabilizan los puntos que consideran (i) qué grupo de animales se pudieron mover más a través del paisaje (ii) los sonidos que pudieron detectar de los diferentes grupos de animales tanto de manera nítida (cerca) como más ruidosa (lejos).

--English

Animals follow a correlated random walk when moving but have preferences for certain habitat types. As a result, their trajectories change modifying their distribution across the landacpe.

There are two teams searching for sounds of different species (1) a forest-dwelling bird and (2) a bat linked to urban areas. In each turn a team will set autorecordings in 5 apple orchards established across the landscape and will modifiy the amount of habitat to attain a higher number of records of the target species. Then, birds and bats will move across the landscape starting from random positions. Finally, points of each team will be calculated based on (i) which group of animals moved more freely across the landscape (ii) sounds that could be detected clearly (from inside the orchard) and more far away.

## HOW TO USE IT

Spanish---Por favor ver el pdf adjunto con las instrucciones

(1) Decidir la cantidad de zonas urbanas que va a tener el paisaje (en el deslizador de la izquierda). Ver el paisaje y la locación inicial de aves y murciélagos (botón).
(2) Dejar que se muevan aves y murciélagos.
(3) Observar las zonas por dónde se movieron para visualizar los "tracks" de los dos tipos de animales
(4) Contabilizar los puntos.
(5) Ver quién ganó.

English
(1) Decide teh amount of urban areas in the landscape. See the landscape and the initial location of birds and bats.
(2) Make birds and bats move.
(3) Look at the tracks of each animal type.
(4) Count points.
(3) Find out who won this turn.



## CREDITS AND REFERENCES

Teresa Morán López (University of Oviedo). Activity presented in "La vida entre manzanos" from the European Researchers night 2024.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

apple2
false
15
Polygon -2674135 true false 33 58 0 150 30 240 105 285 135 285 150 270 165 285 195 285 255 255 300 150 268 62 226 43 194 36 148 32 105 35
Line -16777216 false 106 55 151 62
Line -16777216 false 157 62 209 57
Polygon -6459832 true false 152 62 158 62 160 46 156 30 147 18 132 26 142 35 148 46
Polygon -16777216 false false 132 25 144 38 147 48 151 62 158 63 159 47 155 30 147 18

apple_bat
false
15
Polygon -7500403 true false 33 58 0 150 30 240 105 285 135 285 150 270 165 285 195 285 255 255 300 150 268 62 226 43 194 36 148 32 105 35
Line -16777216 false 106 55 151 62
Line -16777216 false 157 62 209 57
Polygon -6459832 true false 152 62 158 62 160 46 156 30 147 18 132 26 142 35 148 46
Polygon -16777216 false false 132 25 144 38 147 48 151 62 158 63 159 47 155 30 147 18

apple_bird
false
15
Polygon -11221820 true false 33 58 0 150 30 240 105 285 135 285 150 270 165 285 195 285 255 255 300 150 268 62 226 43 194 36 148 32 105 35
Line -16777216 false 106 55 151 62
Line -16777216 false 157 62 209 57
Polygon -6459832 true false 152 62 158 62 160 46 156 30 147 18 132 26 142 35 148 46
Polygon -16777216 false false 132 25 144 38 147 48 151 62 158 63 159 47 155 30 147 18

apple_both
false
15
Polygon -2064490 true false 33 58 0 150 30 240 105 285 135 285 150 270 165 285 195 285 255 255 300 150 268 62 226 43 194 36 148 32 105 35
Line -16777216 false 106 55 151 62
Line -16777216 false 157 62 209 57
Polygon -6459832 true false 152 62 158 62 160 46 156 30 147 18 132 26 142 35 148 46
Polygon -16777216 false false 132 25 144 38 147 48 151 62 158 63 159 47 155 30 147 18

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bat
false
3
Polygon -7500403 true false 130 71 178 73 192 103 195 163 190 196 175 215 137 216 123 193 118 153 115 100
Polygon -7500403 false false 132 109 132 109
Polygon -7500403 false false 57 84
Polygon -7500403 true false 111 98 82 79 82 79 35 86 13 119 13 140 37 131 37 131 34 155 72 143 86 175 103 157 120 170 137 132
Polygon -7500403 true false 201 91 230 72 230 72 277 79 299 112 299 133 275 124 275 124 278 148 240 136 229 170 209 150 192 163 175 125
Circle -16777216 true false 128 90 12
Circle -16777216 true false 128 90 12
Circle -16777216 true false 163 90 12
Line -16777216 false 83 81 81 81
Line -16777216 false 37 131 81 79
Line -16777216 false 73 144 81 82
Line -16777216 false 102 156 82 80
Line -16777216 false 240 136 230 72
Line -16777216 false 229 71 209 150
Line -16777216 false 276 124 232 74
Polygon -7500403 true false 165 74 170 60 178 75
Polygon -7500403 true false 130 73 135 59 143 74

bat1
true
3
Polygon -955883 true false 130 71 178 73 192 103 195 163 190 196 175 215 137 216 123 193 118 153 115 100
Polygon -7500403 false false 132 109 132 109
Polygon -7500403 false false 57 84
Polygon -955883 true false 111 98 82 79 82 79 35 86 13 119 13 140 37 131 37 131 34 155 72 143 86 175 103 157 120 170 137 132
Polygon -955883 true false 201 91 230 72 230 72 277 79 299 112 299 133 275 124 275 124 278 148 240 136 229 170 209 150 192 163 175 125
Circle -16777216 true false 128 90 12
Circle -16777216 true false 128 90 12
Circle -16777216 true false 163 90 12
Line -16777216 false 83 81 81 81
Line -16777216 false 37 131 81 79
Line -16777216 false 73 144 81 82
Line -16777216 false 102 156 82 80
Line -16777216 false 240 136 230 72
Line -16777216 false 229 71 209 150
Line -16777216 false 276 124 232 74
Polygon -955883 true false 165 74 170 60 178 75
Polygon -955883 true false 130 73 135 59 143 74

bat2
true
3
Polygon -13840069 true false 130 71 178 73 192 103 195 163 190 196 175 215 137 216 123 193 118 153 115 100
Polygon -7500403 false false 132 109 132 109
Polygon -7500403 false false 57 84
Polygon -13840069 true false 111 98 82 79 82 79 35 86 13 119 13 140 37 131 37 131 34 155 72 143 86 175 103 157 120 170 137 132
Polygon -13840069 true false 201 91 230 72 230 72 277 79 299 112 299 133 275 124 275 124 278 148 240 136 229 170 209 150 192 163 175 125
Circle -16777216 true false 128 90 12
Circle -16777216 true false 128 90 12
Circle -16777216 true false 163 90 12
Line -16777216 false 83 81 81 81
Line -16777216 false 37 131 81 79
Line -16777216 false 73 144 81 82
Line -16777216 false 102 156 82 80
Line -16777216 false 240 136 230 72
Line -16777216 false 229 71 209 150
Line -16777216 false 276 124 232 74
Polygon -13840069 true false 165 74 170 60 178 75
Polygon -13840069 true false 130 73 135 59 143 74

bird1
false
0
Polygon -955883 true false -1 120 44 90 74 90 104 120 149 120 239 135 284 120 284 135 299 150 239 150 194 165 254 195 209 195 149 210 89 195 59 180 44 135
Polygon -16777216 true false 105 182 150 197 150 197 165 197 120 182 105 182
Polygon -16777216 true false 128 173 173 188 173 188 188 188 143 173 128 173
Polygon -16777216 true false 157 171 202 186 202 186 217 186 172 171 157 171
Circle -16777216 true false 47 102 11
Polygon -1184463 true false 2 119 17 109 25 128 4 120

bird2
false
0
Polygon -13840069 true false -1 120 44 90 74 90 104 120 149 120 239 135 284 120 284 135 299 150 239 150 194 165 254 195 209 195 149 210 89 195 59 180 44 135
Polygon -16777216 true false 105 182 150 197 150 197 165 197 120 182 105 182
Polygon -16777216 true false 128 173 173 188 173 188 188 188 143 173 128 173
Polygon -16777216 true false 157 171 202 186 202 186 217 186 172 171 157 171
Circle -16777216 true false 47 102 11
Polygon -1184463 true false 2 119 17 109 25 128 4 120

bird3
false
0
Polygon -13345367 true false -1 120 44 90 74 90 104 120 149 120 239 135 284 120 284 135 299 150 239 150 194 165 254 195 209 195 149 210 89 195 59 180 44 135
Polygon -16777216 true false 105 182 150 197 150 197 165 197 120 182 105 182
Polygon -16777216 true false 128 173 173 188 173 188 188 188 143 173 128 173
Polygon -16777216 true false 157 171 202 186 202 186 217 186 172 171 157 171
Circle -16777216 true false 47 102 11
Polygon -1184463 true false 2 119 17 109 25 128 4 120

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

corona
false
0
Rectangle -1184463 true false 45 165 255 240
Polygon -1184463 true false 45 165 30 60 90 165 90 60 132 166 150 60 169 166 210 60 210 165 270 60 255 165
Circle -16777216 true false 222 192 22
Circle -16777216 true false 56 192 22
Circle -16777216 true false 99 192 22
Circle -16777216 true false 180 192 22
Circle -16777216 true false 139 192 22

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

crown
false
0
Rectangle -7500403 true true 45 165 255 240
Polygon -7500403 true true 45 165 30 60 90 165 90 60 132 166 150 60 169 166 210 60 210 165 270 60 255 165
Circle -16777216 true false 222 192 22
Circle -16777216 true false 56 192 22
Circle -16777216 true false 99 192 22
Circle -16777216 true false 180 192 22
Circle -16777216 true false 139 192 22

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

house2
false
0
Rectangle -1 true false 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -2674135 true false 15 120 150 15 285 120
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

mouse top
true
0
Polygon -7500403 true true 144 238 153 255 168 260 196 257 214 241 237 234 248 243 237 260 199 278 154 282 133 276 109 270 90 273 83 283 98 279 120 282 156 293 200 287 235 273 256 254 261 238 252 226 232 221 211 228 194 238 183 246 168 246 163 232
Polygon -7500403 true true 120 78 116 62 127 35 139 16 150 4 160 16 173 33 183 60 180 80
Polygon -7500403 true true 119 75 179 75 195 105 190 166 193 215 165 240 135 240 106 213 110 165 105 105
Polygon -7500403 true true 167 69 184 68 193 64 199 65 202 74 194 82 185 79 171 80
Polygon -7500403 true true 133 69 116 68 107 64 101 65 98 74 106 82 115 79 129 80
Polygon -16777216 true false 163 28 171 32 173 40 169 45 166 47
Polygon -16777216 true false 137 28 129 32 127 40 131 45 134 47
Polygon -16777216 true false 150 6 143 14 156 14
Line -7500403 true 161 17 195 10
Line -7500403 true 160 22 187 20
Line -7500403 true 160 22 201 31
Line -7500403 true 140 22 99 31
Line -7500403 true 140 22 113 20
Line -7500403 true 139 17 105 10

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

sheep2
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -6459832 true false 218 120 240 165 255 165 278 120
Circle -6459832 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -6459832 true false 276 85 285 105 302 99 294 83
Polygon -6459832 true false 219 85 210 105 193 99 201 83

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

target2
false
0
Circle -2674135 true false 0 0 300
Circle -16777216 true false 30 30 240
Circle -16777216 true false 90 90 120
Circle -2674135 true false 120 120 60

tree2
false
0
Circle -10899396 true false 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -10899396 true false 65 21 108
Circle -10899396 true false 116 41 127
Circle -10899396 true false 45 90 120
Circle -10899396 true false 104 74 152

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
NetLogo 6.4.0
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
