# EC2 transcoding performance and video quality benchmark test with FFmpeg

## FFmpeg (latest version) compling and installing on EC2

### x86/Graviton instances setup (C5,C6i,C6a,C6g,C7g)

Run the following scripts to setup FFmpeg on x86/Graviton instances
```
source setup-cpu.sh
```

### Nvidia GPU instances setup (G4dn, G5)

Run the following scripts to setup FFmpeg on Nvidia GPU instances
```
source setup-nvidia.sh
```

### Xilinx U30 instances setup (VT1)

Run the following scripts to setup FFmpeg on VT1 instances
```
source setup-xilinx.sh
```

## FFmpeg transcoding performance benchmark test on EC2