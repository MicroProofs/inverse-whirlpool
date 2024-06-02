use inverse_whirlpool/types/data.{State}

pub fn state_initialization(initial_conditions: State) -> Bool {
  initial_conditions.mint == 0
}

/// Initial state of script
pub fn state_update(
  script_state: State,
  /// Current script state
  new_script_state: State,
) -> Int {
  new_script_state.mint - script_state.mint
}
/// Incoming script state
