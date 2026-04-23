docker run --rm \
  -v /etc/ssl/certs:/etc/ssl/certs:ro \
  --network=host \
  -e http_proxy=http://127.0.0.1:1087 \
  -e https_proxy=http://127.0.0.1:1087 \
  -e no_proxy=localhost,127.0.0.1 \
  -it ubuntu:24.04 \
  bash -lc '
    set -e
    sed -i "s|URIs: http://|URIs: https://|g" /etc/apt/sources.list.d/ubuntu.sources
    time apt-get update
  '

