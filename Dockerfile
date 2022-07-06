FROM ovhcom/ai-training-pytorch:1.8.1
LABEL maintainer="datalab-mi"

RUN apt update -y && \
    apt install -y bash \
                   build-essential \
                   g++ \
		   ffmpeg libsm6 libxext6 && \
    rm -rf /var/lib/apt/lists

WORKDIR /workspace
COPY requirements.txt requirements.txt
COPY workspace/* ./
RUN pip install --no-cache-dir -r requirements.txt

# Install mmdet with mim, the open detection package resolver
RUN pip install openmim==0.2.0
RUN mim install mmcv-full==1.5.3
RUN mim install  mmdet==2.24.0
