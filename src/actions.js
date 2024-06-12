// import type {contract} from "../plutus.json"
// getPlutusData
import {getPlutusScript} from "./contract.js"
import {getValidators} from "./util.js"
import {
  Data,
  fromText,
  Constr,
  paymentCredentialOf
} from "lucid-cardano";

const VERBOSE = true;

const contracts = [
  { 
    alias: 'Mint',
    validator: 'true.mint',
  },
  { 
    alias: 'Mint2',
    validator: 'whirl.merkle_minter',
  },
]
const Validators = getValidators(contracts, getPlutusScript())

// #############################################################################
// ## MINT TOKEN
// #############################################################################
export const mint_token = async (lucid) => {

  const user_address = await lucid.wallet.address()
  console.log('INFO: User address:', user_address)

  // Parameterize Contracts ----------------------------------------------------
  if (VERBOSE) { console.log("INFO: Parameterizing Contracts"); }

  // Mint Validators
  const Validator_Mint1 = {type: "PlutusV2", script: Validators.Mint.script };
  const Validator_Mint2 = {type: "PlutusV2", script: Validators.Mint.script };

  // Contract Addresses
  const Address_ContractMint1 = lucid.utils.validatorToAddress(Validator_Mint1);
  const Address_ContractMint2 = lucid.utils.validatorToAddress(Validator_Mint2);

  // Policy IDs
  const policyId_Mint1 = lucid.utils.validatorToScriptHash(Validator_Mint1)
  const policyId_Mint2 = lucid.utils.validatorToScriptHash(Validator_Mint2)
  
  // Define Sacrificial Token Information --------------------------------------
  if (VERBOSE) { console.log("INFO: Defining Sacrificial and Primary Asset") };

  // Token 1 - Sacrificial token
  const assetName_token1 = "SomeTokenName"
  const quantity_token1 = 1 
  const asset_token1 = `${policyId_Mint1}${fromText(assetName_token1)}`

  // Token Metadata
  const metaDatum = {
    name: "Some Name",
    description: "Testing this contract.",
  };

  // Configure Script Datum and Redeemer ----------------------------------------
  if (VERBOSE) { console.log("INFO: Configuring Datum"); }

  // Mint Action
  const mintRedeemer1 = Data.to(
    new Constr(0, [])
  ); 
  
  // Build the First TX --------------------------------------------------------
  if (VERBOSE) { console.log("INFO: Building the TX"); }
  const tx = await lucid.newTx()
  .payToAddress(
    user_address, 
    { 
      [asset_token1]: BigInt(quantity_token1)
    },
  ) 
  .mintAssets({[asset_token1]: BigInt(quantity_token1)}, mintRedeemer1)
  .attachMintingPolicy(Validator_Mint1)
  .attachMetadata(721n, metaDatum)
  .addSigner(user_address)
  .complete();
  if (VERBOSE) { console.log("INFO: Raw TX 1", tx.toString()); }

  // Define Primary Token Information ------------------------------------------
  if (VERBOSE) { console.log("INFO: Defining Sacrificial and Primary Asset") };

  // Token 2 - Token with scriptDataHash as the asset name
  const assetName_token2 = tx.txComplete.body().script_data_hash().to_hex()
  const quantity_token2 = 1 
  const asset_token2 = `${policyId_Mint2}${(assetName_token2)}`
  
  if (VERBOSE) { console.log("INFO: scriptDataHash (to be used as assetName):", assetName_token2); }

  // Configure Script Datum and Redeemer ----------------------------------------
  if (VERBOSE) { console.log("INFO: Configuring Datum"); }

  // Mint Action

  const output_ref = paymentCredentialOf(user_address).hash  // TO DO -- not correct
  const txBodyPiecesStructure = Data.Object({
    metadata_hash: Data.Bytes(),
    collateral_inputs: Data.Bytes(),
    network_id: Data.Bytes(),
    collateral_outputs: Data.Bytes(),
    collateral_fee: Data.Bytes(),
  })
  const txBodyPieces = Data.to({ // TEMPORARY DATA
    metadata_hash: paymentCredentialOf(user_address).hash, 
    collateral_inputs: paymentCredentialOf(user_address).hash,
    network_id: paymentCredentialOf(user_address).hash,
    collateral_outputs: paymentCredentialOf(user_address).hash,
    collateral_fee: paymentCredentialOf(user_address).hash,
    }, txBodyPiecesStructure
  )
  const metaDatumStructure = Data.Object({
    name: Data.Bytes(),
    description: Data.Bytes(),
  })
  const metadata = Data.to({
    name: paymentCredentialOf(user_address).hash,
    description: paymentCredentialOf(user_address).hash,
  }, metaDatumStructure
  )

  const mintRedeemer2 = Data.to(
    new Constr(0, [new Constr(0, [(output_ref, txBodyPieces, metadata)])])
  ); 
  
  const scriptDatumStructure = Data.Object({
    credential: Data.Bytes(),
    amnt: Data.Integer(),
  })
  const scriptDatum = Data.to({
    credential: paymentCredentialOf(user_address).hash, 
    amnt: BigInt(1)
    }, scriptDatumStructure
  )

  // Build the Second TX -------------------------------------------------------
  if (VERBOSE) { console.log("INFO: Building the Secondary TX"); }
  const tx2 = await lucid.newTx()
  .payToAddressWithData(
    Address_ContractMint2, 
    {inline: scriptDatum},
    { 
      ['lovelace']: BigInt(1000000),
    },
  ) 
  .payToAddress(
    user_address, 
    { 
      [asset_token2]: BigInt(quantity_token2)
    },
  ) 
  .mintAssets({[asset_token2]: BigInt(quantity_token2)}, mintRedeemer2)
  .attachMintingPolicy(Validator_Mint2)
  .attachMetadata(721n, metaDatum)
  .addSigner(user_address)
  .complete();
  if (VERBOSE) { console.log("INFO: Raw TX 2", tx2.toString()); }

  // Request User Signature ----------------------------------------------------
  console.log("INFO: Requesting TX signature");
  const signedTx = await tx2.sign().complete();

  // Submit the TX -------------------------------------------------------------
  console.log("INFO: Attempting to submit the transaction");
  const txHash = await signedTx.submit();

  // Return with TX hash -------------------------------------------------------
  console.log(`TX Hash: ${txHash}`);
  return {
    tx_id: txHash,
    address: Address_ContractMint2,
    policy_id: policyId_Mint2,
  };
}
