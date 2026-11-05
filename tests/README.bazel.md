# Production utility behavior test

`//:util_behavior_test` compiles the actual `src/util.cpp` and uses source Common,
canonical jsoncpp/libpcap and pinned external foundations. Assertions remain on
in optimized builds (`-UNDEBUG`). Ten groups cover checksum lengths0..65, carry
folds, IPv4/IPv6 pseudoheaders and zero encoding, parsing boundaries, address
formatting, counter keys and legacy serialization. Empty application-state globals
allow pure utility paths to run; no DB methods are mocked or called. This is not
full packet forwarding, database health or dual-ToR acceptance.

The published infrastructure native_runtime_test wrapper uses declared target
loader/library payloads, not an absolute host path or locally built image.
No ARM/cross runtime result is claimed. Historical Nov1 local image validation
and negative/restoration controls do not establish a fresh pass for the updated
published graph or declared-runtime wrapper.
