use aiken/list
use aiken/transaction.{
  InlineDatum, Input, Output, OutputReference, TransactionId, ValidityRange,
}
use aiken/transaction/credential.{from_verification_key}
use aiken/transaction/value.{flatten, from_asset}
use aiken/interval.{Finite, Interval, IntervalBound}
use inverse_whirlpool/types/data.{State, VKeyHash, Asset}

pub fn sample_token(quantity: Int, name: ByteArray) -> Asset {
  Asset {
    policy: #"0042389112371c0c19fb4ff4972bddb9a42c819cb9e81b631532942c",
    asset_name: name,
    quantity,
  }
}

pub fn sample_owner(indx: Int) -> VKeyHash {
  when indx is {
    1 -> #"41f7e02988a2592fa888ff172e913825da2e358114d595acd993ae63"
    2 -> #"ce7071e0bd6f255f733a86ea35185c1bfaacdd4477e053481a368e7a"
    3 -> #"0743d16cfe3c4fcc0c11c2403bbc10dbc7e1324a3f10638fefc3653d"
    _n -> fail
  }
}

pub fn sample_datum(number: Int) -> State {
  State {
    mint: number,
  }
}

pub fn sample_output(owner_indx: Int, asset: Asset) -> Output {
  let addr = from_verification_key(sample_owner(owner_indx))
  let val = from_asset(asset.policy, asset.asset_name, asset.quantity)

  let datum = InlineDatum(sample_datum(0))

  Output { address: addr, value: val, datum, reference_script: None }
}

pub fn sample_output_ref(tx_hash: ByteArray) -> OutputReference {
  OutputReference {
    transaction_id: TransactionId { hash: tx_hash },
    output_index: 0,
  }
}

pub fn sample_inputs(tx_hash: ByteArray) {
  Input {
    output_reference: OutputReference {
      transaction_id: TransactionId { hash: tx_hash },
      output_index: 0,
    },
    output: sample_output(1, sample_token(1, "SomeTokenName")),
  }
}

pub fn sample_token_claims(
  output: List<Output>,
) -> List<(ByteArray, ByteArray, Int)> {
  output
    |> list.flat_map(fn(output) { flatten(output.value) })
}

pub fn sample_date_range(a: Int, b: Int) -> ValidityRange {
  Interval
    { 
      lower_bound: IntervalBound { bound_type: Finite(a), is_inclusive: True },
      upper_bound: IntervalBound { bound_type: Finite(b), is_inclusive: True }
    }
}
