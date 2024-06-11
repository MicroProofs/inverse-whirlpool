
import { Command, Option } from '@commander-js/extra-typings';
import { mint_token } from './actions.js';
import {
  Blockfrost, 
  Lucid, 
} from "lucid-cardano";
import fs from 'fs';

// Config: Provider Options ---------------------------------------------------
const kupoUrlOption = new Option('-k, --kupo-url <string>', 'Kupo URL')
  .env('KUPO_URL')
  .makeOptionMandatory(true);
const ogmiosUrlOption = new Option('-o, --ogmios-url <string>', 'Ogmios URL')
  .env('OGMIOS_URL')
  .makeOptionMandatory(true);
  const blockfrostUrlOption = new Option('-o, --blockfrost-url <string>', 'Blockfrost URL')
    .env('BLOCKFROST_URL')
    .makeOptionMandatory(true);
const previewOption = new Option('-p, --preview', 'Use testnet').default(false);


// App -------------------------------------------------------------------------
const app = new Command();
app.name('minter').description('Inverse Whirlpool Minter').version('0.0.1');

// App Comment: Mint -----------------------------------------------------------
// Executes the mint action

app
  .command('mint')
  .description('Mints a token with a verifiable metadata hash')
  .addOption(kupoUrlOption)
  .addOption(ogmiosUrlOption)
  .addOption(previewOption)
  .action(async ({ preview, ogmiosUrl, kupoUrl }) => {

    // Set up wallet API and provider API to broadcast the built TX
    const provider = new Kupmios(kupoUrl, ogmiosUrl);
    const lucid = await Lucid.new(provider, preview ? 'Preview' : 'Mainnet');
    lucid.selectWalletFromSeed(fs.readFileSync('seed.txt', { encoding: 'utf-8' }));

    // Try to execute the TX
    try {
      const tx_info = await mint_token(lucid)
      console.log(`TX Hash: ${tx_info.id}`);
    } catch (e) {
      console.log(e);
    }
  });

