loading and saving disks, running the programs

`save yourgame
`

do a disk pretty disk
`save yourgame.png`

`load yourgame
`

`run
`

variables:
```
px=2
msg=" u win "
```

objects:
```
obj = {}
obj.x=1
```

tables:
```
mylist = {}
table.insert(mylist,myobj)
for idx_in_table,obj in ipairs(mylist)
do
...
end
table.remove(mylist,idx_in_table)
```

draw screen callback :
```
function _draw()
 --do your drawing business here 
end
```

update your logic very nth ms:
```
function _update()
 -- check user interaction and update all of the game world 
 end
 ```

function pointers 
```
function myfunc()
 --bla bla
 end
 
 ptr=myfunc -- pointer definition / update
 ptr() -- actually calls function myfunc() ! 
 ```
blit sprite
```
Sprite(picnum,x,y)
```

blit tilemap
```
    map(x_were_you_blit,y_where_you_blit,x_in_map_editor,y_in_map_editor,width_in_tiles,height_in_tiles)    
```

play note
```
Audio.generate(1,250,1)
```
stop note 
```
Audio.generate()
```

sfx TODO
