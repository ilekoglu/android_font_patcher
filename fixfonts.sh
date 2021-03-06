#!/bin/bash

#alias clear='echo'

version=1
branch=master

mkdir -p tmp

check_updates() {
  echo -e "\nChecking for patcher updates"
  rm -f tmp/.updated 2>&1
  wget -qO tmp/.changelog https://raw.githubusercontent.com/johnfawkes/android_font_patcher/$branch/changelog.txt 2>/dev/null
  for i in fixfonts.sh,version; do
    local file="$(echo $i | cut -d , -f1)" value="$(echo $i | cut -d , -f2)"
    if [ $(wget -qO - https://raw.githubusercontent.com/JohnFawkes/android_font_patcher/$branch/$(basename $file) 2>/dev/null | grep "^$value=" | cut -d = -f2) -gt $(grep "^$value=" $file | cut -d = -f2) ]; then
      echo "$version" > tmp/.updated
      wget -qO $file https://raw.githubusercontent.com/JohnFawkes/android_font_patcher/$branch/$(basename $file) 2>/dev/null
    fi
  done
}

if [ -f tmp/.updated ]; then
  echo -e "Font patcher succesfully updated!"
  oldver="$(cat tmp/.updated)" newver="$version"
  oldline=$(sed -n "/^$oldver/=" tmp/.changelog) newline=$(sed -n "/^$newver/=" tmp/.changelog)
  echo "Changelog: $(sed -n "/^$newver/p" tmp/.changelog)"
  sed -n "$newline,$oldline p" tmp/.changelog | sed -E '/^[0-9]|^$/d'
  echo " "
  sleep 2
  echo -e "Please Press enter to continue "
  read -r enter
  case $enter in
    *) :
    ;;
  esac
fi

if [ ! -d PatcherLogs ]; then
  mkdir PatcherLogs
fi

exec 2>PatcherLogs/patcher-verbose.log
set -x 2>&1 >/dev/null

rm -f Fonts/Placeholder

# cmd & spinner <message>
e_spinner() {
  PID=$!
  h=0; anim='-\|/';
  while [ -d /proc/$PID ]; do
    h=$(((h+1)%4))
    sleep 0.02
    printf "\r${@} [${anim:$h:1}]"
  done
}                        

invalid() {
  echo "Invaild Option..."
  sleep 3
  clear
  menu
}

list_fonts() {
  echo "Loading fonts"
  num=2
  if [ -f listoffonts.txt ] || [ -f fontlist.txt ] || [ -f choices.txt ]; then
    rm -f listoffonts.txt >&2
    rm -f fontlist.txt >&2
    rm -f choices.txt >&2
  fi
  touch fontlist.txt 
  touch choices.txt
  echo "[1] Patch all fonts" >> fontlist.txt
  for i in $(find "Fonts/" -type d | sed 's#.*/##'); do
    sleep 0.1
    echo "[$num] $i" >> fontlist.txt
    echo "$num" >> choices.txt
    num=$((num + 1))
  done
}

roboto=(  
  Roboto-Black.ttf 
  Roboto-BlackItalic.ttf 
  Roboto-Bold.ttf 
  Roboto-BoldItalic.ttf 
  RobotoCondensed-Bold.ttf 
  RobotoCondensed-BoldItalic.ttf 
  RobotoCondensed-Italic.ttf 
  RobotoCondensed-Light.ttf 
  RobotoCondensed-LightItalic.ttf 
  RobotoCondensed-Regular.ttf 
  Roboto-Italic.ttf 
  Roboto-Light.ttf 
  Roboto-LightItalic.ttf 
  Roboto-Medium.ttf 
  Roboto-MediumItalic.ttf 
  Roboto-Regular.ttf 
  Roboto-Thin.ttf 
  Roboto-ThinItalic.ttf
)

copy_fonts() {
  c=0
  d=0
  IFS=$'\n'
  font=(/sdcard/Fontchanger/Patcher/*)
  font2=("$font"/*)
  for l in "${font[@]}"; do
    cp -rf "${l}" Fonts
    d=$((d+1))
  done
  font3=($(find "Fonts/" -type d | sed 's#.*/##'))
  font4=($( find Fonts/*/ -type f ))
  IFS=$'\n'
  for z in ${font3[@]}; do
    for i in "${!font4[@]}"; do
      for y in ${!roboto[@]}; do
        cp -f "${font4[i]}" "$(echo ${font4[i]} | sed 's/\(.*\)\/.*/\1/')/${roboto[y]}"
      done
    done
  done
  unset IFS
}

menu() {
  fontstyle=none
  choice=""
  all=false
  if [ ! -d Fonts ]; then
    echo "Fonts folder is not found! Creating...."
    echo "Please place fonts inside a folder with the name of font inside the patcher folder"
    mkdir Fonts
    exit
  fi
  copy_fonts
  for j in Fonts/*; do
    if [ -d "$j" ]; then
      list_fonts & e_spinner
      clear
      cat fontlist.txt
      break
    else
      echo "No Fonts Found"
      echo " "
      echo "Please place fonts inside a folder with the name of font inside the patcher folder"
      exit
    fi
  done
  wrong=$(cat fontlist.txt | wc -l)
  echo "Which font would you like to patch?"
  echo " "
  echo "Please enter the corresponding number"
  echo " "
  echo "[CHOOSE] : "
  echo " "
  read -r choice
    if [[ $choice == "1" ]]; then
      all=true
    elif [[ -n ${choice//[0-9]/} ]]; then
      invalid
    else
      [ $choice -gt $wrong ] && invalid
    fi
    if [[ $all == "true" ]]; then
      ls Fonts >> listoffonts.txt
      choice2=($(cat listoffonts.txt))
    else
      choice2="$(grep -w "$choice" fontlist.txt | tr -d '[' | tr -d ']' | tr -d "$choice" | tr -d ' ')"
    fi
  clear
  echo "Which style would you like to patch?"
  echo " "
  echo "If you have no roboto-*.ttf files for your font already, please select all to apply the font systemwide"
  echo " "
  echo "[0] Thin"
  echo " "
  echo "[1] ThinItalic"
  echo " "
  echo "[2] Light"
  echo " "
  echo "[3] LightItalic"
  echo " "
  echo "[4] Regular"
  echo " "
  echo "[5] Italic"
  echo " "
  echo "[6] Medium"
  echo " "
  echo "[7] MediumItalic"
  echo " "
  echo "[8] Bold"
  echo " "
  echo "[9] BoldItalic"
  echo " "
  echo "[10] Black"
  echo " "
  echo "[11] BlackItalic"
  echo " "
  echo "[12] All"
  read -r style
  case $style in
    0) fontstyle=Thin ;;
    1) fontstyle=ThinItalic;;
    2) fontstyle=Light;;
    3) fontstyle=LightItalic;;
    4) fontstyle=Regular;;
    5) fontstyle=Italic;;
    6) fontstyle=Medium;;
    7) fontstyle=MediumItalic;;
    8) fontstyle=Bold;;
    9) fontstyle=BoldItalic;;
    10) fontstyle=Black;;
    11) fontstyle=BlackItalic;;
    12) all2=true; fontstyle=(Thin ThinItalic Light LightItalic Regular Italic Medium MediumItalic Bold BoldItalic Black BlackItalic);;
    *) invalid
  esac
  clear
    for j in "${fontstyle[@]}"; do
      for k in "${choice2[@]}"; do
          ./font-patcher Fonts/"$k"/Roboto-$j.*
        if [[ $j == "Bold" ]] || [[ $j == "BoldItalic" ]] || [[ $j == "Italic" ]] || [[ $j == "Light" ]] || [[ $j == "LightItalic" ]] || [[ $j == "Regular" ]]; then
          ./font-patcher -cn Fonts/"$k"/RobotoCondensed-$j.* 2>&1
        fi
        echo "Moving fonts to custom fontchanger folder"
        mkdir /sdcard/Fontchanger/Fonts/Custom/$k
        mv Fonts/$k/Roboto-$j.ttf /sdcard/Fontchanger/Fonts/Custom/$k/
        if [[ $j == "Bold" ]] || [[ $j == "BoldItalic" ]] || [[ $j == "Italic" ]] || [[ $j == "Light" ]] || [[ $j == "LightItalic" ]] || [[ $j == "Regular" ]]; then
          mv Fonts/"$k"/RobotoCondensed-$j.ttf /sdcard/Fontchanger/Fonts/Custom/"$k"/
        fi
      done
    done        
  cp -rf PatcherLogs /sdcard/Fontchanger/
  for m in Fonts; do
    rm -rf "$m"
  done
}

menu
exit $?
