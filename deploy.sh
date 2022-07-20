#!/bin/sh
cp -R ./* ~/WinE/Projects/StudyLua/
rsync -avz -e "ssh -p 36000" . wadehan@10.12.234.223:/home/wadehan/StudyLua
