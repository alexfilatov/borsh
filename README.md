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
    {:borsh, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
  use Borsh,
      schema: [
        signer_id: :string,
        public_key: :borsh,
        nonce: :u64,
        receiver_id: :string,
        block_hash: [32],
        actions: [:borsh]
      ],
      enum_map: %{
        0 => EnumElement0,
        1 => EnumElement1,
        2 => EnumElement2
      }
```

#### Options

`schema`:
Borsh schema itself, structure of fields for serialisation with serialisation formats.

`enum_map`:
List of all available enum elements, with indexes in order. It's very important to keep an order of the `enum_map`
elements as Borsh will be using it for de-serialisation to understand which enum element is which. Currently limited
only to 1 enum element per structure, further Borsh versions will contain better structured schema with multiple enums,
e.g.:

```elixir
  enums1: [%{0 => Enum1Element0, 1 => Enum1Element1}],
                                      enums2: [%{0 => Enum2Element0, 1 => Enum2Element1}]
```

#### Borsh literal formats

`:string` - String representation of a value. Borsh encodes it as is, with a little-endian 32bit (4 bytes) header of a
string byte size

`:borsh` - Struct of the borsh-ed module. The serializer will take this struct and executes struct's
module `.borsh_encode`
against this struct and assign binary result to the literal.

[`:borsh`] - Enum of borsh-ed structs. There also should be an `enum_map` to decode each of the enum element

`:u64` - Unsigned integer 64-bit size. There are also `:u8`, `:u16`, `:u32` and `:u128`

`[32]` or `[64]` - A string with 32/64 chars length.

## License

    Copyright © 2021-present Alex Filatov <alex@alexfilatov.com>

    This work is free. You can redistribute it and/or modify it under the
    terms of the MIT License. See the LICENSE file for more details.
