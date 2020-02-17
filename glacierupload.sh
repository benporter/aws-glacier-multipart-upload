#!/bin/bash

# dependencies, jq and parallel:
# sudo dnf install jq
# sudo dnf install parallel
# sudo pip install awscli

byteSize=4194304

# count the number of files that begin with "part"
fileCount=$(ls -1 | grep "^part" | wc -l)
echo "Total parts to upload: " $fileCount

# get the list of part files to upload.  Edit this if you chose a different prefix in the split command
files=$(ls | grep "^part")

# initiate multipart upload connection to glacier
init=$(aws glacier initiate-multipart-upload --account-id - --part-size $byteSize --vault-name media1 --archive-description "November 2015 Pictures and Videos")

echo "---------------------------------------"
# xargs trims off the quotes
# jq pulls out the json element titled uploadId
uploadId=$(echo $init | jq '.uploadId' | xargs)

# create temp file to store commands
touch commands.txt

# create upload commands to be run in parallel and store in commands.txt
i=0
for f in $files 
  do
     byteStart=$((i*byteSize))
     byteEnd=$((i*byteSize+byteSize-1))
     echo aws glacier upload-multipart-part --body $f --range "'"'bytes '"$byteStart"'-'"$byteEnd"'/*'"'" --account-id - --vault-name media1 --upload-id $uploadId >> commands.txt
     i=$(($i+1))
     
  done

# run upload commands in parallel
#   --load 100% option only gives new jobs out if the core is less than 100% active
#   -a commands.txt runs every line of that file in parallel, in potentially random order
#   --no-notice supresses citation output to the console
#   --bar provides a command line progress bar
parallel --load 100% -a commands.txt --no-notice --bar

echo "List Active Multipart Uploads:"
echo "Verify that a connection is open:"
aws glacier list-multipart-uploads --account-id - --vault-name media1

# end the multipart upload
aws glacier abort-multipart-upload --account-id - --vault-name media1 --upload-id $uploadId

# list open multipart connections
echo "------------------------------"
echo "List Active Multipart Uploads:"
echo "Verify that the connection is closed:"
aws glacier list-multipart-uploads --account-id - --vault-name media1

#echo "-------------"
#echo "Contents of commands.txt"
#cat commands.txt
echo "--------------"
echo "Deleting temporary commands.txt file"
rm commands.txt


