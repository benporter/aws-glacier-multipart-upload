# aws-glacier-multipart-upload
Script for uploading large files to AWS Glacier

Helpful AWS Glacier pages:
 - <a href="http://docs.aws.amazon.com/cli/latest/userguide/cli-using-glacier.html#cli-using-glacier-initiate">Using Amazon Glacier with the AWS Command Line Interface</a>
 - <a href="http://docs.aws.amazon.com/cli/latest/reference/glacier/index.html#cli-aws-glacier">AWS Glacier Command Reference</a>

Running scripts in parallel:
 - <a href="https://www.gnu.org/software/parallel/parallel_tutorial.html">GNU Parallel Tutorial</a>

This script depends on <b>jq</b> for dealing with json and <b>parallel</b> for submitting the upload commands in parallel.  If you are using Fed/CentOS/RHEL, then run the following:

    sudo dnf install jq
    sudo dnf install parallel
