#!/bin/bash
#Toroyteach
#Generate Self signed ssl script
#This scripts takes a json object file from root folder (file.json) and creates self signed certificates with those values
#check out a sample.json file in the root folder to see how data should be formated

####Check if script is run as root

if [[ $(id -u) -ne 0 ]] ; then echo "You need Root priviledges to run this command" ; exit 1 ; fi

####check if the file exist first

DATAFILE=file.json

if [ -f "$DATAFILE" ]; then

	echo "File found successfully"

else

	echo "Error $DATAFILE does not exist or was not found."
	exit

fi

####Get the data from the json file and store in a file output

if jq -e . >/dev/null 2>&1 <<<"$json_string"; then


		####get the size of the json object and decrement
		ITEMSNUMBER=$( jq length $DATAFILE )
		JSONSIZE=$(( $ITEMSNUMBER - 1))

		for OUTERKEY in $( seq 0 $JSONSIZE ); do

			#generates an array out of the current elemnt of the json object
			mapfile -t arrSample < <(jq -r '.['$OUTERKEY']' $DATAFILE)

			####this is where outputs will be appended to
			FILECONTENTS=Data/output.txt

			for key in "${!arrSample[@]}"; do

				####Gets the array size then decrements
				FILESIZE=$(( ${#arrSample[@]} - 1 ))

				####escapes the first and second { and [ of any typical array
				if [ $key -lt 1 ]; then
					continue

				####breaks if the reaches end of array item size
				elif [ $key -eq $FILESIZE ]; then
					break

				####gets and passed the array keys and values through trim cut and sed commands to clean it then appends to the output file
				else
					echo "${arrSample[$key]}" | cut -d ":" -f 1,2 | tr -d "\"" | tr -d ":" | tr -d  "," | sed 's/ //' | sed 's/ /\//' | sed 's/ /=/'  >> $FILECONTENTS
					
				fi

			done

			####Gen a no space or line separated file from the output.

			FORMATEDFILE=$( cat "$FILECONTENTS" | tr '\n' ' ' | sed 's/ \//\//g' )

			#### Gen the Open ssl certificates and send out out to new folder with new date time sec as name

			TIME=$(($(date +%s%N)/1000000))
			NEWFOLDER=Data/$TIME
			mkdir $NEWFOLDER

			openssl genrsa -out "$NEWFOLDER"/key.pem
			openssl req -new -key "$NEWFOLDER"/key.pem -out "$NEWFOLDER"/csr.pem -subj "$FORMATEDFILE"
			openssl x509 -req -days 365 -in "$NEWFOLDER"/csr.pem -signkey "$NEWFOLDER"/key.pem -out "$NEWFOLDER"/cert.pem

			####delete the output file that was generated

			rm $FILECONTENTS

		done

	echo "Read file Successfully"

else

	echo "Error... Could not read file data"
	exit
	
fi
