#!/bin/bash

luacheck .

if [ $? -eq 1 ]
then
  exit 0
fi