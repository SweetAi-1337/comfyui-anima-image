#!/bin/bash
set -e

COMFY=/ComfyUI

mkdir -p "$COMFY/models/diffusion_models" \
         "$COMFY/models/text_encoders" \
         "$COMFY/models/vae" \
         "$COMFY/models/controlnet" \
         "$COMFY/models/loras" \
         "$COMFY/models/ultralytics/bbox" \
         "$COMFY/models/upscale_models"

download_if_missing() {
  local url="$1"
  local dest="$2"
  if [ -f "$dest" ]; then
    echo "[skip] уже есть: $dest"
  else
    echo "[download] $dest"
    wget -q --show-progress -O "$dest" "$url"
  fi
}

echo "=== Скачиваю базовые файлы Anima ==="
download_if_missing \
  "https://huggingface.co/circlestone-labs/Anima/resolve/main/split_files/text_encoders/qwen_3_06b_base.safetensors" \
  "$COMFY/models/text_encoders/qwen_3_06b_base.safetensors"

download_if_missing \
  "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors" \
  "$COMFY/models/vae/qwen_image_vae.safetensors"

echo "=== ControlNet / Inpainting ==="
download_if_missing \
  "https://huggingface.co/kohya-ss/Anima-LLLite/resolve/main/anima-lllite-inpainting-v2.safetensors" \
  "$COMFY/models/controlnet/anima-lllite-inpainting-v2.safetensors"

echo "=== Детейлеры ==="
download_if_missing \
  "https://huggingface.co/Bingsu/adetailer/resolve/main/hand_yolov8s.pt" \
  "$COMFY/models/ultralytics/bbox/hand_yolov8s.pt"

download_if_missing \
  "https://huggingface.co/Anzhc/Anzhcs_YOLOs/resolve/main/Anzhc%20Face%20seg%201024%20v2%20y8n.pt" \
  "$COMFY/models/ultralytics/bbox/face_anzhc.pt"

download_if_missing \
  "https://huggingface.co/Tenofas/ComfyUI/resolve/main/ultralytics/bbox/Eyeful_v2-Paired.pt" \
  "$COMFY/models/ultralytics/bbox/eyes_detector.pt"

echo "=== Апскейл-модель ==="
download_if_missing \
  "https://huggingface.co/Kim2091/2x-AnimeSharpV4/resolve/main/2x-AnimeSharpV4_Fast_RCAN_PU.safetensors" \
  "$COMFY/models/upscale_models/2x-AnimeSharpV4_Fast_RCAN_PU.safetensors"

# === Файлы с Civitai (нужен CIVITAI_TOKEN) ===
if [ -n "$CIVITAI_TOKEN" ]; then
  echo "=== Скачиваю модели с Civitai ==="

  # Чекпоинты (несколько, через запятую в ANIMA_CHECKPOINT_URLS)
  if [ -n "$ANIMA_CHECKPOINT_URLS" ]; then
    IFS=',' read -ra CKPT_URLS <<< "$ANIMA_CHECKPOINT_URLS"
    i=1
    for url in "${CKPT_URLS[@]}"; do
      download_if_missing \
        "${url}&token=${CIVITAI_TOKEN}" \
        "$COMFY/models/diffusion_models/checkpoint_${i}.safetensors"
      i=$((i+1))
    done
  fi

  # Лоры стиля (несколько, через запятую в STYLE_LORA_URLS)
  if [ -n "$STYLE_LORA_URLS" ]; then
    IFS=',' read -ra STYLE_URLS <<< "$STYLE_LORA_URLS"
    i=1
    for url in "${STYLE_URLS[@]}"; do
      download_if_missing \
        "${url}&token=${CIVITAI_TOKEN}" \
        "$COMFY/models/loras/style_${i}.safetensors"
      i=$((i+1))
    done
  fi

  # Лоры персонажей (несколько, через запятую в CHARACTER_LORA_URLS)
  if [ -n "$CHARACTER_LORA_URLS" ]; then
    IFS=',' read -ra CHAR_URLS <<< "$CHARACTER_LORA_URLS"
    i=1
    for url in "${CHAR_URLS[@]}"; do
      download_if_missing \
        "${url}&token=${CIVITAI_TOKEN}" \
        "$COMFY/models/loras/character_${i}.safetensors"
      i=$((i+1))
    done
  fi

  # Turbo LoRA
  download_if_missing \
    "https://civitai.red/api/download/models/2560840?token=${CIVITAI_TOKEN}" \
    "$COMFY/models/loras/anima_turbo_lora.safetensors"

  # Edit LoRA
  download_if_missing \
    "https://civitai.red/api/download/models/2650553?token=${CIVITAI_TOKEN}" \
    "$COMFY/models/loras/anima_edit_lora.safetensors"

  # Body-детектор (опционально, если задана ссылка)
  if [ -n "$BODY_DETECTOR_URL" ]; then
    download_if_missing \
      "${BODY_DETECTOR_URL}&token=${CIVITAI_TOKEN}" \
      "$COMFY/models/ultralytics/bbox/body_detector.safetensors"
  fi

  # NSFW-детейлер
  download_if_missing \
    "https://civitai.red/api/download/models/1313556?token=${CIVITAI_TOKEN}" \
    "$COMFY/models/ultralytics/bbox/nsfw_detailer.safetensors"

else
  echo "[!] CIVITAI_TOKEN не задан — модели с Civitai пропущены. Добавь переменную окружения CIVITAI_TOKEN в настройках пода."
fi

echo "=== Всё готово, запускаю ComfyUI ==="
cd "$COMFY"
python main.py --listen 0.0.0.0 --port 8188
