#!/bin/bash

# number of concurrent uploads to use at a time
cores=7
byteSize=8388607

# count the number of files that begin with "part"
#fileCount=$(ls -1 | grep "^part*" | wc -l)
#files=$(ls | grep "^part*")
fileCount=$(ls -1 | grep "^partzam" | wc -l)
files=$(ls | grep "^partzam")

iterations=$[$fileCount/$cores]

echo $fileCount
#echo $files
echo $iterations

# sudo dnf install jq
# sudo dnf install parallel

init=$(aws glacier initiate-multipart-upload --account-id - --part-size 1048576 --vault-name media1 --archive-description "Novemeber 2015")

echo $init

echo "---------------------------------------"
# xargs trims off the quotes
# jq pulls out the json element titled uploadId
uploadId=$(echo $init | jq '.uploadId' | xargs)
echo $uploadId

i=0
for f in $files 
  do
     echo $f
     byteStart=$((i*byteSize))
     byteEnd=$((i*byteSize+byteSize-1))
     echo $i
     echo $byteStart
     echo $byteEnd
     aws glacier upload-multipart-part --body $f --range 'bytes '$byteStart'-'$byteEnd'/*' --account-id - --vault-name media1 --upload-id $uploadId
     i=$(($i+1))
     

  done

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
