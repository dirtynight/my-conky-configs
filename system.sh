#!/bin/bash

get_local_weather() {
#Be sure to include your city id and your api key for openweathermap here
#http://openwethermap.org
weather_file="$HOME/.config/weather.json"
city_id=3247449
api_key=2fbe39953408c97e893bd238e64a0f94
unit=metric
lang=de

if [[ ! -f "$weather_file" ]]; then
	touch $weather_file
fi

url="http://api.openweathermap.org/data/2.5/weather?id=${city_id}&appid=${api_key}&units=${unit}&lang=${lang}"


curl -s "$url" -o "$weather_file"
}

get_weather_icon() {
ICON_01D=""
ICON_01N=""
ICON_02=""
ICON_09=""
ICON_10=""
ICON_11=""
ICON_13=""
ICON_50=""
NO_DATA=""
WEATHER_ICON=$(cat ~/.config/weather.json | jq -r '.weather[0].icon')

if [[ "${WEATHER_ICON}" = *01d* ]]; then
    echo "${ICON_01D}"
elif [[ "${WEATHER_ICON}" = *01n* ]]; then
    echo "${ICON_01N}"
elif [[ "${WEATHER_ICON}" = *02d* || "${WEATHER_ICON}" = *02n* || "${WEATHER_ICON}" = *03d* || "${WEATHER_ICON}" = *03n* || "${WEATHER_ICON}" = *04d* || "${WEATHER_ICON}" = *04n* ]]; then
    echo "${ICON_02}"
elif [[ "${WEATHER_ICON}" = *09d* || "${WEATHER_ICON}" = *09n* ]]; then
    echo "${ICON_09}"
elif [[ "${WEATHER_ICON}" = *10d* || "${WEATHER_ICON}" = *10n* ]]; then
    echo "${ICON_10}"
elif [[ "${WEATHER_ICON}" = *11d* || "${WEATHER_ICON}" = *11n* ]]; then
    echo "${ICON_11}"
elif [[ "${WEATHER_ICON}" = *13d* || "${WEATHER_ICON}" = *13n* ]]; then
    echo "${ICON_13}"
elif [[ "${WEATHER_ICON}" = *50d* || "${WEATHER_ICON}" = *50n* ]]; then
    echo "${ICON_50}"
else
	echo "${NO_DATA}"
fi
}

vert_day() {
FILE="/tmp/year"
TEXT=$(date +%Y)
touch $FILE
awk '{ for (i=1; i<=NF; i++) { 
          for (j=1; j<=length($i); j++) { 
              printf("\${goto 270} %s\n", substr($i, j, 1)) 
          } 
          printf("\n") 
      } 
    }' <<< "$TEXT" > $FILE 
 cat "$FILE"
}

get_spotify_artist() {
artist=`dbus-send --print-reply --dest=org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata'|grep -E -A 2 "artist"|grep -E -v "artist"|grep -E -v "array"|cut -b 27-|cut -d '"' -f 1|grep -E -v ^$`
echo $artist
}
get_spotify_title() {
title=`dbus-send --print-reply --dest=org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata'|grep -E -A 1 "title"|grep -E -v "title"|cut -b 44-|cut -d '"' -f 1|grep -E -v ^$`
echo $title
}
get_img_url() {
img_url=`dbus-send --print-reply --dest=org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata' | grep -E -A 0 "image" | cut -d '"' -f2`
echo $img_url
}
get_spotify_album() {
album=`dbus-send --print-reply --dest=org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata'|grep -E -A 1 "album"|grep -E "^\s*variant"|cut -b 44-|grep -E -v ^$|sed 's/"$//'`
echo $album
}
get_spotify_id() {
id=`dbus-send --print-reply --session --dest=org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata' | grep spotify/track | cut -d '"' -f2`
echo $id
}
spotify_status() {
status=` dbus-send --print-reply --dest=org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'PlaybackStatus' | tail -1 | cut -d "\"" -f2`
echo $status
}
get_cover() {
id_current=$(cat /tmp/sandz_current.txt)
id_new=$(get_spotify_id)
cover=
img_url=
dbus=`busctl --user list | grep "vlc"`

if [ "$dbus" == "" ]; then
       `cp img/no_cover.jpeg /tmp/sandz_current.jpg`
	echo "" > /tmp/sandz_current.txt
else
	if [ "$id_new" != "$id_current" ]; then

		echo $id_new > /tmp/sandz_current.txt
		imgname=`cat /tmp/sandz_current.txt | cut -d '/' -f5`

		cover=`ls covers | grep "$id_new"`

		if grep -q "${imgname}" <<< "$cover"
		then
			`cp covers/$imgname.jpg /tmp/sandz_current.jpg`
		else
			img_url=$(get_img_url)
			`wget -q -O covers/$imgname.jpg $img_url &> /dev/null`
			`touch covers/$imgname.jpg`
			`cp covers/$imgname.jpg /tmp/sandz_current.jpg`
			rm -f `ls -t covers/* | awk 'NR>10'`
			rm -f wget-log 
		fi
	fi
fi
}

command=$1
shift

case $command in
    	weather)
        get_local_weather "$@"
        ;;
    	wicon)
        get_weather_icon "$@"
        ;;
    	vert)
	vert_day "$@" 
	;;
	spotstatus)
	spotify_status "$@"
	;; 
	spotify_artist)
	get_spotify_artist "$@"
	;;
	spotify_title)
	get_spotify_title "$@"
	;;
	spotify_album)
	get_spotify_album "$@"
	;;
	album_art)
	get_img_url "$@"
	;;
	getcover)
	get_cover "$@"
	;;
     *)
        exit 1
        ;;
esac
