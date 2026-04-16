script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

DOCKER_BUILDKIT=1 docker build --network=host \
  --build-arg HTTP_PROXY=http://127.0.0.1:1087 \
  --build-arg HTTPS_PROXY=http://127.0.0.1:1087 \
  --build-arg NO_PROXY="192.168.0.0/16, 10.0.0.0/8, localhost, 127.0.0.10" \
  -t local-run-harbor-base -f "$script_dir/Dockerfile" "$script_dir"
