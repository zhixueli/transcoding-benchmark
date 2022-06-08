#
# Script to generate multiple bitrate contents for Nvidia GPU transcoding video quality test,
# and uploaded to given s3 bucket set in scrpits 264to264_benchmark_nvidia.sh and 265to265_benchmark_nvidia.sh
#
# Usage:    source benchmark_content_nvidia.sh {ec2 instance type}
# Sample:   source benchmark_content_nvidia.sh G4dn.x
#
# The bitrate could be customized with other values (seperated with space)
#

INSTANCE=$1

BITRATE_HD=(3M 2.5M 2M 1.5M 1M 750K 500K 250K)
BITRATE_4K=(16M 14M 12M 10M 8M 6M 4M 2M)

if [ -z $1 ]; then
    INSTANCE="G4dn.x"
fi

for ((i=0;i<${#BITRATE_HD[@]};i++)); do

    source 264to264_benchmark_nvidia.sh 1 ${INSTANCE} ${BITRATE_HD[$i]}

done

for ((i=0;i<${#BITRATE_4K[@]};i++)); do

    source 265to265_benchmark_nvidia.sh 1 ${INSTANCE} ${BITRATE_4K[$i]}

done