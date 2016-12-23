#!/bin/sh

if [ -z "$(pacmd list-sinks | grep record)" ]; then
	default_output=$(pacmd list-sinks | grep -A1 "* index" | grep -oP "<\K[^ >]+") 
	pactl load-module module-combine-sink \
		sink_name=record-n-play \
		slaves=$default_output \
		sink_properties=device.description="Record-and-Play"
	#elif : ; then
	#	echo "DEBUG: SINK EXISTS"
fi

offset=0.6
state=2
run=""

while [ "$run" != "q" ]; do
	music_lib=~/storage/media/music
	title=$(spotify-now -i %title)
	track=$(spotify-now -i %track)
	artist=$(spotify-now -i %artist)
	album=$(spotify-now -i %album)
	disc=$(spotify-now -i %disc)
	file="$music_lib"/"$artist"/"$album"/"$title.mp3"

#	echo "DEBUG: file = $file"
	if [ ! -d "$music_lib"/"$artist" ]; then
		mkdir "$music_lib"/"$artist"
		mkdir "$music_lib"/"$artist"/"$album"
	elif [ ! -d "$music_lib"/"$artist"/"$album" ]; then
		mkdir "$music_lib"/"$artist"/"$album"
	fi

	if [ "$artist" != "Ad" ] && [ $state == 0 ]; then
#		echo "DEBUG: RECORDING"
		parec --format=s16le -d record-n-play.monitor | \
			lame -r --quiet -q 3 --lowpass 17 --abr 192 - "$file" &
		state=1
	fi

	while [ $state != 0 ]; do
#		echo "DEBUG: STILL IN THE LOOP"
		if [ "$title" != "$(spotify-now -i %title)" ]; then
			if [ $state == 1 ]; then
				sleep $offset
				killall lame
				killall parec
				id3 	--artist "$artist" \
					--album "$album" \
					--track "$track" \
					--title "$title" \
					--comment "disc $disc" \
					"$file"
			fi
			state=0
		fi

     		if [ -n "$(spotify-now -p "1")" ] && [ $state != 2 ]; then
#			echo "DEBUG: PAUSE"
			killall lame
			killall parec
			rm "$file"
			state=2
		fi
	done
done

