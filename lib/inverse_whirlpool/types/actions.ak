// --- Contract Actionable Interface -------------------------------------------

// Mint validator to issue/burn collateral token
pub type MintActions {
  InitialToken {
    action: MintActionType
  }
  VendingToken {
    action: MintActionType
  }
}
pub type MintActionType {
  MintToken
  BurnToken
}

// Spend validator to update the datum or retrieve ada or asset from address
pub type SpendActions {
  Admin {
    action: AdminActionTypes
  }
  Minter {
    action: MintActionType
  }
}
pub type AdminActionTypes {
  UpdateDatum
}
