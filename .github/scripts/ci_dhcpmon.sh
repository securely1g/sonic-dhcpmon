#!/usr/bin/env bash
# Run from the source checkout on a native Debian Trixie runner.
set -euo pipefail
out=${1:?pass an artifact directory outside the checkout}
mkdir -p "$out"
arch=$(dpkg --print-architecture)
case "$arch:$(uname -m)" in
  amd64:x86_64) platform=@sonic_build_infra//platforms:x86_64_trixie ;;
  arm64:aarch64) platform=@sonic_build_infra//platforms:aarch64_trixie ;;
  *) echo "Unsupported native host: $arch / $(uname -m)" >&2; exit 1 ;;
esac
test "$(bazel --version)" = "bazel $(cat .bazelversion)"
test ! -e MODULE.bazel.lock
git check-ignore -q MODULE.bazel.lock

# These public mirrors keep the original source and Debian package checksums.
revision=8cdb94d129914a1d74237930d255f4c75075e4d9
mirrors="$out/source_mirrors.cfg"
curl --fail --silent --show-error --retry 3 \
  "https://raw.githubusercontent.com/securely1g/sonic-bazel-registry/$revision/ci/source_mirrors.cfg" -o "$mirrors"
printf '%s  %s\n' 2e01494e18c47475b29309b9f6ac1506665b3331498996d24f69d6dfc77eacc8 "$mirrors" | sha256sum -c -

flags=(--lockfile_mode=update --host_platform="$platform" --platforms="$platform" --downloader_config="$mirrors")
artifacts=(//:runtime //:runtime.debug_symbols)
bazel build "${flags[@]}" --jobs=4 "${artifacts[@]}"
bazel test "${flags[@]}" --jobs=4 --nocache_test_results --test_output=errors //:util_behavior_test

for i in 0 1; do
  target=${artifacts[$i]}
  file=$(bazel cquery "${flags[@]}" --output=files "$target")
  test -f "$file"
  cp "$file" "$out/${target#//:}.tar"
done
python3 .github/scripts/check_dhcpmon_artifacts.py --arch "$arch" "$out/runtime.tar" "$out/runtime.debug_symbols.tar" > "$out/debug-pair.json"
cp bazel-testlogs/util_behavior_test/test.{log,xml} "$out/"
grep -Fx 'Monitor-production-utility-PASS 10 groups' "$out/test.log"
bazel aquery "${flags[@]}" 'mnemonic("CppCompile", //:dhcpmon)' --output=text > "$out/daemon-compile-actions.txt"
bazel aquery "${flags[@]}" 'mnemonic("DebAssemble", deps(set(//:runtime //:runtime.debug_symbols //:util_behavior_test)))' \
  --output=jsonproto | python3 -c 'import json, sys; sys.exit("unexpected DEB assembly action") if json.load(sys.stdin).get("actions") else None'
bazel mod graph "${flags[@]}" > "$out/module-graph.txt"
cp MODULE.bazel.lock "$out/"
git diff --exit-code HEAD --
printf 'source=%s\ncheckout=%s\nuserspace=%s\nhost_and_target=%s\n' \
  "$SOURCE_SHA" "$(git rev-parse HEAD)" "$(dpkg --print-architecture)" "$platform" > "$out/build.txt"
bazel --version >> "$out/build.txt"
(cd "$out" && sha256sum *.tar *.json *.lock *.txt *.log *.xml *.cfg > SHA256SUMS)
