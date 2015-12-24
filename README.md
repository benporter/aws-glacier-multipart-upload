# aws-glacier-multipart-upload
Script for uploading large files to AWS Glacier

Helpful AWS Glacier pages:
 - <a href="http://docs.aws.amazon.com/cli/latest/userguide/cli-using-glacier.html#cli-using-glacier-initiate">Using Amazon Glacier with the AWS Command Line Interface</a>
 - <a href="http://docs.aws.amazon.com/cli/latest/reference/glacier/index.html#cli-aws-glacier">AWS Glacier Command Reference</a>

Running scripts in parallel:
 - <a href="https://www.gnu.org/software/parallel/parallel_tutorial.html">GNU Parallel Tutorial</a>

**Motivation**

The one-liner <a href="http://docs.aws.amazon.com/cli/latest/reference/glacier/upload-archive.html">upload-archive</a> isn't recommend for files over 100 MB, and you should instead use <a href="http://docs.aws.amazon.com/cli/latest/reference/glacier/upload-multipart-part.html">upload-multipart<a/>.  This is advantageous because you can upload parts of the file in parallel.

**Prerequisites**

All of the following items in the Prerequisites section only need to be done once to set things up. 

This script depends on <b>jq</b> for dealing with json and <b>parallel</b> for submitting the upload commands in parallel.  If you are using Fed/CentOS/RHEL, then run the following:

    sudo dnf install jq
    sudo dnf install parallel

It assumes you have an AWS account, and have signed up for the glacier service.  In this example, I have already created the vault named <i>media1</i> via AWS console.

It also assumes that you have the AWS Command Line Interface installed on your machine.  Again, if you are using Fed/CentOS/RHEL, then here is how you would get it:

    sudo pip install awscli

Configure your machine to pass credentials automatically.  This allows you pass a single dash with the account-id argument.

    aws configure

Before jumping into the script, verify that your connection works by describing the vault you have created, which is <i>media1</i> in my case. Run this describ-vault command and you should see similiar json results. 

    aws glacier describe-vault --vault-name media1 --account-id -
    {
    "SizeInBytes": 11360932143, 
    "VaultARN": "arn:aws:glacier:us-east-1:<redacted>:vaults/media1", 
    "LastInventoryDate": "2015-12-16T01:23:18.678Z", 
    "NumberOfArchives": 7, 
    "CreationDate": "2015-12-12T02:22:24.956Z", 
    "VaultName": "media1"
    }

Download the glacierupload.sh script:

    wget https://raw.githubusercontent.com/benporter/aws-glacier-multipart-upload/master/glacierupload.sh

Make it executable:

    chmod u+x glacierupload.sh

**Script Usage**

Tar and zip the files you want to upload:

    tar -zcvf my-backup.tar.gz /location/to/zip/*

Now chunk out your zipped file into equal peice chunks.  You can only pick multiples of 1MB up to 4MB.  This example chunks out the <i>my-backup.tar.gz</i> file into 4MB chunks, giving all of them the prefix <i>part</i> which is what the script expects to see.  If you choose something other than <i>part</i>, then you'll need to edit the script.

    split --bytes=4194304 --verbose my-backup.tar.gz part

Now it is time to run the script.  It assumes that your <i>part*</i> files are in the same directory as the script.

    ./glacierupload.sh


