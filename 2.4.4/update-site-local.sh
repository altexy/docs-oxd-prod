#! /bin/bash
git pull
echo -n "Enter task Performed >"
read text
echo "Entered Task: $text"
git add -A
git commit -m "updated site $text"
git push origin 2.4.4