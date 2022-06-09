# EC2 transcoding performance and video quality benchmark test with FFmpeg

## 1. FFmpeg (latest version) compling and installing on EC2

### 1.1 x86/Graviton instances setup (C5,C6i,C6a,C6g,C7g)

```
source setup-cpu.sh
```

### 1.2 Nvidia GPU instances setup (G4dn, G5)

```
source setup-nvidia.sh
```

### 1.3 Xilinx U30 instances setup (VT1)

```
source setup-xilinx.sh
```

## 2. FFmpeg transcoding performance benchmark test on EC2

The performance metrics Total FPS (frames per second) will show after the benchmark script finish running, and the results will be logged in logs/{instance type}/results.log as well.

### 2.1 Prerequesite

Create the S3 bucket and path for storing input/output files, uploaded the 1080p/4K input files into the bucket, make sure INPUT_BUCKET, OUTPUT_BUCKET and INPUT_FILE of each script in this section are set properly

### 2.2 Benchmark HD/4K transcoding performance on CPU instances

* 1080p h.264 transcoding

Usage:  source 264to264_benchmark_cpu.sh {batch size} {ec2 instance type} {transcoding bitrate}

        batch size: concurrent number of ffmpeg transcoding process (make cpu utilization close to 100%)
        ec2 instance type: instance type of ec2 for transcoding
        transcoding bitrate: bitrate for transcoding, e.g. 800k, 2M
Sample:

```
source 264to264_benchmark_cpu.sh 5 C6g.4x 2.5M
```

* 4K h.265 transcoding

Usage:  source 265to265_benchmark_cpu.sh {batch size} {ec2 instance type} {transcoding bitrate}

        batch size: concurrent number of ffmpeg transcoding process (make cpu utilization close to 100%)
        ec2 instance type: instance type of ec2 for transcoding
        transcoding bitrate: bitrate for transcoding, e.g. 800k, 2M
Sample:

```
source 265to265_benchmark_cpu.sh 3 C7g.4x 8M
```

### 2.3 Benchmark HD/4K transcoding performance on Nvidia GPU instances

* 1080p h.264 transcoding

Usage:  source 264to264_benchmark_nvidia.sh {batch size} {ec2 instance type} {transcoding bitrate}

        batch size: concurrent number of ffmpeg transcoding process (make cpu utilization close to 100%)
        ec2 instance type: instance type of ec2 for transcoding
        transcoding bitrate: bitrate for transcoding, e.g. 800k, 2M
Sample:

```
source 264to264_benchmark_nvidia.sh 5 G4dn.x 2.5M
```

* 4K h.265 transcoding

Usage:  source 265to265_benchmark_nvidia.sh {batch size} {ec2 instance type} {transcoding bitrate}

        batch size: concurrent number of ffmpeg transcoding process (make cpu utilization close to 100%)
        ec2 instance type: instance type of ec2 for transcoding
        transcoding bitrate: bitrate for transcoding, e.g. 800k, 2M
Sample:

```
source 265to265_benchmark_nvidia.sh 3 G4dn.x 8M
```

### 2.4 Benchmark HD/4K transcoding performance on Xilinx U30 instances

* 1080p h.264 transcoding

Usage:  source 264to264_benchmark_xilinx.sh {batch size} {ec2 instance type} {transcoding bitrate} {quality level: default/objective/subjective}

        batch size: concurrent number of ffmpeg transcoding process (make gpu utilization close to 100%)
        ec2 instance type: instance type of ec2 for transcoding
        transcoding bitrate: bitrate for transcoding, e.g. 800k, 2M
        quality level: default/objective/subjective, H.264 and H.265 codecs on the Xilinx U30 cards can be tuned to improve either objective visual quality (to optimize VMAF scores) or subjective visual quality.
Sample:

```
source 264to264_benchmark_xilinx.sh 16 VT1.3x 2.5M objective
```

* 4K h.265 transcoding

Usage:  source 265to265_benchmark_xilinx.sh {batch size} {ec2 instance type} {transcoding bitrate} {quality level: default/objective/subjective}

        batch size: concurrent number of ffmpeg transcoding process (make gpu utilization close to 100%)
        ec2 instance type: instance type of ec2 for transcoding
        transcoding bitrate: bitrate for transcoding, e.g. 800k, 2M
        quality level: default/objective/subjective, H.264 and H.265 codecs on the Xilinx U30 cards can be tuned to improve either objective visual quality (to optimize VMAF scores) or subjective visual quality.
Sample:

```
source 265to265_benchmark_xilinx.sh 2 VT1.3x 8M objective
```

## 3. FFmpeg transcoding video quality (VMAF) benchmark test

### 3.1 Generate transcoded contents

The scripts will generate multiple bitrate contents for transcoding video quality test, and uploaded to given S3 bucket output folder that set in previous step. The transcoding bitrate could be customized with other values (seperated with space) in the scripts.

* Generate HD/4K transcoded contents of CPU transcoding

Usage:  source benchmark_content_cpu.sh {ec2 instance type}
Sample:

```
source benchmark_content_cpu.sh C6g.4x
```

* Generate HD/4K transcoded contents of Nvidia GPU transcoding

Usage:  source benchmark_content_nvidia.sh {ec2 instance type}
Sample:

```
source benchmark_content_nvidia.sh G4dn.x
```

* Generate HD/4K transcoded contents of Xilinx U30 transcoding

Usage:  source benchmark_content_xilinx.sh {ec2 instance type}
Sample:

```
source benchmark_content_xilinx.sh VT1.3x
```

### 3.2 Compute VMAF scores of the trancoded contents

The script will benchmark the video quality of multiple bitrate contents in vmaf scores, and uploaded CSV file to given S3 bucket (RESULT_BUCKET) set in the script. Please make sure INPUT_BUCKET, OUTPUT_BUCKET and RESULT_BUCKET are set properly before running the script.

Usage:  source benchmark_vmaf.sh {input file} {ec2 instance type} {vmaf model: HD/4K }

        input file: the original input file. The scripts will download all the transcoded files that start with title of the input file and compute the vmaf scores
        ec2 instance type: instance type of ec2 for transcoding
        vmaf model: HD/4K. Using HD for 1080p/720p and 4K for UHD/4K

Sample:
```
source benchmark_vmaf.sh bbb_sunflower_1080p_30fps_normal.mp4 C6g.4x HD
```