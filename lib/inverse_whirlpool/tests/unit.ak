use aiken/transaction/value.{from_asset}
use inverse_whirlpool/checks.{has_unique_input, valid_mint}
use inverse_whirlpool/tests/data.{sample_inputs,
  sample_output_ref, sample_token}

test valid_utxo_input_param() {
  // Make sure the input is unique
  let utxo_input = #"41f7e02988a2592fa888ff172e913825da2e358114d595acd532942c"
  let utxo_param = utxo_input
  // Script parameter
  let inputs =
    [sample_inputs(utxo_input)]
  let spent_utxo = sample_output_ref(utxo_param)
  has_unique_input(inputs, spent_utxo)
}

test invalid_utxo_input_param() {
  // Make sure the input is unique
  let utxo_input = #"41f7e02988a2592fa888ff172e913825da2e358114d595acd532942c"
  let utxo_param = #"ce7071e0bd6f255f733a86ea35185c1bfaa1324a3f10638fefc3653d"
  // Script parameter
  let inputs =
    [sample_inputs(utxo_input)]
  let spent_utxo = sample_output_ref(utxo_param)
  !has_unique_input(inputs, spent_utxo)
}

test valid_mint_1() {
  let some_enforced_token_name = "UnitTestToken"
  let some_quantity = 1
  let some_token = sample_token(some_quantity, some_enforced_token_name)
  let some_mint =
    from_asset(some_token.policy, some_token.asset_name, some_token.quantity)
  valid_mint(
    some_mint,
    some_token.policy,
    some_enforced_token_name,
    some_quantity,
  )
}

test invalid_mint_1() {
  let some_enforced_token_name = "UnitTestToken"
  let some_quantity = 1
  let some_token = sample_token(some_quantity, some_enforced_token_name)
  let some_mint =
    from_asset(some_token.policy, some_token.asset_name, some_token.quantity)
  !valid_mint(some_mint, some_token.policy, some_enforced_token_name, 2)
}

/// Incorrect quantity
test invalid_mint_2() {
  let some_enforced_token_name = "UnitTestToken"
  let some_quantity = 1
  let some_token = sample_token(some_quantity, some_enforced_token_name)
  let some_mint =
    from_asset(some_token.policy, some_token.asset_name, some_token.quantity)
  !valid_mint(some_mint, some_token.policy, "BadTokenName", some_quantity)
}

/// Incorrect asset name
test invalid_mint_3() fail {
  let some_enforced_token_name = "UnitTestToken"
  let some_quantity = 1
  let some_token = sample_token(some_quantity, some_enforced_token_name)
  let some_mint =
    from_asset(some_token.policy, some_token.asset_name, some_token.quantity)
  !valid_mint(some_mint, #"000000", some_enforced_token_name, some_quantity)
}
/// Incorrect policy id
