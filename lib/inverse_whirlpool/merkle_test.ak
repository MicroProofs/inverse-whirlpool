use aiken/bytearray
use aiken/fuzz.{and_then, bytearray as byte_fuzzer, map}
use aiken/hash
use aiken/list
use inverse_whirlpool/merkle.{
  Left, Right, combine_proofs, convert_bytes_to_left_proofs,
  convert_bytes_to_remainder_proofs, convert_bytes_to_right_proofs, left_proof,
  right_proof, verify_root,
}
use inverse_whirlpool/utils.{list_at}

fn get_16_bytearrays() -> Fuzzer<List<ByteArray>> {
  let a <- and_then(byte_fuzzer())
  let b <- and_then(byte_fuzzer())
  let c <- and_then(byte_fuzzer())
  let d <- and_then(byte_fuzzer())
  let e <- and_then(byte_fuzzer())
  let f <- and_then(byte_fuzzer())
  let g <- and_then(byte_fuzzer())
  let h <- and_then(byte_fuzzer())
  let i <- and_then(byte_fuzzer())
  let j <- and_then(byte_fuzzer())
  let k <- and_then(byte_fuzzer())
  let l <- and_then(byte_fuzzer())
  let m <- and_then(byte_fuzzer())
  let n <- and_then(byte_fuzzer())
  let o <- and_then(byte_fuzzer())
  let p <- map(byte_fuzzer())

  [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p]
}

// assume list is even
fn merklize_one_level(leaves: List<ByteArray>) -> List<ByteArray> {
  when leaves is {
    [] ->
      []
    [_] -> fail @"impossible"
    [a, b, ..rest] -> {
      let hash = bytearray.concat(a, b) |> hash.blake2b_256

      [hash, ..merklize_one_level(rest)]
    }
  }
}

