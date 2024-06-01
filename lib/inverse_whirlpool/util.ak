use aiken/list
use aiken/transaction/value.{lovelace_of}
use aiken/transaction.{InlineDatum, Input, Output}
use aiken/transaction/credential.{ScriptCredential}
use inverse_whirlpool/types/data.{State, ContractInfo}

// Get's the User proposed state update
pub fn get_state_update(
  outputs: List<Output>,
  script_policy_id: ByteArray,
) -> ContractInfo {
  expect [Output { datum: InlineDatum(incoming_datum), value: payment .. }] =
    list.filter(
      outputs,
      fn(output) {
        output.address.payment_credential == ScriptCredential(script_policy_id)
      },
    )
  expect incoming_script_state: State = incoming_datum

  let user_input = ContractInfo {
    state: incoming_script_state,
    lovelace: lovelace_of(payment)
  }

  user_input
}

pub fn get_contract_state(
  inputs: List<Input>,
  script_policy_id: ByteArray,
) -> ContractInfo {

  expect [Input { output: Output { datum: InlineDatum(current_datum), value: contract_value, .. }, ..}] =
    list.filter(
      inputs,
      fn(inp) {
        inp.output.address.payment_credential == ScriptCredential(script_policy_id)
      },
    )
  expect script_state: State = current_datum

  let contract_info = ContractInfo {
    state: script_state,
    lovelace: lovelace_of(contract_value)
  }
  contract_info
}
