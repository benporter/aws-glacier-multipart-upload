# aws-glacier-multipart-upload
Script for uploading large files to AWS Glacier

Helpful AWS Glacier pages:
 - <a href="http://docs.aws.amazon.com/cli/latest/userguide/cli-using-glacier.html#cli-using-glacier-initiate">Using Amazon Glacier with the AWS Command Line Interface</a>
 - <a href="http://docs.aws.amazon.com/cli/latest/reference/glacier/index.html#cli-aws-glacier">AWS Glacier Command Reference</a>

Running scripts in parallel:
 - <a href="https://www.gnu.org/software/parallel/parallel_tutorial.html">GNU Parallel Tutorial</a>

**Motivation**

The one-liner <a href="http://docs.aws.amazon.com/cli/latest/reference/glacier/upload-archive.html">upload-archive</a> isn't recommend for files over 100 MB, and you should instead use <a href="http://docs.aws.amazon.com/cli/latest/reference/glacier/upload-multipart-part.html">upload-multipart<a/>. The difficult part of using using multiupload is that it is really three major commands, with the second needing to repeated for every file to upload, and a custom byte range needs to be defined for each file chunk that is being uploaded.  For example, with a 4MB file (4194304 bytes) the first three files need the following argument.  This is repeated 1945 times for my 8GB file.
 - aws glacier upload-multipart-part --body partaa --range 'bytes 0-4194303/*' --account-id - --vault-name media1 --upload-id [your upload id here]
 - aws glacier upload-multipart-part --body partab --range 'bytes 4194304-8388607/*' --account-id - --vault-name media1 --upload-id [your upload id here]
 - aws glacier upload-multipart-part --body partac --range 'bytes 8388608-12582911/*' --account-id - --vault-name media1 --upload-id [your upload id here]
 - 1941 commands later...
 - aws glacier upload-multipart-part --body partzbxu --range 'bytes 8153726976-8157921279/*' --account-id - --vault-name media1 --upload-id [your upload id here]

We need a script to handle the math and autogenerate the code.  

This script leverages the <a href="https://www.gnu.org/software/parallel/parallel_tutorial.html">parallel</a> library, so my 1945 upload scripts are kicked off in parallel, but are queued up until a core is done with one before proceeding to the next.  There is even a progress bar built in that shows you what percent is complete, and an estimated wait time until it is done.

**Prerequisites**

All of the following items in the Prerequisites section only need to be done once to set things up. 

This script depends on <b>jq</b> for dealing with json and <b>parallel</b> for submitting the upload commands in parallel.  If you are using Fed/CentOS/RHEL, then run the following:

    sudo dnf install jq
    sudo dnf install parallel

It assumes you have an AWS account, and have signed up for the glacier service.  In this example, I have already created the vault named <i>backups</i> via AWS console.

It also assumes that you have the <a href="http://docs.aws.amazon.com/cli/latest/userguide/installing.html">AWS Command Line Interface</a> installed on your machine.  Again, if you are using Fed/CentOS/RHEL, then here is how you would get it:

    sudo pip install awscli

Configure your machine to pass credentials automatically.  This allows you pass a single dash with the account-id argument.

    aws configure
    
Additionally, in order to use the script properly, you will need java in order to compile and execute TreeHashExample.java

Before jumping into the script, verify that your connection works by describing the vault you have created, which is <i>backups</i> in my case. Run this describe-vault command and you should see similiar json results. 

    aws glacier describe-vault --vault-name backups --account-id -
    {
    "SizeInBytes": 11360932143, 
    "VaultARN": "arn:aws:glacier:us-east-1:<redacted>:vaults/backups", 
    "LastInventoryDate": "2015-12-16T01:23:18.678Z", 
    "NumberOfArchives": 7, 
    "CreationDate": "2015-12-12T02:22:24.956Z", 
    "VaultName": "backups"
    }
    
Also ensure that you change the bytesize to something reasonable for your archive. I've set it to be 2GB now that Glacier allows filesizes between 1MB and 4GB as parts for the multipart upload.

Download the glacierupload.sh script:

    wget https://raw.githubusercontent.com/benporter/aws-glacier-multipart-upload/master/glacierupload.sh

Make it executable:

    chmod u+x glacierupload.sh
    
You will also need to download and compile TreeHashExample.java.

    javac TreeHashExample.java

**Script Usage**

Tar and zip the files you want to upload:

    tar -zcvf my-backup.tar.gz /location/to/zip/*

Now chunk out your zipped file into equal peice chunks.  You can only pick multiples of 1MB up to 4MB.  This example chunks out the <i>my-backup.tar.gz</i> file into 4MB chunks, giving all of them the prefix <i>part</i> which is what the script expects to see.  If you choose something other than <i>part</i>, then you'll need to edit the script.

    split --bytes=4194304 --verbose my-backup.tar.gz part

Now it is time to run the script.  It assumes that your <i>part*</i> files and TreeHashExample are in the same directory as the script.

    ./glacierupload.sh my-backup.tar.gz


