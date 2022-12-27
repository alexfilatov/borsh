defmodule Borsh.Encode do
  @moduledoc """
  This module contains functions for encoding Elixir data structures into BORSH binary format.

  ## Usage

  ```elixir
  iex> borsh_struct = %DummyStruct{first_name: "Boris", last_name: "Johnson", age: 58}
  iex> Borsh.Encode.encode(borsh_struct, [a: :string, b: :string, c: :u32])
  <<5, 0, 0, 0, 66, 111, 114, 105, 115, 7, 0, 0, 0, 74, 111, 104, 110, 115, 111, 110, 58>>
  ```
  """

  @doc """
  Encodes structs according to the schema into the bytestring
  """
  @spec borsh_encode(obj :: struct, borsh_schema :: keyword) :: bitstring()
  def borsh_encode(obj, borsh_schema) do

    {_, res} =
      Enum.map_reduce(
        borsh_schema,
        [],
        fn schema_item, acc ->
          {schema_item, acc ++ [extract_encode_item(obj, schema_item)]}
        end
      )

    res
    |> List.flatten()
    |> :erlang.list_to_binary()
  end

  # Encode
  defp extract_encode_item(obj, {key, format}) do
    value = Map.get(obj, key)
    encode_item(value, {key, format})
  end

  defp encode_item(value, {key, format}) when format === [:borsh] do
    [
      # 4bytes binary length of the List
      value
      |> length()
      |> binarify(32),
      Enum.map(
        value,
        fn i ->
          i.__struct__.borsh_encode(i)
        end
      )
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
    [
      string_value
      |> byte_size()
      |> binarify(32),
      string_value
    ]
  end

  defp binarify(int_value, size \\ 32) do
    <<int_value :: size(size) - integer - unsigned - little>>
  end

  defp convert_size(size) do
    size
    |> Atom.to_string()
    |> String.slice(1..3)
    |> String.to_integer()
  end
end
