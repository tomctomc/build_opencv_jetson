#! /bin/bash

################################################################################
#
# automatically fetch and build our modified opencv on nvidia jetson tx2
#
################################################################################

OPENCV_SOURCE_DIR=$HOME/opencv_source
CMAKE_INSTALL_PREFIX=/usr/local

################################################################################

LOGBASE=log_`date +%Y%m%d%H%M`

NUM_CPU=$(nproc)

mkdir -p ${OPENCV_SOURCE_DIR}
cd ${OPENCV_SOURCE_DIR}

if [ -d opencv ]
then
	echo "********** REUSING ${OPENCV_SOURCE_DIR}/opencv - remove this before running to re-clone **********"
else
	git clone -b tomctomc https://github.com/tomctomc/opencv.git
fi

if [ -d opencv_contrib ]
then
	echo "********** REUSING ${OPENCV_SOURCE_DIR}/opencv_contrib - remove this before running to re-clone **********"
else
	git clone -b tomctomc https://github.com/tomctomc/opencv_contrib.git
fi


cd opencv
mkdir build
cd build

##### run cmake
LOGFILE=${LOGBASE}_cmake.txt
time cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} \
      -D WITH_CUDA=ON \
      -D CUDA_ARCH_BIN=${ARCH_BIN} \
      -D CUDA_ARCH_PTX="" \
      -D ENABLE_FAST_MATH=ON \
      -D CUDA_FAST_MATH=ON \
      -D WITH_CUBLAS=ON \
      -D WITH_LIBV4L=ON \
      -D WITH_GSTREAMER=ON \
      -D WITH_GSTREAMER_0_10=OFF \
      -D WITH_QT=OFF \
      -D WITH_OPENGL=OFF \
      -D CPACK_BINARY_DEB=ON \
	  -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
      ../ \
	2>&1 | tee ${LOGFILE}

if [ $? -eq 0 ] ; then
	echo "***** cmake success *****"
else
	echo "***** fatal: cmake error *****"
	exit 1
fi


##### run make
LOGFILE=${LOGBASE}_make.txt
time make -j$(($NUM_CPU - 1)) -i 2>&1 | tee ${LOGFILE}

if [ $? -eq 0 ] ; then
	echo "***** make success *****"
else
	echo "***** fatal: make error *****"
	exit 1
fi

##### run make install
LOGFILE=${LOGBASE}_makeinstall.txt
time sudo make install 2>&1 | tee ${LOGFILE}

if [ $? -eq 0 ] ; then
	echo "***** install success *****"
else
	echo "***** fatal: install error *****"
	exit 1
fi

##### run make package
sudo ldconfig  
LOGFILE=${LOGBASE}_makepackage.txt
time sudo make package -j$(($NUM_CPU - 1)) 2>&1 | tee ${LOGFILE}

if [ $? -eq 0 ] ; then
	echo "***** package build success *****"
else
	echo "***** fatal: package build error *****"
	exit 1
fi
