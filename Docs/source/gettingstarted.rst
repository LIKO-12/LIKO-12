===============
Getting Started
===============

Here, we will show you how to install and start LIKO-12, keep in mind, in the future, this will get easier.

Prerequisites
-------------

* `LOVE2D`_: ``https://love2d.org/``
* `GIT`_: ``https://git-scm.com/`` (Can be skipped, see below)

Downloading LIKO-12
~~~~~~~~~~~~~~~~~~~

Fire up `GIT`_ and go to folder where do you want LIKO-12 installed then use following commands to download it::

    $ git init
    $ git clone -b WIP --single-branch https://github.com/RamiLego4Game/LIKO-12.git

Then each time you want to update, simply go again into folder of LIKO-12 and use following commands::

    $ git init
    $ git pull

Alternatively you can just download whole WIP branch via github here::
    https://github.com/RamiLego4Game/LIKO-12/archive/WIP.zip


.. note::
  It is not recommended to use the WIP.zip solution.

Running LIKO-12
~~~~~~~~~~~~~~~

On Windows, once you have installed `LOVE2D`_, you need to create a .bat file with following content::
    "C://Program Files/LOVE/love" "PATH TO LIKO-12 REPO"

On Mac and Linux, simple .sh file with following content will suffice::
    love .

.. TODO: Add What next?

.. _LÖVE: https://love2d.org/
.. _GIT: https://git-scm.com/