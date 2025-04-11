FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# ----------- 1. Dependencies -----------
RUN apt-get update && apt-get install -y \
    build-essential cmake git pkg-config libgtk-3-dev \
    libavcodec-dev libavformat-dev libswscale-dev \
    libv4l-dev libxvidcore-dev libx264-dev \
    libjpeg-dev libpng-dev libtiff-dev \
    gfortran openexr libatlas-base-dev \
    python3-dev python3-pip python3-numpy \
    libtbb2 libtbb-dev libdc1394-22-dev \
    libeigen3-dev libgflags-dev libgoogle-glog-dev \
    libprotobuf-dev protobuf-compiler \
    libgphoto2-dev libhdf5-dev libopenexr-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    qtbase5-dev wget unzip

# ----------- 2. Install Glog RC2  -----------
WORKDIR /opt
RUN git clone https://github.com/google/glog.git && \
    cd glog && git checkout v0.6.0 && mkdir build && cd build && \
    cmake .. && make -j$(nproc) && make install

# ----------- 3. Ceres Solver 2.1 -----------
WORKDIR /opt
RUN git clone https://github.com/ceres-solver/ceres-solver.git && \
    cd ceres-solver && git checkout 2.1.0 && mkdir build && cd build && \
    cmake .. && make -j$(nproc) && make install

# ----------- 4. OpenCV + Contrib -----------
WORKDIR /opt
RUN git clone https://github.com/opencv/opencv.git && \
    cd opencv && git checkout 4.5.2

RUN git clone https://github.com/opencv/opencv_contrib.git && \
    cd opencv_contrib && git checkout 4.5.2

WORKDIR /opt/opencv/build
RUN cmake \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=$(python3 -c "import sys; print(sys.prefix)") \
    -D INSTALL_PYTHON_EXAMPLES=ON \
    -D INSTALL_C_EXAMPLES=ON \
    -D WITH_TBB=ON \
    -D WITH_CUDA=OFF \
    -D BUILD_opencv_cudacodec=OFF \
    -D ENABLE_FAST_MATH=1 \
    -D CUDA_FAST_MATH=1 \
    -D WITH_CUBLAS=1 \
    -D WITH_V4L=ON \
    -D WITH_QT=OFF \
    -D WITH_OPENGL=ON \
    -D WITH_GSTREAMER=ON \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D OPENCV_ENABLE_NONFREE=ON \
    -D OPENCV_EXTRA_MODULES_PATH=/opt/opencv_contrib/modules \
    -D OPENCV_PYTHON3_INSTALL_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
    -D PYTHON_EXECUTABLE=$(which python3) \
    -D BUILD_TESTS=ON \
    -D BUILD_EXAMPLES=ON \
    ..

RUN make -j$(nproc) && make install && ldconfig

# ----------- 5. Environment ready -----------
WORKDIR /workspace
COPY . /workspace

CMD [ "bash" ]
