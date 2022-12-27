defmodule Borsh do
  @moduledoc """
  BORSH, binary serializer for security-critical projects.

  Borsh stands for `Binary` `Object` `Representation` `Serializer` for `Hashing`.
  It is meant to be used in security-critical projects as it prioritizes consistency, safety, speed;
  and comes with a strict specification.

  In short, Borsh is a non self-describing binary serialization format.
  It is designed to serialize any objects to canonical and deterministic set of bytes.

  General principles:
  - integers are little endian;
  - sizes of dynamic containers are written before values as u32;
  - all unordered containers (hashmap/hashset) are ordered in lexicographic order by key (in tie breaker case on value);
  - structs are serialized in the order of fields in the struct;
  - enums are serialized with using u8 for the enum ordinal and then storing data inside the enum value (if present).

  This is Elixir implementation of the serializer.
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

  `:string` - String representation of a value. Borsh encodes it as is, with a little-endian 32bit (4 bytes) header of a string byte size

  `:borsh` - Struct of the borsh-ed module. The serializer will take this struct and executes struct's module `.borsh_encode`
      against this struct and assign binary result to the literal.

  `[:borsh]` - Enum of borsh-ed structs. Each element of this list of `:borsh` struct must have a Borsh schema

  `:u64` - Unsigned integer 64-bit size. There are also `:u8`, `:u16`, `:u32` and `:u128`

  `[32]` or `[64]` - A string with 32/64 chars length.

  """

  defmacro __using__(opts) do
    schema = opts[:schema]

    quote do
      def borsh_schema do
        unquote(schema)
      end

      @doc """
      Encodes objects according to the schema into the bytestring
      """
      @spec borsh_encode(obj :: struct) :: bitstring()
      def borsh_encode(obj) do
        Borsh.Encode.borsh_encode(obj)
      end

      @doc """
      Decodes objects according to the schema into the the struct
      """
      @spec borsh_decode(bs :: bitstring()) :: struct()
      def borsh_decode(bs) do
        Borsh.Decode.borsh_decode(bs, __MODULE__)
      end
    end
  end
end
