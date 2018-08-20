Set the SaveID of the game, should be called before [LoadData](LoadData.md) and [SaveData](SaveData.md).

**The game SaveID can be only set once !**

Please make sure that your game saveid is unique and that it won't conflict with other's games,
Do something like `developerName_gameName`.
---

#### Syntax:
```lua
SaveID(id)
```

---

#### Arguments:

* **<id\> (String)**: The game SaveID.

---

##### See also:

* [SaveData()](SaveData.md)
* [LoadData()](LoadData.md)