# tuto on doing your first game in liko

## step 0 : draw player in sprite editor

press esc, back on android , to open editors and click on the tile editor:
paint youself a nice simple player sprite
![](1_paint_ply.gif)

## step 1: display your sprite 

navigate to the code editor and type

`clear()
Sprite(1,0,0)`

to clear console and display player
press esc/back to go to prompt and type
`run`

result:

![](2_cleardisp.gif)


## step 2: variables and the _draw() function

to store player state, we need to define variables
to be able to access it from everywhere in the program

open the code editor and add 

`px=0
py=0`

the `_draw()` function is called whenever LIKO 12 draws the screen,
you don't need to call it yourself

![](3_variables.png)

go to the prompt and type `run` :

![](4_result.png)
 

## step 3 : the _update() function and btn()

you will most probably always run your game logic in the `_update()` function,
liko calls it normally 60 times by second

this is where you would check for button/screen presses and change the player coordinates,
move the baddies.....

we will use the `btn()` function to check if arrows are pressed and change the player coordinates,
that are stored in 
`px
py`
we will use an ` if then end ` statement to do something when the button is pressed


create an update function with the following code :
`_update()
 if btn(1) then --checking if left is pressed
  px=px-1 -- this block is executed if the condition is met
 end


using the btn in update to move player

## step 4: ennemies , working on a list of unkown size
adding ennemies using a table and a factory method
maybe on scanning content of the map?

move ennemies from update function
