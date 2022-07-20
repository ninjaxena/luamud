#!/bin/bash
cd `dirname $0`
p=`pwd`
lua -e "MUD_LIB_PATH='$p/MudLib/'" $p/MudOS/main.lua
