import {
  Blockfrost, 
  Lucid, 
} from "lucid-cardano";

// Initialize Lucid ------------------------------------------------------------
export const lucidAPI = async (wallet) => {

  let network_id = wallet.networkId
  let network
  let key

  if (network_id == 0) {
    network = "Preview"
    key =  process.env.VUE_APP_BLOCKFROST_PREVIEW
  } else if (network_id == 1) {
    network = "Mainnet"
    key =  process.env.VUE_APP_BLOCKFROST_MAINNET
  } else {
    return
  }

  const api = await Lucid.new(
    new Blockfrost(
      "https://cardano-"+network.toLowerCase()+".blockfrost.io/api/v0", 
      key),
      network,
  );

  return api.selectWallet(wallet.API);
}

// Retrieve validators from plutus.json ----------------------------------------
export function getValidators(endpoints, contract)  {

  var Validators = {}

  endpoints.forEach(function (endpoint) {
    Validators[endpoint.alias] =  {
      type: "PlutusV2",
      script: contract.validators.find((v) => v.title === endpoint.validator).compiledCode,
    }
  });
  return Validators
}
