#!/bin/bash

# number of concurrent uploads to use at a time
cores=7
#byteSize=1048576

# count the number of files that begin with "part"
fileCount=$(ls -1 | grep "^part*" | wc -l)
files=$(ls | grep "^part*")

iterations=$[$fileCount/$cores]

echo $fileCount
#echo $files
echo $iterations

# sudo dnf install jq

init=$(aws glacier initiate-multipart-upload --account-id - --part-size 1048576 --vault-name media1 --archive-description "Novemeber 2015")


echo $init

echo "---------------------------------------"
# xargs trims off the quotes
# jq pulls out the json element titled uploadId
uploadId=$(echo $init | jq '.uploadId' | xargs)
echo $uploadId

# replace 3 with $iterations
for i in {1..3} 
  do
     echo $i
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



