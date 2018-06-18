local editorsheet = SpriteSheet(image(fs.read("editorsheet.lk12")),24,16)

pushPalette()
palt()
cursor(editorsheet:extract(1),"normal",1,1)
cursor(editorsheet:extract(2),"handrelease",2,1)
cursor(editorsheet:extract(3),"handpress",2,1)
cursor(editorsheet:extract(4),"hand",4,4)
cursor(editorsheet:extract(5),"cross",3,3)
cursor(editorsheet:extract(7),"point",1,1)
cursor(editorsheet:extract(8),"draw",3,3)

cursor(editorsheet:extract(32),"normal_white",1,1)

cursor(editorsheet:extract(149),"pencil",0,7)
cursor(editorsheet:extract(150),"bucket",0,7)
cursor(editorsheet:extract(151),"eraser",0,7)
cursor(editorsheet:extract(152),"picker",0,7)
popPalette()