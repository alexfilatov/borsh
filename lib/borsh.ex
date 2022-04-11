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
      def is_borsh, do: true

      def borsh_schema do
        unquote(schema)
      end

      @doc """
      Encodes objects according to the schema into the bytestring
      """
      @spec borsh_encode(obj :: keyword) :: bitstring()
      def borsh_encode(obj) do
        {_, res} =
          Enum.map_reduce(borsh_schema(), [], fn schema_item, acc ->
            {schema_item, acc ++ [extract_encode_item(obj, schema_item)]}
          end)

        res |> List.flatten() |> :erlang.list_to_binary()
      end

      # Encode
      defp extract_encode_item(obj, {key, format}) do
        value = Map.get(obj, key)
        encode_item(value, {key, format})
      end

      defp encode_item(value, {key, format}) when format === [:borsh] do
        [
          # 4bytes binary length of the List
          value |> length() |> binarify(32),
          Enum.map(value, fn i ->
            i.__struct__.borsh_encode(i)
          end)
        ]
      end

      defp encode_item(value, {key, format}) when format === :borsh do
        value.__struct__.borsh_encode(value)
      end

      # TODO: add string length validation
      defp encode_item(value, {key, format}) when format in [[32], [64]], do: value

      defp encode_item(value, {key, size})
           when size in [:u8, :u16, :u32, :u64, :u128] and is_binary(value) do
        value
        |> String.to_integer()
        |> encode_item({key, size})
      end

      defp encode_item(value, {key, size}) when size in [:u8, :u16, :u32, :u64, :u128] do
        size = convert_size(size)
        binarify(value, size)
      end

      defp encode_item(string_value, {key, :string}) do
        # 4 bytes of the string length
        [string_value |> byte_size() |> binarify(32), string_value]
      end

      defp binarify(int_value, size \\ 32) do
        <<int_value::size(size)-integer-unsigned-little>>
      end

      defp convert_size(size) do
        size |> Atom.to_string() |> String.slice(1..3) |> String.to_integer()
      end
    end
  end
end
