//! hello-checkin: one instruction, `check_in`, accepted only while `now <= deadline`.
//!
//! Hello-world simplification: the deadline arrives in the instruction data (8 bytes, i64 little-endian
//! unix seconds). A real program (BeThere) stores it in an event account the attendee cannot choose.

use pinocchio::{AccountView, Address, ProgramResult, error::ProgramError};
#[cfg(target_os = "solana")]
use pinocchio::sysvars::{Sysvar, clock::Clock};

#[cfg(target_os = "solana")]
pinocchio::entrypoint!(process_instruction);

/// Custom error code returned on-chain as `custom program error: 0x1`.
pub const DEADLINE_PASSED: u32 = 1;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CheckInError {
    DeadlinePassed,
}

impl From<CheckInError> for ProgramError {
    fn from(error: CheckInError) -> Self {
        match error {
            CheckInError::DeadlinePassed => ProgramError::Custom(DEADLINE_PASSED),
        }
    }
}

/// The whole rule, pure: no clock read, no accounts.
///
/// Boundary on purpose: `now > deadline` rejects, so the deadline second itself is still open
/// (closed interval `..=deadline`), the same operator as BeThere's `mark_checked_in` (`now > event_end`).
pub fn validate_check_in(now: i64, deadline: i64) -> Result<(), CheckInError> {
    match now > deadline {
        true => Err(CheckInError::DeadlinePassed),
        false => Ok(()),
    }
}

pub fn parse_deadline(instruction_data: &[u8]) -> Result<i64, ProgramError> {
    let bytes: [u8; 8] = instruction_data
        .try_into()
        .map_err(|_| ProgramError::InvalidInstructionData)?;
    Ok(i64::from_le_bytes(bytes))
}

pub fn process_instruction(
    _program_id: &Address,
    _accounts: &mut [AccountView],
    instruction_data: &[u8],
) -> ProgramResult {
    let deadline = parse_deadline(instruction_data)?;
    let now = current_unix_timestamp()?;
    validate_check_in(now, deadline)?;
    Ok(())
}

/// Read the clock once per instruction (skill: "Read the clock once ... then pass `now` into a pure function").
#[cfg(target_os = "solana")]
fn current_unix_timestamp() -> Result<i64, ProgramError> {
    Ok(Clock::get()?.unix_timestamp)
}

#[cfg(not(target_os = "solana"))]
fn current_unix_timestamp() -> Result<i64, ProgramError> {
    Err(ProgramError::UnsupportedSysvar)
}
