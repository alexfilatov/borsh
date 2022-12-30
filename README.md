# Borsh [![Build Status](https://github.com/alexfilatov/borsh/workflows/CI/badge.svg?branch=main)](https://github.com/alexfilatov/borsh/actions?query=workflow%3ACI) [![Hex pm](https://img.shields.io/hexpm/v/borsh.svg?style=flat)](https://hex.pm/packages/borsh) [![hex.pm downloads](https://img.shields.io/hexpm/dt/borsh.svg?style=flat)](https://hex.pm/packages/borsh)

BORSH, binary serializer for security-critical projects.

**IMPORTANT! Implemented only `Serialization`. `Deserialization` will be implemented by the end of the March.**

Borsh stands for `Binary` `Object` `Representation` `Serializer` for `Hashing`. It is meant to be used in
security-critical projects as it prioritizes consistency, safety, speed; and comes with a strict specification.

In short, Borsh is a non self-describing binary serialization format. It is designed to serialize any objects to
canonical and deterministic set of bytes.

General principles:

- integers are little endian;
- sizes of dynamic containers are written before values as u32;
- all unordered containers (hashmap/hashset) are ordered in lexicographic order by key (in tie breaker case on value);
- structs are serialized in the order of fields in the struct;
- enums are serialized with using u8 for the enum ordinal and then storing data inside the enum value (if present).

This is Elixir implementation of the serializer. Official specification: https://github.com/near/borsh#specification

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `borsh` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:borsh, "~> 0.1"}
  ]
end
```

## Usage

```elixir
  use Borsh,
      schema: [
        signer_id: :string,
        public_key: {:borsh, PublicKey},
        nonce: :u64,
        receiver_id: :string,
        block_hash: [32],
        actions: [
          {:borsh, ActionOne}, 
          {:borsh, ActionTwo}
        ]
      ]
```

#### Options

`schema`:
Borsh schema itself, structure of fields for serialisation with serialisation formats.

#### Borsh literal formats

`:string` - string, encoded as utf-8 bytes

`:u8` - unsigned 8-bit integer

`:u16` - unsigned 16-bit integer

`:u32` - unsigned 32-bit integer

`:u64` - unsigned 64-bit integer

`:i8` - signed 8-bit integer

`:i16` - signed 16-bit integer

`:i32` - signed 32-bit integer

`:i64` - signed 64-bit integer

`:f32` - 32-bit float

`:f64` - 64-bit float

`{:borsh, Module}` - Struct of the borsh-ed module. The serializer will take this struct and executes struct's  module `.borsh_encode` against this struct
`:borsh` - [deprecated] the same as `{:borsh, Module}`, but not possible to decode if used. Works only for encoding.

`[{:borsh, Module}]` - Enum of borsh-ed structs. Each element of this list of `:borsh` struct must have a Borsh schema with a field
`[:borsh]` - [deprecated] the same as `[{:borsh, Module}]` but  not possible to decode if used. Works only for encoding.

`[32]` or `[64]` - A string with 32/64 chars length.

## License

    Copyright © 2021-present Alex Filatov <alex@alexfilatov.com>

    This work is free. You can redistribute it and/or modify it under the
    terms of the MIT License. See the LICENSE file for more details.
