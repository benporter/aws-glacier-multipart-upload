#!/bin/bash

# dependencies, jq and parallel:
# sudo dnf install jq
# sudo dnf install parallel
# sudo pip install awscli

jqCMD=$( which jq )
parallelCMD=$( which parallel )
pipCMD=$( which pip )
awsCMD=$( which aws )

if [ -z "$jqCMD" ] || [ -z "$pipCMD" ] || [ -z "$parallelCMD" ] || [ -z "$awsCMD" ]; then
	echo; echo;
	echo Missing prerequisites:
	echo       jq [ $jqCMD ]
	echo      pip [ $pipCMD ]
	echo      aws [ $awsCMD ]
	echo paralell [ $paralellCMD ]
	echo; echo;

	exit 1
fi

if [ -z "$1" ] || [ -z "$2" ]  || [ -z "$3" ] || [ -z "$4" ]; then
	echo; echo;
	echo "Syntax: $0 [ Source File Name ] [ Profile Name ] [ Vault Name ] [ Archive Description ]"
	echo; echo;

	exit 1
fi

srcFile=$1
profileName=$2
vaultName=$3
archiveDesc=$4

if [ ! -s "$srcFile" ]; then
	echo; echo; 
	echo "Source file does not exist [ $srcFile ]"
	echo; echo; 
	
	exit 1
fi

partPrefix="glacierPart_"

# chunkMb needs to be 1, 2, 4, 8, 32, 64 - It's not recommended to go above 100mb chunks for uploads
chunkMb=32
byteSize=$( bc <<<"1024*1024*$chunkMb" )

srcFileSize=$( stat -c%s $srcFile )

if [[ $srcFileSize < $byteSize ]]; then
	echo; echo
	echo "file [ $srcFile ] size [ $srcFileSize ] < [ $byteSize ] "
	echo; echo

	aws glacier upload-archive --profile $profileName --account-id - --vault-name $vaultName --body $srcFile
else


	# make tmp directory to split file
	ramDisk="/dev/shm"
	tmpPrefix="glacierUpload_"
	
	previousTmpDirs=$(ls $ramDisk/$tmpPrefix* 2> /dev/null )
	if [ ! -z "$previousTmpDirs" ]; then
		echo ; echo
	
		echo Previous temp directories exist
		echo $previousTmpDirs
		echo remove contents before continuing. This Only happens when the previous execution fails!
	
		echo ; echo
		
		exit 
	fi
	
	tmpDir="$ramDisk/$tmpPrefix$( date +"%s" )"
	echo "Creating [ $tmpDir ]"
	mkdir -p $tmpDir
	
	# split the file
	split --bytes=$byteSize --verbose $srcFile $tmpDir/$partPrefix
	
	# count the number of files that begin with "$partPrefix"
	fileCount=$(ls -1 $tmpDir | grep "^$partPrefix" | wc -l)
	echo "Total parts to upload: " $fileCount
	
	cd $tmpDir
	
	# get the list of part files to upload.  Edit this if you chose a different prefix in the split command
	files=$(ls | grep "^$partPrefix")
	echo "Files: ${#files[@]}"
	
	# initiate multipart upload connection to glacier
	init=$(aws glacier initiate-multipart-upload --profile $profileName --account-id - --part-size $byteSize --vault-name $vaultName --archive-description "$archiveDesc")
	
	echo "---------------------------------------"
	# xargs trims off the quotes
	# jq pulls out the json element titled uploadId
	uploadId=$(echo $init | jq '.uploadId' | xargs)
	
	echo uploadID [ $uploadId ]
	
	# create temp file to store commands
	touch commands.txt
	
	# create upload commands to be run in parallel and store in commands.txt
	i=0
	for f in $files 
	  do
	     byteStart=$((i*byteSize))
	     byteEnd=$((i*byteSize+byteSize-1))
	     echo aws glacier upload-multipart-part --body $f --range "'"'bytes '"$byteStart"'-'"$byteEnd"'/*'"'" --profile $profileName --account-id - --vault-name $vaultName --upload-id $uploadId >> commands.txt
	     i=$(($i+1))
	     
	  done
	
	# run upload commands in parallel
	#   --load 100% option only gives new jobs out if the core is than 100% active
	#   -a commands.txt runs every line of that file in parallel, in potentially random order
	#   --notice supresses citation output to the console
	#   --bar provides a command line progress bar
	parallel --load 100% -a commands.txt --eta --progress
	
	echo "List Active Multipart Uploads:"
	echo "Verify that a connection is open:"
	aws glacier list-multipart-uploads --profile $profileName --account-id - --vault-name $vaultName
	
	# end the multipart upload
	aws glacier abort-multipart-upload --profile $profileName --account-id - --vault-name $vaultName --upload-id $uploadId
	
	# list open multipart connections
	echo "------------------------------"
	echo "List Active Multipart Uploads:"
	echo "Verify that the connection is closed:"
	aws glacier list-multipart-uploads --profile $profileName --account-id - --vault-name $vaultName
	
	#echo "-------------"
	#echo "Contents of commands.txt"
	cat commands.txt
	echo "--------------"
	echo "Deleting temporary commands.txt file"
	rm commands.txt
	
	rm -rf $tmpDir

fi
