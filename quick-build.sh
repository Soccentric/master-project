#!/bin/bash

make build raspberry-pi raspberrypi5 core-image-full-cmdline
make sdk raspberry-pi raspberrypi5 core-image-full-cmdline

make build nvidia-jetson jetson-agx-orin-devkit core-image-full-cmdline
make sdk nvidia-jetson jetson-agx-orin-devkit core-image-full-cmdline

make build nxp-imx imx93-9x9-lpddr4-qsb core-image-full-cmdline
make sdk nxp-imx imx93-9x9-lpddr4-qsb core-image-full-cmdline

make  build xilinx-zynq zynqmp-ev-generic core-image-full-cmdline
make sdk xilinx-zynq zynqmp-ev-generic core-image-full-cmdline  
