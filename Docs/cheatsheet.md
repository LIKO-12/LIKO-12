loading and saving disks, running the programs

`save yourgame
`

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
```mylist = {}
table.insert(mylist,myobj)
for idx_in_table,obj in ipairs(mylist)
do
...
end
table.remove(mylist,idx_in_table)```

draw screen callback :
`function _draw()
 --do your drawing business here 
end`

update your logic very nth ms:
`function _update()
 -- check user interaction and update all of the game world 
 end`

function pointers 
`function myfunc()
 --bla bla
 end
 
 ptr=myfunc -- pointer definition / update
 ptr() -- actually calls function myfunc() ! `
 

