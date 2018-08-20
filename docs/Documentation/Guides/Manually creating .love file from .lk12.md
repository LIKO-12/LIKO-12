LIKO-12 Uses LÖVE Frawework, and so creating games binaries take the same steps.

First of all, we have to create a modified .love file, which is actually a .zip file, but with a different extenstion.

---

## 1- Start by downloading the LIKO-12_Universal.love build, from either itch.io or github

![Screenshot](../../_media/Game Packaging/SC-1.png)

## 2- Rename it from `.love` to `.zip` (In windows you will have to enable file extensions view, follow [this article](https://www.howtohaven.com/system/show-file-extensions-in-windows-explorer.shtml)).

---

![GIF](../../_media/Game Packaging/GIF-1.gif)

---

## 3- Extract the `.zip`

---

![GIF](../../_media/Game Packaging/GIF-2.gif)

---

## 4- Delete some unnecessary files

  * `/Peripherals/WEB`
  * `/Engine/luajit-request`
  * `/OS/DiskOS`
  * `/OS/PoorOS`

## 5- Create `build.json`, with the following content, replace the values with your game name

```json
{
  "Title": "LIKO-12 - Snake",
  "Appdata": "liko12_ramilego4game_snake"
}
```

## 6- Replace `game.lk12` in `/OS/GameDiskOS/game.lk12` with your game file

---

![GIF](../../_media/Game Packaging/GIF-3.gif)

---

## 7- Archive everything again

---

![GIF](../../_media/Game Packaging/GIF-4.gif)

---

## 8- Change the extension back to `.love`

---

![GIF](../../_media/Game Packaging/GIF-5.gif)

---

## 9- Now you may want to create Windows, Linux and Mac builds, if so, follow the classical LÖVE Instructions

  [LÖVE Wiki -> Game Distribution](https://love2d.org/wiki/Game_Distribution)

## 10- Enjoy !