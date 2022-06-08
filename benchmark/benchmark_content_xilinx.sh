#
# Script to generate multiple bitrate contents for Xilinx U30 transcoding video quality test,
# and uploaded to given s3 bucket set in scrpits 264to264_benchmark_xilinx.sh and 265to265_benchmark_xilinx.sh
#
# Usage:    source benchmark_content_xilinx.sh {ec2 instance type} {quality level: default/objective/subjective}
#
#           quality level: default/objective/subjective, H.264 and H.265 codecs on the Xilinx U30 cards can be tuned to 
#                          improve either objective visual quality (to optimize VMAF scores) or subjective visual quality.
#
# Sample:   source benchmark_content_xilinx.sh VT1.3x objective
#
# The bitrate could be customized with other values (seperated with space)
#

INSTANCE=$1
QUALITY=$2

BITRATE_HD=(3M 2.5M 2M 1.5M 1M 750K 500K 250K)
BITRATE_4K=(16M 14M 12M 10M 8M 6M 4M 2M)

if [ -z $1 ]; then
    INSTANCE="VT1.3x"
fi

if [ -z $2 ]; then
    QUALITY="default"
fi

for ((i=0;i<${#BITRATE_HD[@]};i++)); do
    source 264to264_benchmark_xilinx.sh 1 ${INSTANCE} ${BITRATE_HD[$i]} ${QUALITY}
done

for ((i=0;i<${#BITRATE_4K[@]};i++)); do
    source 265to265_benchmark_xilinx.sh 1 ${INSTANCE} ${BITRATE_4K[$i]} ${QUALITY}
done