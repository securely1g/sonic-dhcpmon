# DHCP monitor source-owned Bazel targets

Use Bazel 8.5.1 and the canonical securely1g registry from `.bazelrc`.
The default platform is native AMD64/Trixie. The source daemon preserves all ten
production translation units; runtime/debug TARs and Debian-recipe-derived
installed-package metadata are owned here. Package metadata is not DEB production.

```
bazel cquery 'set(//:dhcpmon //:runtime //:runtime.debug_symbols //:util_behavior_test)' --output=files
bazel aquery 'deps(//:util_behavior_test)' --output=jsonproto
bazel test --jobs=2 --local_resources=memory=4096 --nocache_test_results //:util_behavior_test
bazel build --jobs=2 --local_resources=memory=4096 //:runtime //:runtime.debug_symbols
```

Inspect the configured graph before execution. See `tests/README.bazel.md` for
bounded production-utility assertions and their limits. Full monitor health,
dual-ToR, live forwarding, installed-image startup and service deployment
are not established by this unit test.

The **Bazel DHCP monitor** PR checks run on native AMD64 and ARM64 Debian Trixie
runners. Each job sets both the host and target Bazel platform to match the
runner (`x86_64_trixie` or `aarch64_trixie`), builds the runtime and detached
debug TARs, verifies the architecture and matching symbols for `/usr/sbin/dhcpmon`,
and runs `//:util_behavior_test`. The `dhcpmon-amd64` and `dhcpmon-arm64` CI
artifacts contain the respective TARs, checksums, build ID, test results,
and generated module lock and graph. The separate `//:monitor_metadata` target
currently describes AMD64 packages only; neither job uses it to build the daemon.
