#
# Script for compiling and installing FFmpeg from source on Amazon Linux 2 with support for Xilinx U30 cards
#

# 1 - Update host OS

sudo yum update -y
sudo yum upgrade -y

# 2 - Install build dependencies & other packages

sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
sudo yum install kernel-devel-$(uname -r) -y
sudo yum install kernel-headers-$(uname -r) -y
sudo yum install python -y
sudo yum install boost-devel -y
sudo yum install gcc-c++ -y
sudo yum install git -y

# 3 - Source and install the Xilinx U30 card drivers

git clone https://github.com/Xilinx/video-sdk
cd video-sdk/release/U30_Amazon_2.0_v1.5_20210827

# 4 - Configure the U30 cards

sudo ./install.sh
source /opt/xilinx/xrt/setup.sh
# sudo -s source /opt/xilinx/xcdr/setup.sh

# 5 - Use precompiled FFmpeg binary 

printf "\nDone.\n"
printf "\nAlways set up the runtime environment for the Xilinx Video SDK before running video transcoding jobs on your Amazon EC2 VT1 instance:\n"
printf "\nsource /opt/xilinx/xrt/setup.sh\n"

