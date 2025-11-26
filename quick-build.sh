#!/bin/bash

#make build raspberry-pi raspberrypi5 core-image-full-cmdline
#make sdk raspberry-pi raspberrypi5 core-image-full-cmdline

#make build nvidia-jetson jetson-agx-orin-devkit core-image-full-cmdline
#make sdk nvidia-jetson jetson-agx-orin-devkit core-image-full-cmdline

#make build nxp-imx imx93frdm core-image-full-cmdline
#make sdk nxp-imx imx93frdm core-image-full-cmdline

#make  build xilinx-zynq k26-smk-kr core-image-full-cmdline
#make sdk xilinx-zynq k26-smk-kr core-image-full-cmdline  

make build texas-instruments am62xx-evm tisdk-default-image
make sdk texas-instruments am62xx-evm tisdk-default-image