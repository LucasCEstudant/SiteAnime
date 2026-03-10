FROM libretranslate/libretranslate:latest

# This Dockerfile extends the official LibreTranslate image and attempts to pre-download
# language models to avoid long first-run downloads at container startup.
# It installs Argos Translate models for en, pt, es, zh if available.

USER root

# Install pip and argos translate if not present
RUN apt-get update \
    && apt-get install -y python3-pip curl --no-install-recommends \
    && pip3 install --no-cache-dir argostranslate==1.1.1

# Download specific Argos Translate packages (en<->pt, en<->es, en<->zh)
# Note: package names and availability may change; this attempts to fetch common packages.
RUN set -eux; \
    mkdir -p /tmp/argos; \
    cd /tmp/argos; \
    python3 - <<'PY'
from argostranslate import package
import urllib.request
packages = [
    'translate-en_pt-1_0.argosmodel',
    'translate-en_es-1_0.argosmodel',
    'translate-en_zh-1_0.argosmodel',
]
for p in packages:
    try:
        print('Attempting to download', p)
        url = f'https://www.argosopentech.com/argospm/packages/{p}'
        urllib.request.urlretrieve(url, p)
        package.install_from_path(p)
    except Exception as e:
        print('Failed to install', p, e)
PY

# Clean up apt caches
RUN apt-get remove -y python3-pip curl \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/argos

USER 1000

# Expose same port
EXPOSE 5000

CMD ["/entrypoint.sh"]
