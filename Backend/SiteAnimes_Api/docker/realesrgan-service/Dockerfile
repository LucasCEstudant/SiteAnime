FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        wget unzip libvulkan1 libglib2.0-0 libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Use a locally-downloaded Real-ESRGAN ZIP (place file in this directory)
ARG ESRGAN_ZIP=realesrgan-ncnn-vulkan-v0.2.0-ubuntu.zip
COPY ${ESRGAN_ZIP} /tmp/realesrgan.zip
RUN mkdir -p /app/realesrgan \
    && unzip /tmp/realesrgan.zip -d /tmp/esrgan-extract \
    && \
    BINPATH=$(find /tmp/esrgan-extract -type f -name 'realesrgan-ncnn-vulkan' -print -quit) \
    && if [ -z "$BINPATH" ]; then echo "Could not find realesrgan-ncnn-vulkan in archive" >&2; exit 1; fi \
    && chmod +x "$BINPATH" \
    && mv "$BINPATH" /app/realesrgan/realesrgan-ncnn-vulkan \
    && rm -rf /tmp/esrgan-extract /tmp/realesrgan.zip

# Download model files (not included in the v0.2.0 binary-only zip)
ARG MODELS_ZIP_URL=https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesrgan-ncnn-vulkan-20220424-ubuntu.zip
RUN wget -q -O /tmp/models.zip "$MODELS_ZIP_URL" \
    && unzip -o /tmp/models.zip 'models/*' -d /app/realesrgan \
    && rm /tmp/models.zip \
    && echo "Models installed:" && ls /app/realesrgan/models/

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

ENV ESRGAN_BIN=/app/realesrgan/realesrgan-ncnn-vulkan
ENV ESRGAN_MODELS=/app/realesrgan/models
ENV ESRGAN_TIMEOUT=120
ENV UPSCALE_MODE=auto

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]