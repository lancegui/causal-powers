# Result registry implementation

1. Make analysis-state-management the sole owner of an outcome-scoped result
   registry schema and its promotion/archive lifecycle.
2. Add one R helper that saves a completed regression result and updates the
   registry in the same transaction-like call: validate output first, retain
   source code content or a resolvable Git revision, then promote only a
   successful requested replacement.
3. Point regression execution and causal-result guidance briefly to that helper;
   keep the always-on card synchronized and within its word budget.
4. Test creation, scoped replacement, simultaneous families/outcomes,
   identical rerun deduplication, experimental results, failed/partial writes,
   missing outputs, and historical recovery.

Initial scope is R regression workflows. Direct writes that bypass the helper
cannot be made registry-safe.
