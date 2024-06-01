use aiken/transaction.{
 Mint, OutputReference, ScriptContext, Transaction,
}
use inverse_whirlpool/types/data.{ContractInfo}
use inverse_whirlpool/types/actions.{InitialToken, MintActions, VendingToken, MintToken,  BurnToken}
use inverse_whirlpool/checks.{
  has_unique_input, valid_mint, 
}
use inverse_whirlpool/state_transitions.{
  state_initialization, state_update
}
use inverse_whirlpool/util.{
  get_state_update, get_contract_state
}
use aiken/transaction/value

/// --- Asset Metadata Validation Smart Contract -------------------------------
validator(
  spent_utxo: OutputReference,
) {
  // --- Mint Validation Logic  ------------------------------------------------
  fn mint(mint_validation: MintActions, context: ScriptContext) -> Bool {
    // Get information about the transaction
    let ScriptContext { transaction, purpose } = context
    let Transaction {
      inputs,
      outputs,
      extra_signatories,
      mint,
      ..
    } = transaction

    // Expect single signer
    expect [_] = extra_signatories

    // Expect that the tx is minting
    expect Mint(script_policy_id) = purpose

    // Deconstruct the transaction into its base components:
    // Inputs, Outputs, Inline Datum, and a list of Minted Tokens
    let mint = value.from_minted_value(mint)

    trace @"Mint Preamble Complete"

    // Get the incoming script state
    let ContractInfo {state: incoming_script_state,  lovelace: _} = get_state_update(outputs, script_policy_id)
    
    when mint_validation is {

      /// Initial Token
      InitialToken { action } -> {
       when action is {
          MintToken -> {
            trace @"Mint Action: Mint Initial Token"
            {
              let isUniqueContract = has_unique_input(inputs, spent_utxo)
              let isValidInitialConditions = state_initialization(incoming_script_state)
              let initiatingTokenBeingMinted =
                valid_mint(
                  mint,
                  script_policy_id,
                  "SomeEnforcedTokenName_Initiating",
                  1,
                )

              and {
                isUniqueContract,
                isValidInitialConditions,
                initiatingTokenBeingMinted
              }
            }
          }
          BurnToken -> {
            trace @"Mint Action: Burn Initial Token"
            {
              False
            }
          }
        }
      }

      /// Vending Token
      VendingToken { action } -> {

        // Get the current script state - Note: no script state exists before Minting an initiating token
        let ContractInfo {state: script_state,  lovelace: _} = get_contract_state(inputs, script_policy_id)

        when action is {

          MintToken -> {
            trace @"Mint Action: Mint Vending Token"

            let num_mint = state_update(script_state, incoming_script_state)
            let vendingTokenBeingMinted =
              valid_mint(
                mint,
                script_policy_id,
                "SomeEnforcedTokenName_Vending",
                num_mint,
              )
            and {
              num_mint > 0,
              vendingTokenBeingMinted
            }
          }
          
          BurnToken -> {
            trace @"Mint Action: Burn Vending Token"

            let num_mint = state_update(script_state, incoming_script_state)
            let vendingTokenBeingMinted =
              valid_mint(
                mint,
                script_policy_id,
                "SomeEnforcedTokenName_Vending",
                num_mint,
              )
            and {
              num_mint < 0,
              vendingTokenBeingMinted
            }
          }
        }
      }
    }
  }
}