test merkle_1(bytes_list via get_16_bytearrays()) {
  let first_item = list_at(bytes_list, 7)

  let first_proof = list_at(bytes_list, 6)

  let level_one = merklize_one_level(bytes_list)

  let level_one_hash = list_at(level_one, 2)

  let level_two = merklize_one_level(level_one)

  let level_two_hash = list_at(level_two, 0)

  let level_three = merklize_one_level(level_two)

  let level_three_hash = list_at(level_three, 1)

  expect [root] = merklize_one_level(level_three)

  let proof_list =
    [
      #[0],
      first_proof,
      #[0],
      level_one_hash,
      #[0],
      level_two_hash,
      #[1],
      level_three_hash,
    ]

  let proofs =
    list.foldr(proof_list, #"", fn(x, acc) { bytearray.concat(x, acc) })

  let remaining_proofs = proofs |> convert_bytes_to_remainder_proofs

  verify_root(remaining_proofs, first_item, root)
}

test merkle_2(bytes_list via get_16_bytearrays()) {
  let first_item = list_at(bytes_list, 9)

  let first_proof = list_at(bytes_list, 8)

  let level_one = merklize_one_level(bytes_list)

  let level_one_hash = list_at(level_one, 5)

  let level_two = merklize_one_level(level_one)

  let level_two_hash = list_at(level_two, 3)

  let level_three = merklize_one_level(level_two)

  let level_three_hash = list_at(level_three, 0)

  expect [root] = merklize_one_level(level_three)

  let proof_list =
    [
      #[0],
      first_proof,
      #[1],
      level_one_hash,
      #[1],
      level_two_hash,
      #[0],
      level_three_hash,
    ]

  let proofs =
    list.foldr(proof_list, #"", fn(x, acc) { bytearray.concat(x, acc) })

  let remaining_proofs = proofs |> convert_bytes_to_remainder_proofs

  verify_root(remaining_proofs, first_item, root)
}

test merkle_3(bytes_list via get_16_bytearrays()) {
  let new_item = list_at(bytes_list, 9) |> hash.blake2b_256

  let left_side_closest = list_at(bytes_list, 7)

  let left_side_neighbor = list_at(bytes_list, 6)

  let right_side_closest = list_at(bytes_list, 12)

  let right_side_neighbor = list_at(bytes_list, 13)

  let level_one = merklize_one_level(bytes_list)

  let level_one_left = list_at(level_one, 2)

  let level_one_right = list_at(level_one, 7)

  let level_two = merklize_one_level(level_one)

  let level_two_left = list_at(level_two, 0)

  let level_two_modified =
    list.indexed_map(
      level_two,
      fn(i, x) {
        if i == 2 {
          new_item
        } else {
          x
        }
      },
    )

  let level_three = merklize_one_level(level_two_modified)

  expect [root] = merklize_one_level(level_three)

  let left_list =
    [left_side_closest, left_side_neighbor, level_one_left, level_two_left]

  let right_list =
    [right_side_closest, right_side_neighbor, level_one_right]

  let remaining_side_proofs = ""

  let proof_list =
    []

  let left_proofs =
    list.foldr(left_list, #"", fn(x, acc) { bytearray.concat(x, acc) })

  let right_proofs =
    list.foldr(right_list, #"", fn(x, acc) { bytearray.concat(x, acc) })

  let proofs =
    list.foldr(proof_list, #"", fn(x, acc) { bytearray.concat(x, acc) })

  let left_proof_final =
    left_proofs
      |> convert_bytes_to_left_proofs
      |> left_proof

  let right_proof_final =
    right_proofs
      |> convert_bytes_to_right_proofs
      |> right_proof

  let remaining_proofs = proofs |> convert_bytes_to_remainder_proofs

  let
    _,
    combined_hash,
  <-
    combine_proofs(
      Right,
      remaining_side_proofs,
      left_proof_final,
      right_proof_final,
      new_item,
    )

  verify_root(remaining_proofs, combined_hash, root)
}

fn merkle_4_setup() {
  let bytes_list =
    [
      #"0379899ac4a85a30898d29e5041f8c6cf398d370f08b48ce258cdc376e5b8c8c",
      #"2413b790b449b5134f357e5afed5149073b21bb6808650f1da5c821bef9fb25a",
      #"56b3f804e7d380264dd9d26b8f5af2fc5624b9c7c4751c16d288a28ee9d2e401",
      #"a801bfafdc95b4f98196ada7d4d99ca22c2e3ca4f2a5b9704ad48ba0bacf6313",
      #"1f90b49b9ff263fceb6bb86286a771697f99b7b8282270876c5b6aa04c28fa18",
      #"3c4cb28da90f5a784cdbdd3c1c154cdd5a7b44b31882a5bb1ee7f3e9a14a77d8",
      #"541431258d0e7b58145337cb491cd98d425e7fd77bbd81679a28ab5689a4ac5e",
      #"dcf93f6a91df8ff87f4e17ec954a79ab3ebf330b87d9e3457b6f0eef1230abe4",
      #"1e6b2d4e73051f97dc43ca3319e07c0f49bc1e493d56814537c6125c43359c7d",
      #"9581c5e21a94884538e1212bb666df18bd353eb1c03c20bd473fa6f3fc21162c",
      #"30a6de707aa2ac2fa0d302b6a321c63291f147a3c6c2f3172fbf484ce42761d5",
      #"29847997b0d56a12b7fd2ac72618bba69cf28293a03d88c3bd0ee9ee1fee110d",
      #"77bbf46b3cc8f5620d170b201bb2a7e3a4508e53b2ae17cf1d1b9add18314cc3",
      #"83d32921e87c9a88db3ac56a1e6b8552c9732911a977927bd2e58b3add48683c",
      #"064d2e79dc1f95fbdf8ebad4f95676c10ffc1696131731badf30b38f4f60b66d",
      #"03cfeeb613c20b73496ea0402a36ba05733d7cea285676c5f540e98b5ff39930",
    ]

  let new_item = list_at(bytes_list, 9) |> hash.blake2b_256

  let left_side_closest = list_at(bytes_list, 7)

  let left_side_neighbor = list_at(bytes_list, 6)

  let right_side_closest = list_at(bytes_list, 12)

  let right_side_neighbor = list_at(bytes_list, 13)

  let level_one = merklize_one_level(bytes_list)

  let level_one_left = list_at(level_one, 2)

  let level_one_right = list_at(level_one, 7)

  let level_two = merklize_one_level(level_one)

  let level_two_left = list_at(level_two, 0)

  let level_two_modified =
    list.indexed_map(
      level_two,
      fn(i, x) {
        if i == 2 {
          new_item
        } else {
          x
        }
      },
    )

  let level_three = merklize_one_level(level_two_modified)

  expect [root] = merklize_one_level(level_three)

  let left_list =
    [left_side_closest, left_side_neighbor, level_one_left, level_two_left]

  let right_list =
    [right_side_closest, right_side_neighbor, level_one_right]

  let proof_list =
    []

  let left_proofs =
    list.foldr(left_list, #"", fn(x, acc) { bytearray.concat(x, acc) })

  let right_proofs =
    list.foldr(right_list, #"", fn(x, acc) { bytearray.concat(x, acc) })

  let proofs =
    list.foldr(proof_list, #"", fn(x, acc) { bytearray.concat(x, acc) })

  fn(g) { g(left_proofs, right_proofs, proofs, new_item, root) }
}

test merkle_4() {
  let left_proofs, right_proofs, proofs, new_item, root <- merkle_4_setup()()

  let remaining_side_proofs = ""

  let left_proof_final =
    left_proofs
      |> convert_bytes_to_left_proofs
      |> left_proof

  let right_proof_final =
    right_proofs
      |> convert_bytes_to_right_proofs
      |> right_proof

  let remaining_proofs = proofs |> convert_bytes_to_remainder_proofs

  let
    _,
    combined_hash,
  <-
    combine_proofs(
      Right,
      remaining_side_proofs,
      left_proof_final,
      right_proof_final,
      new_item,
    )

  verify_root(remaining_proofs, combined_hash, root)?
}

fn merkle_5_setup() {
  let bytes_list =
    [
      #"037989aac4a85a30898d29e5041f8c6cf398d370f08b48ce258cdc376e5b8c8c",
      #"2413b790b449b5134f357e5afed5149073b21bb6808650f1da5c821bef9fb25a",
      #"56b3f804e7d380264dd9d26b8f5af2fc5624b9c7c4751c16d288a28ee9d2e401",
      #"a801bfafdc95b4f98196ada7d4d99ca22c2e3ca4f2a5b9704ad48ba0bacf6313",
      #"1f90b49b9ff263fceb6bb86286a771697f99b7b8282270876c5b6aa04c28fa18",
      #"3c4cb28da90f5a784cdbdd3c1c154cdd5a7b44b31882a5bb1ee7f3e9a14a77d8",
      #"541431258d0e7b58145337cb491cd98d425e7fd77bbd81679a28ab5689a4ac5e",
      #"dcf93f6a91df8ff87f4e17ec954a79ab3ebf330b87d9e3457b6f0eef1230abe4",
      #"1e6b2d4e73051f97dc43ca3319e07c0f49bc1e493d56814537c6125c43359c7d",
      #"9581c5e21a94884538e1212bb666df18bd353eb1c03c20bd473fa6f3fc21162c",
      #"30a6de707aa2ac2fa0d302b6a321c63291f147a3c6c2f3172fbf484ce42761d5",
      #"29847997b0d56a12b7fd2ac72618bba69cf28293a03d88c3bd0ee9ee1fee110d",
      #"77bbf46b3cc8f5620d170b201bb2a7e3a4508e53b2ae17cf1d1b9add18314cc3",
      #"83d32921e87c9a88db3ac56a1e6b8552c9732911a977927bd2e58b3add48683c",
      #"064d2e79dc1f95fbdf8ebad4f95676c10ffc1696131731badf30b38f4f60b66d",
      #"04cfeeb613c20b73496ea0402a36ba05733d7cea285676c5f540e98b5ff39930",
      #"0379899ac4a85a30898d29e5041f8c6cf398d370f08b48ce258cdc376e5b8c8c",
      #"2413b790b449b5134f357e5afed5149073b21bb6808650f1da5c821bef9fb25a",
      #"56b3f804e7d380264dd9d26b8f5af2fc5624b9c7c4751c16d288a28ee9d2e401",
      #"a801bfafdc95b4f98196ada7d4d99ca22c2e3ca4f2a5b9704ad48ba0bacf6313",
      #"1f90b49b9ff263fceb6bb86286a771697f99b7b8282270876c5b6aa04c28fa18",
      #"3c4cb28da90f5a784cdbdd3c1c154cdd5a7b44b31882a5bb1ee7f3e9a14a77d8",
      #"541431258d0e7b58145337cb491cd98d425e7fd77bbd81679a28ab5689a4ac5e",
      #"dcf93f6a91df8ff87f4e17ec954a79ab3ebf330b87d9e3457b6f0eef1230abe4",
      #"1e6b2d4e73051f97dc43ca3319e07c0f49bc1e493d56814537c6125c43359c7d",
      #"9581c5e21a94884538e1212bb666df18bd353eb1c03c20bd473fa6f3fc21162c",
      #"30a6de707aa2ac2fa0d302b6a321c63291f147a3c6c2f3172fbf484ce42761d5",
      #"29847997b0d56a12b7fd2ac72618bba69cf28293a03d88c3bd0ee9ee1fee110d",
      #"77bbf46b3cc8f5620d170b201bb2a7e3a4508e53b2ae17cf1d1b9add18314cc3",
      #"83d32921e87c9a88db3ac56a1e6b8552c9732911a977927bd2e58b3add48683c",
      #"064d2e79dc1f95fbdf8ebad4f95676c10ffc1696131731badf30b38f4f60b66d",
      #"05cfeeb613c20b73496ea0402a36ba05733d7cea285676c5f540e98b5ff39930",
    ]

  let new_item = list_at(bytes_list, 15) |> hash.blake2b_256

  let left_side_closest = list_at(bytes_list, 11)

  let left_side_neighbor = list_at(bytes_list, 10)

  let right_side_closest = list_at(bytes_list, 16)

  let right_side_neighbor = list_at(bytes_list, 17)

  let level_one = merklize_one_level(bytes_list)

  let level_one_left = list_at(level_one, 4)

  let level_one_right = list_at(level_one, 9)

  let level_two = merklize_one_level(level_one)

  let level_two_right = list_at(level_two, 5)

  let level_two_modified =
    list.indexed_map(
      level_two,
      fn(i, x) {
        if i == 3 {
          new_item
        } else {
          x
        }
      },
    )

  let level_three = merklize_one_level(level_two_modified)

  let level_three_right = list_at(level_three, 3)

  let remaining_left_side_proofs = list_at(level_three, 0)

  let level_four = merklize_one_level(level_three)

  expect [root] = merklize_one_level(level_four)

  let left_list =
    [left_side_closest, left_side_neighbor, level_one_left]

  let right_list =
    [
      right_side_closest,
      right_side_neighbor,
      level_one_right,
      level_two_right,
      level_three_right,
    ]

  let proof_list =
    []

  let left_proofs =
    list.foldr(left_list, #"", fn(x, acc) { bytearray.concat(x, acc) })

  let right_proofs =
    list.foldr(right_list, #"", fn(x, acc) { bytearray.concat(x, acc) })

  let proofs =
    list.foldr(proof_list, #"", fn(x, acc) { bytearray.concat(x, acc) })

  fn(g) {
    g(
      left_proofs,
      right_proofs,
      remaining_left_side_proofs,
      proofs,
      new_item,
      root,
    )
  }
}

test merkle_5() {
  let
    left_proofs,
    right_proofs,
    remaining_left_side_proofs,
    proofs,
    new_item,
    root,
  <- merkle_5_setup()()

  let left_proof_final =
    left_proofs
      |> convert_bytes_to_left_proofs
      |> left_proof

  let right_proof_final =
    right_proofs
      |> convert_bytes_to_right_proofs
      |> right_proof

  let remaining_proofs = proofs |> convert_bytes_to_remainder_proofs

  let
    _,
    combined_hash,
  <-
    combine_proofs(
      Left,
      remaining_left_side_proofs,
      left_proof_final,
      right_proof_final,
      new_item,
    )

  verify_root(remaining_proofs, combined_hash, root)
}
