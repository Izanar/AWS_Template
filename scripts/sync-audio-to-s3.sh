#!/usr/bin/env bash
# Upload application audio to the scenario-owned private bucket; never delete objects.
# Usage: sync-audio-to-s3.sh <app-checkout-or-repository-url> <bucket>
set -euo pipefail
source="${1:?Application checkout or repository URL required}"
bucket="${2:?S3 bucket name required}"
ref="${APP_SOURCE_REF:-main}"
[[ "$bucket" =~ ^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$ ]] || { echo 'Invalid bucket name' >&2; exit 1; }
[[ "$source" != -* && "$ref" != -* ]] || { echo 'Invalid source/ref' >&2; exit 1; }
command -v aws >/dev/null
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
if [[ -d "$source" ]]; then
  checkout="$source"
else
  command -v git >/dev/null
  git clone --depth 1 --no-checkout "$source" "$work_dir/app"
  git -C "$work_dir/app" fetch --depth 1 origin "$ref"
  git -C "$work_dir/app" checkout --detach FETCH_HEAD
  checkout="$work_dir/app"
fi
audio_dir="$checkout/html/audio"
[[ -d "$audio_dir" && -f "$audio_dir/rain.mp3" ]] || {
  echo 'Expected html/audio/ with rain.mp3 in the application checkout' >&2
  exit 1
}
aws s3 sync "$audio_dir/" "s3://${bucket}/audio/" --no-follow-symlinks --only-show-errors
echo "Audio uploaded to s3://${bucket}/audio/"
