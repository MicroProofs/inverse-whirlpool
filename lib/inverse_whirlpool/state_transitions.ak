
use inverse_whirlpool/types/data.{State}

pub fn state_initialization(
  initial_conditions: State,    /// Initial state of script
) -> Bool {
  initial_conditions.mint == 0
}

pub fn state_update(
  script_state: State,          /// Current script state
  new_script_state: State,      /// Incoming script state
) -> Int {
  new_script_state.mint - script_state.mint
}
