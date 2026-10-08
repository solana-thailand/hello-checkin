use hello_checkin::{CheckInError, validate_check_in};

const DEADLINE: i64 = 1_760_000_000;

#[test]
fn accepts_one_second_before_deadline() {
    assert_eq!(validate_check_in(DEADLINE - 1, DEADLINE), Ok(()));
}

#[test]
fn accepts_at_the_deadline_second() {
    assert_eq!(validate_check_in(DEADLINE, DEADLINE), Ok(()));
}

#[test]
fn rejects_one_second_after_deadline() {
    assert_eq!(
        validate_check_in(DEADLINE + 1, DEADLINE),
        Err(CheckInError::DeadlinePassed)
    );
}
