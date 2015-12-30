#!/bin/bash

# This script will end all active AWS Glacier Multipart upload connections

# get all active multipart upload connections
activeConn=$(aws glacier list-multipart-uploads --account-id - --vault-name media1)

i=0
while true
  do
  echo ""
  echo "iteration $i"
  
  # parse out the multipart upload id to remove
  uploadId=$(echo $activeConn | jq '.UploadsList | .['$i'] | .MultipartUploadId' | xargs)
  
  # ends the while loop
  if [ "$uploadId" == "null" ]
  then
     echo "No more active connections to close"
     break
  else
     echo "Closing connection for: $uploadId"
     aws glacier abort-multipart-upload --account-id - --vault-name media1 --upload-id $uploadId
  fi

  # i++
  i=$[$i+1]

  # set a max iteration in case something breaks
  if [ "$i" -gt "35" ]
  then 
      echo "exceed iteration count"
      break
  fi

  done

echo ""
echo "Remaining Active Connections:"
echo "(this can happen with the ID starts with -)"
aws glacier list-multipart-uploads --account-id - --vault-name media1
