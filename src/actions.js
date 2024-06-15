// import type {contract} from "../plutus.json"
// getPlutusData
import {getPlutusScript} from "./contract.js"
import {getValidators} from "./util.js"
import {
  toHex,
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
    validator: 'whirl.mint',
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
  const Validator_Mint2 = {type: "PlutusV2", script: Validators.Mint2.script };

  // Contract Addresses
  const Address_ContractMint1 = lucid.utils.validatorToAddress(Validator_Mint1);
  const Address_ContractMint2 = lucid.utils.validatorToAddress(Validator_Mint2);

  // Policy IDs
  const policyId_Mint1 = lucid.utils.validatorToScriptHash(Validator_Mint1)
  const policyId_Mint2 = lucid.utils.validatorToScriptHash(Validator_Mint2)
  if (VERBOSE) { console.log("INFO: Policy ID 1", policyId_Mint1) };
  if (VERBOSE) { console.log("INFO: Policy ID 2", policyId_Mint2) };
  
  // Define Sacrificial Token Information --------------------------------------
  if (VERBOSE) { console.log("INFO: Defining Sacrificial and Primary Asset") };

  // Token 1 - Sacrificial token
  const assetName_token1 = "SomeTokenName"
  const assetName_token2 = "SomeTokenName"
  const quantity_token1 = 1 
  const asset_token1 = `${policyId_Mint1}2200000000000000000000000000000000000000000000000000000000000022`
  const asset_token2 = `${policyId_Mint2}${fromText(assetName_token2)}`

  // Token Metadata
  const metaDatum = {
    name: "Some Name",
    description: "Testing this contract.",
  };

  // Configure Script Datum and Redeemer ----------------------------------------
  if (VERBOSE) { console.log("INFO: Configuring Datum"); }

  // Configure Script Datum and Redeemer ----------------------------------------
  if (VERBOSE) { console.log("INFO: Configuring Datum"); }

  //   // TO DO -- not correct
  // const txBodyPiecesStructure = Data.Object({
  //   metadata_hash: Data.Bytes(),
  //   collateral_inputs: Data.Bytes(),
  //   network_id: Data.Bytes(),
  //   collateral_outputs: Data.Bytes(),
  //   collateral_fee: Data.Bytes(),
  // })
  // const txBodyPieces = Data.to({ // TEMPORARY DATA
  //   metadata_hash: paymentCredentialOf(user_address).hash, 
  //   collateral_inputs: paymentCredentialOf(user_address).hash,
  //   network_id: paymentCredentialOf(user_address).hash,
  //   collateral_outputs: paymentCredentialOf(user_address).hash,
  //   collateral_fee: paymentCredentialOf(user_address).hash,
  //   }, txBodyPiecesStructure
  // )
  const metaDatumStructure = Data.Object({
    name: Data.Bytes(),
    description: Data.Bytes(),
  })
  const metadata = Data.to({
    name: paymentCredentialOf(user_address).hash,
    description: paymentCredentialOf(user_address).hash,
  }, metaDatumStructure
  )

  // Mint Action - Always True
  const mintRedeemer1 = Data.to(
    new Constr(0, [])
  ); 

  const outputRef = new Constr(0, [new Constr(0, ['']), 0n] )

  const collateralFee = "1A00999999"

  const collateralInput = "81825820A20E9799B49BD112364B6525E821F0AB55299E92F1726489B85466FBA157FB8F0A"

  const collateralOutput = "82583900EEECB5EE70224765A7B6A875473A50BCE2D8221085C8DCDC3E8161633E68F6B7D18FE185C852D7AD907D34D5951AB2B68F9CA5CDC8000CCF1B0000000253DC2A1A"
                  //          82583900eeecb5ee70224765a7b6a875473a50bce2d8221085c8dcdc3e8161633e68f6b7d18fe185c852d7ad907d34d5951ab2b68f9ca5cdc8000ccf1b0000000253dc2a1a
  const txBodyPieces = new Constr(0, ["00", collateralInput,collateralOutput, collateralFee])

  // Mint Action - Mint with TX INFO
  const mintRedeemer2 = Data.to(
    new Constr(0, [outputRef, txBodyPieces, ""] )
  ); 

  // const scriptDatumStructure = Data.Object({
  //   credential: Data.Bytes(),
  //   amnt: Data.Integer(),
  // })
  // const scriptDatum = Data.to({
  //   credential: paymentCredentialOf(user_address).hash, 
  //   amnt: BigInt(1)
  //   }, scriptDatumStructure
  // )


  // Build the First TX --------------------------------------------------------
  if (VERBOSE) { console.log("INFO: Building the TX"); }
  try {
    const dummy_tx = await lucid.newTx().
    collectFrom((await lucid.wallet.getUtxos()).sort((a, b) => {
      return a.txHash.localeCompare(b.txHash) || a.outputIndex - b.outputIndex;
    }))
    .mintAssets({[asset_token1]: 1n}, mintRedeemer1)
    .mintAssets({[asset_token2]: 1n}, mintRedeemer2)
    .attachMintingPolicy(Validator_Mint1)
    .attachMintingPolicy(Validator_Mint2)
    .addSigner(user_address)
    .complete();

    const collateral_inputs = toHex(dummy_tx.txComplete.body().collateral().to_bytes())
    const collateral_outputs = toHex(dummy_tx.txComplete.body().collateral_return().to_bytes())
    const collateral_fee = toHex(dummy_tx.txComplete.body().total_collateral().to_bytes())

    console.log('collateral_inputs',collateral_inputs)
    console.log('collateral_outputs',collateral_outputs)
    console.log('collateral_fee',collateral_fee)
    // console.log('BEFORE', Data.to(collateralOutput))
    // console.log('AFTER', Data.to(collateral_outputs))

    const txBodyPieces2 = new Constr(0, ["00", collateral_inputs,collateral_outputs, collateral_fee])

    // Mint Action - Mint with TX INFO
    const mintRedeemer3 = Data.to(
      new Constr(0, [outputRef, txBodyPieces2, ""] )
    ); 

    const tx = await lucid.newTx().
    collectFrom((await lucid.wallet.getUtxos()).sort((a, b) => {
      return a.txHash.localeCompare(b.txHash) || a.outputIndex - b.outputIndex;
    }))
    .mintAssets({[asset_token1]: 1n}, mintRedeemer1)
    .mintAssets({[asset_token2]: 1n}, mintRedeemer3)
    .attachMintingPolicy(Validator_Mint1)
    .attachMintingPolicy(Validator_Mint2)
    .addSigner(user_address)
    .complete();

    let txString = tx.toString()

    const scriptDataHash = tx.txComplete.body().script_data_hash().to_hex()
    console.log("SCRIPT DATA HASH", scriptDataHash)



    if (VERBOSE) { console.log("INFO: Raw TX", tx.toString()); }
    txString = txString.replaceAll('2200000000000000000000000000000000000000000000000000000000000022', scriptDataHash)

    if (VERBOSE) { console.log("INFO: TX Replaced:", txString); }

    // Define Primary Token Information ------------------------------------------
    if (VERBOSE) { console.log("INFO: Defining Sacrificial and Primary Asset") };
  
    // Token 2 - Token with scriptDataHash as the asset name
    // const assetName_token2 = tx.txComplete.body().script_data_hash().to_hex()
    // const quantity_token2 = 1 
    // const asset_token2 = `${policyId_Mint2}${(assetName_token2)}`
    
    if (VERBOSE) { console.log("INFO: scriptDataHash (to be used as assetName):", assetName_token2); }
  

    // Request User Signature ----------------------------------------------------
    console.log("INFO: Requesting TX signature");
    const signedTx = await lucid.fromTx(txString).sign().complete(); 
    if (VERBOSE) { console.log("INFO: SIGNED TX:", signedTx.toHash()); }
    if (VERBOSE) { console.log("INFO: SIGNED TX:", signedTx.toString()); }


  // Submit the TX -------------------------------------------------------------
  console.log("INFO: Attempting to submit the transaction");
  const txHash = await signedTx.submit();
  //const txHash  = 'TEMP'

  // Return with TX hash -------------------------------------------------------
  console.log(`TX Hash: ${txHash}`);
  return {
    tx_id: txHash,
    address: Address_ContractMint2,
    policy_id: policyId_Mint2,
  };

  }
  catch (e) {
    console.log(e)
  }
  


}
