use aiken/dict
use aiken/list
use aiken/transaction.{Input, OutputReference}
use aiken/transaction/value.{AssetName, PolicyId, Value}

pub fn has_unique_input(inputs: List<Input>, spent_utxo: OutputReference) {
  // Ensures the script is parameterized by a unique UTXO input being spent
  list.any(inputs, fn(input) { input.output_reference == spent_utxo })
}

pub fn valid_mint(
  mint: Value,
  token_policy: PolicyId,
  token_name: AssetName,
  quantity: Int,
) -> Bool {
  expect [Pair(mint_token_name, mint_amount)] =
    mint
      |> value.tokens(token_policy)
      |> dict.to_pairs()

  mint_amount == quantity && mint_token_name == token_name
}
