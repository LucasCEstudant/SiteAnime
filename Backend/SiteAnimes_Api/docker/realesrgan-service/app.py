import os
import uuid
import asyncio
import subprocess
import logging
from pathlib import Path
from io import BytesIO

from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import StreamingResponse
from PIL import Image

app = FastAPI(title="Real-ESRGAN Upscale Service", version="1.0.0")
logger = logging.getLogger("realesrgan-service")

ESRGAN_BIN = os.getenv("ESRGAN_BIN", "/app/realesrgan/realesrgan-ncnn-vulkan")
ESRGAN_MODELS = os.getenv("ESRGAN_MODELS", "/app/realesrgan/models")
TIMEOUT_SECONDS = int(os.getenv("ESRGAN_TIMEOUT", "420"))
UPSCALE_MODE = os.getenv("UPSCALE_MODE", "auto")  # auto | gpu | cpu
TMP_DIR = Path("/tmp/esrgan")
TMP_DIR.mkdir(parents=True, exist_ok=True)

# Resolved at startup
_active_backend: str = "initializing"


def _test_gpu_binary() -> bool:
    """Run the ncnn-vulkan binary on a small test image and verify the output is valid."""
    test_in = TMP_DIR / "_gpu_test_in.png"
    test_out = TMP_DIR / "_gpu_test_out.png"
    try:
        img = Image.new("RGB", (8, 8), color=(100, 150, 200))
        img.save(str(test_in), "PNG")

        cmd = [
            ESRGAN_BIN,
            "-i", str(test_in),
            "-o", str(test_out),
            "-n", "realesrgan-x4plus-anime",
            "-s", "4",
            "-m", ESRGAN_MODELS,
        ]
        result = subprocess.run(cmd, capture_output=True, timeout=30)

        if result.returncode != 0:
            stderr = result.stderr.decode(errors="replace")
            logger.warning("GPU test: binary exited %d - %s", result.returncode, stderr[:300])
            return False

        if not test_out.exists():
            logger.warning("GPU test: output file not created")
            return False

        out_img = Image.open(str(test_out)).convert("RGB")
        if all(p == (0, 0, 0) for p in out_img.getdata()):
            logger.warning("GPU test: output is entirely black (driver/Vulkan issue)")
            return False

        logger.info("GPU test passed: valid %dx%d output", out_img.width, out_img.height)
        return True

    except subprocess.TimeoutExpired:
        logger.warning("GPU test: timed out after 30s")
        return False
    except Exception as exc:
        logger.warning("GPU test: error - %s", exc)
        return False
    finally:
        for p in (test_in, test_out):
            try:
                p.unlink(missing_ok=True)
            except Exception:
                pass


@app.on_event("startup")
async def _detect_backend():
    global _active_backend

    if UPSCALE_MODE == "gpu":
        _active_backend = "gpu"
        logger.info("Backend forced to GPU via UPSCALE_MODE env")
        return

    if UPSCALE_MODE == "cpu":
        _active_backend = "cpu"
        logger.info("Backend forced to CPU via UPSCALE_MODE env")
        return

    # auto-detect
    logger.info("Auto-detecting upscale backend...")
    if _test_gpu_binary():
        _active_backend = "gpu"
        logger.info("Active backend: GPU (Real-ESRGAN ncnn-vulkan)")
    else:
        _active_backend = "cpu"
        logger.info("Active backend: CPU (Pillow Lanczos)")


@app.get("/health")
async def health():
    return {"status": "ok", "backend": _active_backend}


@app.post("/upscale")
async def upscale(
    file: UploadFile = File(...),
    scale: int = Form(4),
):
    if scale not in (2, 3, 4):
        raise HTTPException(status_code=400, detail="scale must be 2, 3 or 4")

    content_type = file.content_type or ""
    if not content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="file must be an image")

    job_id = uuid.uuid4().hex[:12]
    data = await file.read()
    logger.info("Upscale request job=%s backend=%s scale=%d size=%d",
                job_id, _active_backend, scale, len(data))

    if _active_backend == "gpu":
        result_bytes = await asyncio.to_thread(_upscale_gpu, data, scale, job_id)
    else:
        result_bytes = await asyncio.to_thread(_upscale_cpu, data, scale, job_id)

    logger.info("Upscale complete job=%s output_size=%d", job_id, len(result_bytes))

    return StreamingResponse(
        BytesIO(result_bytes),
        media_type="image/png",
        headers={"Content-Disposition": f"inline; filename=upscaled_{job_id}.png"},
    )


def _upscale_gpu(data: bytes, scale: int, job_id: str) -> bytes:
    """Upscale using Real-ESRGAN ncnn-vulkan binary (GPU)."""
    input_path = TMP_DIR / f"{job_id}_in.png"
    output_path = TMP_DIR / f"{job_id}_out.png"
    try:
        input_path.write_bytes(data)
        cmd = [
            ESRGAN_BIN,
            "-i", str(input_path),
            "-o", str(output_path),
            "-n", "realesrgan-x4plus-anime",
            "-s", str(scale),
            "-m", ESRGAN_MODELS,
        ]
        result = subprocess.run(cmd, capture_output=True, timeout=TIMEOUT_SECONDS)

        if result.returncode != 0:
            stderr = result.stderr.decode(errors="replace")
            logger.error("Real-ESRGAN failed job=%s exit=%d stderr=%s",
                         job_id, result.returncode, stderr)
            raise HTTPException(status_code=500,
                                detail=f"Real-ESRGAN failed: {stderr[:500]}")

        if not output_path.exists():
            raise HTTPException(status_code=500, detail="Output file not generated")

        return output_path.read_bytes()

    except subprocess.TimeoutExpired:
        logger.error("Real-ESRGAN timeout job=%s", job_id)
        raise HTTPException(status_code=504,
                            detail=f"Processing timed out after {TIMEOUT_SECONDS}s")
    finally:
        for p in (input_path, output_path):
            try:
                p.unlink(missing_ok=True)
            except Exception:
                pass


def _upscale_cpu(data: bytes, scale: int, job_id: str) -> bytes:
    """Upscale using Pillow Lanczos resampling (CPU fallback)."""
    img = Image.open(BytesIO(data)).convert("RGB")
    new_size = (img.width * scale, img.height * scale)
    upscaled = img.resize(new_size, Image.LANCZOS)

    buf = BytesIO()
    upscaled.save(buf, format="PNG")
    logger.info("CPU upscale job=%s %dx%d -> %dx%d",
                job_id, img.width, img.height, new_size[0], new_size[1])
    return buf.getvalue()