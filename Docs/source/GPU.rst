==============
GPU Peripheral
==============

About:
======

The GPU Peripherals stands for *Graphics Proccessing Unit*, 
and it's used for drawing anything that would be shown on the user's screen.

.. note::
   All the functions of this peripheral are made **Globals** in **DiskOS**

Functions:
==========

GPU.clear
---------

**Usage**::

  clear(cid)

Clears the screen and fills it with a specific color.

**Arguments**:

:[cid] (0): **Number**: Color ID, The color to fill the screen with, must be in range [0,15].

GPU.color
---------

**Usage**:

1. **Set Color**::

     color(cid)

   Sets the current active drawing color.

   **Arguments**:
  
   :cid: **Number**: Color ID, The new active color id, must be in range [0,15].
  
2. **Get Color**::

     local cid = color()
  
   Gets the current active drawing color.
  
   **Returns**:
  
   :cid: **Number (Int)**: Color ID, The current active color id in range [0,15].
  
