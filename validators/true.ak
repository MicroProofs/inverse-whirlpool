use aiken/transaction.{
  ScriptContext
}

validator {
  fn mint(action: _, context: ScriptContext) -> Bool {
    let ScriptContext { _, purpose } = context

    // Expect that the tx is minting
    expect Mint(_) = purpose

    // Always true
    True
  }
}
