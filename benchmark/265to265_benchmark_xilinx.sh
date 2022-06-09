#
# Script to do benchmark test for Xilinx U30 transcoding performance with h.265 codec settings,
# log the performance result (frames per second) and upload the transcoded files to given s3 bucket
#
# Usage:    source 265to265_benchmark_xilinx.sh {batch size} {ec2 instance type} {transcoding bitrate} {quality level: default/objective/subjective}
#
#           batch size: concurrent number of ffmpeg transcoding process (make gpu utilization close to 100%)
#           ec2 instance type: instance type of ec2 for transcoding
#           transcoding bitrate: bitrate for transcoding, e.g. 800k, 2M
#           quality level: default/objective/subjective, H.264 and H.265 codecs on the Xilinx U30 cards can be tuned to 
#                          improve either objective visual quality (to optimize VMAF scores) or subjective visual quality.
#
# Sample:   source 265to265_benchmark_xilinx.sh 2 VT1.3x 8M objective
#
# Please make sure INPUT_BUCKET, OUTPUT_BUCKET and INPUT_FILE are set properly
#

BATCH_SIZE=$1
INSTANCE=$2
BITRATE=$3
QUALITY=$4
INPUT_BUCKET=s3://{input files bucket}/input/
OUTPUT_BUCKET=s3://{output files bucket}/output/
INPUT_FILE={input file}
INPUT_FOLDER=`pwd`/input
OUTPUT_FOLDER=`pwd`/output/${INSTANCE}
LOGS_FOLDER=`pwd`/logs/${INSTANCE}
LOG_FILE=${LOGS_FOLDER}/results.log
TEMP_FOLDER=`pwd`/temp

PROFILE="main"
CODEC="hevc"

if [ -z "$1" ]
    then
        BATCH_SIZE=2
fi

if [ -z "$2" ]
    then
        INSTANCE="VT1.3x"
fi

if [ -z $3 ]; then
    BITRATE=7M
fi

if [ -z $4 ]; then
    QUALITY=default
fi

batch_transcoding_process() {

    name=${INPUT_FILE%.*}
    output="${name}-${CODEC}-${INSTANCE}-${BITRATE}"

    python benchmark_xilinx.py -s ${INPUT_FOLDER}/${INPUT_FILE} -d ${output}.mp4 -u ${BATCH_SIZE} -i ${CODEC} -o ${CODEC} -b ${BITRATE} -v ${QUALITY}

}

wait_for_cpu_idle() {
    current=$(mpstat | awk '$13 ~ /[0-9.]+/ { print 100 - $13 }')
    echo "cpu usage: $current%"
    while [ $(echo "$current>25" | bc) -eq 1 ]; do
        current=$(mpstat | awk '$13 ~ /[0-9.]+/ { print 100 - $13 }')
        echo "cpu usage: $current%, the latest transcoding job may not finished yet"
        sleep 5
    done
}

## step 1 - download input files

mkdir -p ${INPUT_FOLDER} ${OUTPUT_FOLDER} ${LOGS_FOLDER} ${TEMP_FOLDER} ${LOGS_FOLDER}/temp

FILE=${INPUT_FOLDER}/${INPUT_FILE}
if [ -f "$FILE" ]; then
    echo "$INPUT_FILE exists, no need to download again."
else
    echo "$INPUT_FILE doesn't exist, start to download from S3."
    aws s3 sync ${INPUT_BUCKET} ${INPUT_FOLDER}
fi

## step 2 - transcoding input files

echo "======================================================" >> ${LOG_FILE}
batch_transcoding_process 

## step 3 upload results
cp ${output}.mp4 ${OUTPUT_FOLDER}/"${INPUT_FILE%.*}_${CODEC}_${BITRATE}_${QUALITY}.mp4"
aws s3 sync ${OUTPUT_FOLDER} ${OUTPUT_BUCKET}${INSTANCE}

## step 4 clean jobs
rm -rf ${TEMP_FOLDER}