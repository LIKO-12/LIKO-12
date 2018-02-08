# tuto on doing your first game in liko

## step 0 : draw player in sprite editor

press esc, back on android , to open editors and click on the tile editor:
paint youself a nice simple player sprite
![](1_paint_ply.gif)

## step 1: display your sprite 

navigate to the code editor and type

```
clear()
Sprite(1,0,0)
```

to clear console and display player
press esc/back to go to prompt and type
`run`

result:

![](2_cleardisp.gif)

you will notice that the draw operation is executed one time,
then you are returned to the prompt 

## step 2: variables 

to store player state, we need to define variables
to be able to access it from everywhere in the program

open the code editor and add 

```
px=0
py=0
```

![](3_variables.png)

go to the prompt and type `run` :

![](4_result.png)
 
## step 3 : moving your display code to the _draw() function

the `_draw()` function is called whenever LIKO 12 draws the screen,
you don't need to call it yourself

up to this point our script was executed just one time ( clear the screen, display the player )
in the context of an arcade game to move everything fluidly , you the program never stops running,
_draw() is called up to 60 times a second

update your code snippet like such

```
px=0
py=0

_draw()
 clear()
 Sprite(1,px,py)
end
```
 ![](s3code.png)
 
if you type esc and run it, the result will be the same, but you will not be returned to the prompt,
only if you type esc you will interrupt the program !

![](s3result.png)
 
## step 4 : the _update() function and btn()

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
```
_update()
 if btn(1) then --checking if left is pressed
  px=px-1 -- this block is executed if the condition is met
 end
```
TODO png of program


if you `run` your cartridge from the prompt,
you will see you can move your player smoothly wih arrow keys

TODO gif of heli moving

## step 4: ennemies , working on a list of unkown size

we will add ennemies to a table,
so that we can have an unspecified amout depending on the level

let us declare a table to store ennemies:
```
ennemies = {}
```

then we will write a function to abstract the task of adding an ennemy 
```
function addennemy(ex,ey)
 ennemy={}
 ennemy.x=ex
 ennemy.y=ey
 table.insert(ennemies,ennemy)
end
```
adding ennemies using a table and a factory method
maybe on scanning content of the map?

move ennemies from update function

## step 5: simple collision

## step 6: colliding with ennemies

## step 7 : firing a bullet

## step 8: victory condition, function pointers in _update() and _draw() !
