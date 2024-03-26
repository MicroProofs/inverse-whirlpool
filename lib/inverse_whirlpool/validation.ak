use aiken/bytearray
use aiken/dict
use aiken/hash
use aiken/list
use aiken/transaction.{InlineDatum, Output, OutputReference, Transaction}
use aiken/transaction/credential.{Address, Credential}
use aiken/transaction/value.{PolicyId, Value}
use inverse_whirlpool/consts.{merkle_lower_bound, merkle_upper_bound}
use inverse_whirlpool/merkle.{Side}

pub type MintActions {
  InitMerkle
  CreateAccount {
    account: Credential,
    starting_side: Side,
    other_side_location: Int,
    left_side: ByteArray,
    right_side: ByteArray,
    remaining_proofs: ByteArray,
    output_index: Int,
  }
  BurnAccount
}

pub type ValidateActions {
  SpendMerkleRoot
  IncrementAccount(Int)
  DestroyAccount
}

pub type RootHash =
  ByteArray

pub type State {
  Merkle { root: RootHash, own_hash: PolicyId }
  Account(Credential, Int)
}

pub fn init_merkle(
  init_ref: OutputReference,
  tx: Transaction,
  own_policy: PolicyId,
  expected_address: Address,
  expected_value: Value,
) -> Bool {
  expect Some(_) =
    tx.inputs |> list.find(fn(i) { i.output_reference == init_ref })

  let expected_data =
    merkle_lower_bound
      |> bytearray.concat(merkle_upper_bound)
      |> hash.blake2b_256
      |> Merkle(own_policy)
      |> InlineDatum

  expect [first_output, ..] = tx.outputs

  // Control mint value
  expect [(_, 1)] =
    tx.mint
      |> value.from_minted_value
      |> value.tokens(own_policy)
      |> dict.to_list

  let Output {
    address: actual_address,
    value: actual_value,
    datum: actual_data,
    ..
  } = first_output

  and {
    actual_address == expected_address,
    value.without_lovelace(actual_value) == expected_value,
    actual_data == expected_data,
  }
}
