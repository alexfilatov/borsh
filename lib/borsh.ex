defmodule Borsh do
  @moduledoc """
  BORSH, binary serializer for security-critical projects.

  Borsh stands for "Binary Object Representation Serializer for Hashing".
  It is meant to be used in security-critical projects as it prioritizes consistency, safety, speed;
  and comes with a strict specification.
  In short, Borsh is a non self-describing binary serialization format.
  It is designed to serialize any objects to canonical and deterministic set of bytes.

  General principles of Borsh serialization:

  - Integers are encoded in little-endian format.
  - The size of dynamic containers (such as hash maps and hash sets) is written as a 32-bit unsigned integer before the values.
  - All unordered containers are ordered lexicographically by key, with a tie breaker of the value.
  - Structs are serialized in the order of their fields.
  - Enums are serialized by storing the ordinal as an 8-bit unsigned integer, followed by the data contained within the enum value (if present).

  This is Elixir implementation of the Borsh serializer and deserializer.
  Official specification: https://github.com/near/borsh#specification

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
        ]
    ```

  ### Options

  `schema`:
    Borsh schema itself, structure of fields for serialisation with serialisation formats.

  ### Borsh literal formats

  `:string` - the type represents the string representation of a value. When using the Borsh serialization format, it is encoded as-is, with a 4-byte little-endian header indicating the number of bytes in the string.

  `:borsh` - Struct of the borsh-ed module. The serializer will take this struct and executes struct's module `.borsh_encode` against this struct and assign binary result to the literal.

  `[:borsh]` - Enum of borsh-ed structs. Each element of this list of `:borsh` struct must have a Borsh schema

  `:u64` - Unsigned integer 64-bit size. There are also `:u8`, `:u16`, `:u32` and `:u128`

  `[32]` or `[64]` - A string with 32/64 chars length.

  """

  defmacro __using__(opts) do
    schema = opts[:schema]

    quote do
      @doc """
       The `borsh_schema` function returns the value of the `schema` variable,
       which is expected to be a data structure that describes the
       layout of the struct's data when serialized.
      """
      def borsh_schema do
        unquote(schema)
      end

      @doc """
      The borsh_encode function takes a single argument, `obj`, which should be a struct.
      It calls the borsh_encode function from the `Borsh.Encode` module and passes `obj` as an argument.
      It returns the result of this function call, which is expected to be a bitstring representing the _serialized_ data.
      """
      @spec borsh_encode(obj :: struct) :: bitstring()
      def borsh_encode(obj) do
        Borsh.Encode.borsh_encode(obj)
      end

      @doc """
      The `borsh_decode` function takes a single argument, `bs`, which should be a bitstring.
      It calls the `borsh_decode` function from the `Borsh.Decode` module and passes `bs` and the
      current module's name as arguments.
      It returns the result of this function call, which is expected to be a struct containing the _deserialized_ data.
      """
      @spec borsh_decode(bs :: bitstring()) :: struct()
      def borsh_decode(bs) do
        Borsh.Decode.borsh_decode(bs, __MODULE__)
      end
    end
  end
end
