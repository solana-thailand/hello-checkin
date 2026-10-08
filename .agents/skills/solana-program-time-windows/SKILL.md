---
name: solana-program-time-windows
description: Design, prove and test the time windows of a Solana program (deadlines, event end, refund cut-offs) so that no instruction can run on the wrong side of a boundary.
depends-on: quasar-lang, anchor-lang, pinocchio
---

# Time windows in a Solana program

Learned on BeThere's deposit escrow (Quasar, `quasar-lang`; Solana Developer Thailand). The pattern does not
depend on the framework: it applies the same way in Anchor or Pinocchio.

## Put every window in one pure function

Read the clock once per instruction (`Clock::get()?.unix_timestamp`), then pass `now` into a pure function
that returns `Result<(), ValidationError>`. No account access inside it. That function is what you test and
prove; the instruction only calls it.

BeThere's windows, as an example of a complete set:

| Instruction | Rejects when | Error |
|---|---|---|
| `create_event` | `event_end <= now` | event must end in the future |
| `create_event` | `refund_deadline <= event_end` | refunds must close after the event |
| `mark_checked_in` | `now > event_end` | `EventEnded` |
| `refund` | `now < event_end` | `RefundNotYetAllowed` |
| `refund` (not checked in) | `now >= refund_deadline` | `RefundDeadlinePassed` |

Write the boundary operator on purpose (`>` vs `>=`) and say in a comment which side of the instant is open.

## Reading the clock in Pinocchio 0.11 (checked 8 Oct 2026, mollusk-svm 0.16)

Gate the entrypoint and the clock read on `target_os = "solana"`, so the pure function's tests build on the host:

```rust
#[cfg(target_os = "solana")]
pinocchio::entrypoint!(process_instruction);

#[cfg(target_os = "solana")]
fn current_unix_timestamp() -> Result<i64, ProgramError> {
    use pinocchio::sysvars::{clock::Clock, Sysvar};
    Ok(Clock::get()?.unix_timestamp)
}
```

The crate needs `crate-type = ["cdylib", "lib"]` (`cargo new --lib`, not a binary), and an SVM test (Mollusk)
loads the `.so`, so run `cargo build-sbf` before `cargo test`.

## Prove it, then test both sides

- Prove the pure function with Kani: one harness per row above, using `kani::assume` to pin `now` on the
  rejecting side, and one that the valid case is accepted (`event_end = now + 1`,
  `refund_deadline = event_end + 1`).
- Test the instruction in an SVM test (LiteSVM, Mollusk or the framework's own) at `boundary - 1`,
  `boundary` and `boundary + 1`, warping the clock, and assert the exact error code, not only "it failed".
- Kani does not run in most CI by default: say in the README which proofs ran and when.

## For devnet runs

A full deposit → check-in → refund run needs `event_end` a few minutes after `create_event`: check in before
it, then wait past it to refund. A run that cannot wait is a replay, not a run.
