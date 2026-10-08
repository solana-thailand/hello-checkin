//! SVM test (Mollusk): run the built .so at deadline - 1, deadline, deadline + 1 by warping the clock.
//! Needs `cargo build-sbf` first (loads target/deploy/hello_checkin.so).

use hello_checkin::DEADLINE_PASSED;
use mollusk_svm::{Mollusk, result::Check};
use pinocchio::error::ProgramError;
use solana_instruction::Instruction;
use solana_pubkey::Pubkey;

const DEADLINE: i64 = 1_760_000_000;

fn run_at(now: i64, checks: &[Check]) {
    let program_id = Pubkey::new_unique();
    let mut mollusk = Mollusk::new(&program_id, "target/deploy/hello_checkin");
    mollusk.sysvars.clock.unix_timestamp = now;
    let instruction = Instruction::new_with_bytes(program_id, &DEADLINE.to_le_bytes(), vec![]);
    mollusk.process_and_validate_instruction(&instruction, &[], checks);
}

#[test]
fn check_in_one_second_before_deadline_succeeds() {
    run_at(DEADLINE - 1, &[Check::success()]);
}

#[test]
fn check_in_at_deadline_succeeds() {
    run_at(DEADLINE, &[Check::success()]);
}

#[test]
fn check_in_one_second_after_deadline_fails_with_deadline_passed() {
    run_at(DEADLINE + 1, &[Check::err(ProgramError::Custom(DEADLINE_PASSED))]);
}

#[test]
fn check_in_with_bad_data_fails() {
    let program_id = Pubkey::new_unique();
    let mollusk = Mollusk::new(&program_id, "target/deploy/hello_checkin");
    let instruction = Instruction::new_with_bytes(program_id, &[1, 2, 3], vec![]);
    mollusk.process_and_validate_instruction(
        &instruction,
        &[],
        &[Check::err(ProgramError::InvalidInstructionData)],
    );
}
