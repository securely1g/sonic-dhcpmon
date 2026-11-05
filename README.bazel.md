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
dual-ToR, live forwarding, ARM, installed-image startup and service deployment
are not established by this unit test. Fresh publication validation is pending;
historical Nov1 integration evidence applies to its frozen graph only.
