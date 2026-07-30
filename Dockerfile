FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /

RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv git wget curl unzip ffmpeg libgl1 \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python3 /usr/bin/python

RUN git clone https://github.com/comfyanonymous/ComfyUI.git /ComfyUI
WORKDIR /ComfyUI
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cu124

RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git /ComfyUI/custom_nodes/ComfyUI-Manager

WORKDIR /ComfyUI/custom_nodes

RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    cd ComfyUI-Impact-Pack && python install.py && cd ..

RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git && \
    cd ComfyUI-Impact-Subpack && python install.py && cd ..

RUN git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git
RUN git clone https://github.com/rgthree/rgthree-comfy.git
RUN git clone https://github.com/yolain/ComfyUI-Easy-Use.git
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git
RUN git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git --recursive
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git
RUN git clone https://github.com/sipherxyz/comfyui-art-venture.git
RUN git clone https://github.com/WASasquatch/was-node-suite-comfyui.git
RUN git clone https://github.com/evanspearman/ComfyMath.git
RUN git clone https://github.com/alexopus/ComfyUI-Image-Saver.git
RUN git clone https://github.com/Miosp/ComfyUI-FBCNN.git
RUN git clone https://github.com/Goshe-nite/comfyui-gps-supplements.git
RUN git clone https://github.com/pamparamm/ComfyUI-ppm.git
RUN git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git
RUN git clone https://github.com/Comfy-Org/Nvidia_RTX_Nodes_ComfyUI.git

RUN git clone https://github.com/Sen-sou/Comfyui-Anima-Regional-Conditioning.git
RUN git clone https://github.com/kohya-ss/ComfyUI-Anima-LLLite.git
RUN git clone https://github.com/Mirumo0u0/ComfyUI-Cosmos-Reference.git

RUN for dir in */; do \
      if [ -f "${dir}requirements.txt" ]; then \
        pip install --no-cache-dir -r "${dir}requirements.txt" || true; \
      fi; \
    done

WORKDIR /ComfyUI

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8188

ENTRYPOINT ["/start.sh"]
