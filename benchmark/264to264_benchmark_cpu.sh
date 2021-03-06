#
# Script to do benchmark test for CPU transcoding performance with h.264 codec settings,
# log the performance result (frames per second) and upload the transcoded files to given s3 bucket
#
# Usage:    source 264to264_benchmark_cpu.sh {batch size} {ec2 instance type} {transcoding bitrate}
#
#           batch size: concurrent number of ffmpeg transcoding process (make cpu utilization close to 100%)
#           ec2 instance type: instance type of ec2 for transcoding
#           transcoding bitrate: bitrate for transcoding, e.g. 800k, 2M
#
# Sample:   source 264to264_benchmark_cpu.sh 5 C6g.4x 2.5M
#
# Please make sure INPUT_BUCKET, OUTPUT_BUCKET and INPUT_FILE are set properly
#

BATCH_SIZE=$1
INSTANCE=$2
BITRATE=$3
INPUT_BUCKET=s3://{input files bucket}/input/
OUTPUT_BUCKET=s3://{output files bucket}/output/
INPUT_FILE={input file}
INPUT_FOLDER=`pwd`/input
OUTPUT_FOLDER=`pwd`/output/${INSTANCE}
LOGS_FOLDER=`pwd`/logs/${INSTANCE}
LOG_FILE=${LOGS_FOLDER}/results.log
TEMP_FOLDER=`pwd`/temp

PROFILE="high"
CODEC="libx264"

VCPU=`nproc`

if [ -z $1 ]; then
    BATCH_SIZE=5
fi

if [ -z $2 ]; then
    INSTANCE="C5.4x"
fi

if [ -z $3 ]; then
    BITRATE=3M
fi

#ffmpeg -y -hwaccel auto -i $i -c:v libx264 -pix_fmt yuv420p -profile:v high -preset faster -rc-lookahead:v 0 -bf:v 2 -coder:v cabac -b:v 7M -c:a copy out.mp4 -report

batch_transcoding_process() {

    name=${INPUT_FILE%.*}
    output="${name}-${CODEC}-${INSTANCE}-${BITRATE}"
    temp_log=${LOGS_FOLDER}/temp/${output}

    for ((n=0;n<$BATCH_SIZE;n++)); do
        echo "batch job id $n start..."
        if [ $n -eq $((BATCH_SIZE-1)) ]; then
            echo "please waiting for the transcoding jobs complete..."
            nohup bash -c "(time ffmpeg -y -hwaccel auto -i ${INPUT_FOLDER}/${INPUT_FILE} -c:v ${CODEC} -pix_fmt yuv420p -profile:v ${PROFILE} -preset faster -rc-lookahead:v 0 -bf:v 2 -coder:v cabac -b:v ${BITRATE} -c:a copy ${TEMP_FOLDER}/${output}_$n.mp4 2>&1 ) > ${temp_log}_$n.log 2>&1" >/dev/null 2>&1
        else
            nohup bash -c "(time ffmpeg -y -hwaccel auto -i ${INPUT_FOLDER}/${INPUT_FILE} -c:v ${CODEC} -pix_fmt yuv420p -profile:v ${PROFILE} -preset faster -rc-lookahead:v 0 -bf:v 2 -coder:v cabac -b:v ${BITRATE} -c:a copy ${TEMP_FOLDER}/${output}_$n.mp4 2>&1 ) > ${temp_log}_$n.log 2>&1 &" >/dev/null 2>&1
        fi
    done

    echo "transcoding jobs complete..."
    sleep 3
    #wait_for_cpu_idle

    fps_total=0
    cpu_usage_total=0

    for ((n=0;n<$BATCH_SIZE;n++)); do

        # Get ffmpeg transcoding frames per second 
        fps=`cat ${temp_log}_$n.log | awk -F'=' '/fps=/ {print $(NF-7)}' | awk '{print $1}'`
        fps_total=`echo "$fps_total+$fps" | bc`
        # Get CPU usage
        user=`cat ${temp_log}_$n.log | awk '/user/ {print $2}' | awk -F'm' '{printf 60*int($1*100)/100+int($2*100)/100}'`
        real=`cat ${temp_log}_$n.log | awk '/real/ {print $2}' | awk -F'm' '{printf 60*int($1*100)/100+int($2*100)/100}'`
        cpu_usage=`echo "scale=4;$user/$real/$VCPU*100;" | bc`
        cpu_usage_total=`echo "$cpu_usage_total+$cpu_usage" | bc`
        # Log cpu_usage and fps
        echo "${output} trancode job #$n cpu_usage:$cpu_usage fps:${fps} frames per second"
        echo "${output} trancode job #$n cpu_usage:$cpu_usage fps:${fps} frames per second" >> ${LOG_FILE}

    done

    echo "${output} trancode jobs total cpu_usage:$cpu_usage_total fps:${fps_total} frames per second"
    echo "${output} trancode jobs total cpu_usage:$cpu_usage_total fps:${fps_total} frames per second" >> ${LOG_FILE}

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
cp ${TEMP_FOLDER}/${output}_0.mp4 ${OUTPUT_FOLDER}/"${INPUT_FILE%.*}_${CODEC}_${BITRATE}.mp4"
aws s3 sync ${OUTPUT_FOLDER} ${OUTPUT_BUCKET}${INSTANCE}

## step 4 clean jobs
rm -rf ${TEMP_FOLDER}