#!/bin/bash

# dependencies, jq and parallel:
# sudo dnf install jq
# sudo dnf install parallel
# sudo pip install awscli

byteSize=2147483648
vaultName='backups'

# count the number of files that begin with "part"
fileCount=$(ls -1 | grep "^part" | wc -l)
echo "Total parts to upload: " $fileCount

# get the list of part files to upload.  Edit this if you chose a different prefix in the split command
files=$(ls | grep "^part")

# initiate multipart upload connection to glacier
init=$(aws glacier initiate-multipart-upload --account-id - --part-size $byteSize --vault-name $vaultName --archive-description 'Upload Description')

echo "---------------------------------------"
# xargs trims off the quotes
# jq pulls out the json element titled uploadId
uploadId=$(echo $init | jq '.uploadId' | xargs)

# create temp file to store commands
touch commands.txt

#get total size in bytes of the archive
archivesize=`ls -l $1 | cut -d ' ' -f 8`

# create upload commands to be run in parallel and store in commands.txt
i=0
for f in $files 
  do
     filesize=`ls -l $f | cut -d ' ' -f 8`
     echo 'filesize '$filesize
     byteStart=$((i*byteSize))
     byteEnd=$((i*byteSize+byteSize-1))
     #if the filesize is less than the bytesize, set the bytesize to be the filesize
     if [ $byteEnd -gt $filesize ]; then
        byteEnd=$((filesize-1))
     fi
     echo aws glacier upload-multipart-part --body $f --range "'"'bytes '"$byteStart"'-'"$byteEnd"'/*'"'" --account-id - --vault-name $vaultName --upload-id $uploadId >> commands.txt
     i=$(($i+1))
     
  done

# run upload commands in parallel
#   --load 100% option only gives new jobs out if the core is than 100% active
#   -a commands.txt runs every line of that file in parallel, in potentially random order
#   --notice supresses citation output to the console
#   --bar provides a command line progress bar
parallel --load 100% -a commands.txt --no-notice --bar

echo "List Active Multipart Uploads:"
echo "Verify that a connection is open:"
aws glacier list-multipart-uploads --account-id - --vault-name $vaultName

#compute the tree hash
checksum=`java TreeHashExample $1 | cut -d ' ' -f 5`

# end the multipart upload
result=`aws glacier complete-multipart-upload --account-id - --vault-name $vaultName --upload-id $uploadId --archive-size $archivesize --checksum $checksum`

#store the json response from amazon for record keeping
touch result.json
echo $result >> result.json

# list open multipart connections
echo "------------------------------"
echo "List Active Multipart Uploads:"
echo "Verify that the connection is closed:"
aws glacier list-multipart-uploads --account-id - --vault-name $vaultName

#echo "-------------"
#echo "Contents of commands.txt"
#cat commands.txt
echo "--------------"
echo "Deleting temporary commands.txt file"
rm commands.txt

