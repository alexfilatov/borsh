# Borsh [![Build Status](https://github.com/alexfilatov/borsh/workflows/CI/badge.svg?branch=main)](https://github.com/alexfilatov/borsh/actions?query=workflow%3ACI) [![Hex pm](https://img.shields.io/hexpm/v/borsh.svg?style=flat)](https://hex.pm/packages/borsh) [![hex.pm downloads](https://img.shields.io/hexpm/dt/borsh.svg?style=flat)](https://hex.pm/packages/borsh)

BORSH, binary serializer for security-critical projects.

Borsh stands for "Binary Object Representation Serializer for Hashing".
It is meant to be used in security-critical projects as it prioritizes consistency, safety, speed;
and comes with a strict specification.
In short, Borsh is a non self-describing binary serialization format.
It is designed to serialize any objects to canonical and deterministic set of bytes.

General principles of Borsh serialization:

- Integers are encoded in little-endian format.
- The size of dynamic containers (such as hash maps and hash sets) is written as a 32-bit unsigned integer before the
  values.
- All unordered containers are ordered lexicographically by key, with a tie breaker of the value.
- Structs are serialized in the order of their fields.
- Enums are serialized by storing the ordinal as an 8-bit unsigned integer, followed by the data contained within the
  enum value (if present).

This is Elixir implementation of the Borsh serializer and deserializer.
Official specification: https://github.com/near/borsh#specification

A little article on Medium about Borsh serializer in more
details: https://medium.com/@alexfilatov/borsh-binary-serialiser-for-near-protocol-eed79a1638f4

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

In this example `ActionOne`, `ActionTwo` and `PublicKey` are structs that implement `Borsh` protocol.

### Options

`schema`: Borsh schema itself, structure of fields for serialisation with serialisation formats described below.

### Borsh literal formats

#### String literals

`:string` - string, encoded as utf-8 bytes

`[32]` and `[64]` - A string with 32/64 chars length.

#### Number literals

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

#### Borsh-typed literals

To define custom types for serialization, we can use the syntax `{:borsh, StructModule}` in a parent struct, when we
want to serialize another struct within it. There are single and arrays of borsh types.

`{:borsh, Module}` - The syntax represents a single struct of a borsh-encoded module. When this struct is passed to the
serializer, the serializer will execute the `.borsh_encode` method of the struct's module on the struct.

`:borsh` - has the same effect as `{:borsh, Module}`, but the resulting serialized data cannot be decoded back into the
original struct. Using `:borsh` for serialization is safe for sending transactions to the NEAR blockchain, as the main
concern is just the serialization itself.

`[{:borsh, Module}]` - represents an enumeration of borsh-encoded structs, where each element of the list must have a
Borsh schema.

`[:borsh]` - has the same effect as [{:borsh, Module}], but the resulting serialized data cannot be decoded back into
the original structs. It can only be used for encoding, not decoding.

`[{:borsh, Module1}, {:borsh, Module2}]` - represents an enumeration of borsh-encoded structs, where each element
of the list must have a Borsh schema. Each element in the list can belong to a different module, and the sequence of
elements is important. This syntax can be used for both encoding and decoding.

## License

    Copyright © 2021-present Alex Filatov <alex@alexfilatov.com>

    This work is free. You can redistribute it and/or modify it under the
    terms of the MIT License. See the LICENSE file for more details.
