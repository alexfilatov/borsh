defmodule Borsh.Encode do
  require Logger

  @moduledoc """
  This module contains functions for encoding Elixir data structures into BORSH binary format.
  ## Usage

  ```elixir
  defmodule ParentStruct do
   @type t() :: %__MODULE__{first_name: String.t(), last_name: String.t(), age: integer}

   defstruct [
     :first_name,
     :last_name,
     :age
   ]

   use Borsh,
     schema: [
       first_name: :string,
       last_name: :string,
       age: :u8
     ]
  end
  borsh_struct = %ParentStruct{first_name: "Boris", last_name: "Johnson", age: 58}
  Borsh.Encode.encode(borsh_struct)
  <<5, 0, 0, 0, 66, 111, 114, 105, 115, 7, 0, 0, 0, 74, 111, 104, 110, 115, 111, 110, 58>>
  ```
  """

  @doc """
  Encodes structs according to the schema into the bitstring
  """
  @spec borsh_encode(obj :: struct) :: bitstring()
  def borsh_encode(obj) do
    borsh_schema = obj.__struct__.borsh_schema()

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

  # encoding list of structs
  defp encode_item(value, {_key, [:borsh]}), do: encode_list(value)
  defp encode_item(value, {_key, [{:borsh, _module}]}), do: encode_list(value)
  defp encode_item(value, {_key, _}) when is_list(value), do: encode_list(value)

  # keeping this for backward compatibility, we should use {:borsh, struct} instead of :borsh
  defp encode_item(value, {key, :borsh}) do
    Logger.warn(
      "Using :borsh format is deprecated, please use `#{key}: {:borsh, #{value.__struct__}}` instead of `#{key}: :borsh`"
    )

    value.__struct__.borsh_encode(value)
  end

  # when this is a :borsh type with a struct name
  # we dont need struct name for encoding, but we'll need that for decoding
  defp encode_item(value, {_key, {:borsh, _}}) do
    value.__struct__.borsh_encode(value)
  end

  # encoding strings with fixed sizes: 32 bytes and 64 bytes, types `[32]` and `[64]` respectively:
  defp encode_item(<<_::size(256)>> = string_value, {key, [32]}) do
    encode_item(string_value, {key, :string})
  end

  defp encode_item(_value, {key, [32]}),
    do: raise("Invalid string length for `#{key}`, must be 32 bytes")

  defp encode_item(<<_::size(512)>> = string_value, {key, [64]}) do
    encode_item(string_value, {key, :string})
  end

  defp encode_item(_value, {key, [64]}),
    do: raise("Invalid string length for `#{key}`, must be 64 bytes")

  defp encode_item(value, {key, size})
       when size in [:u8, :u16, :u32, :u64, :u128] and is_binary(value) do
    value
    |> String.to_integer()
    |> encode_item({key, size})
  end

  defp encode_item(value, {_key, size})
       when size in [:u8, :u16, :u32, :u64, :u128, :i8, :i16, :i32, :i64, :i128] do
    binarify(value, size)
  end

  defp encode_item(string_value, {_key, :string}) do
    # 4 bytes of the string length
    [
      # 32-bits string length,
      string_value |> byte_size() |> binarify(:u32),
      # string itself
      string_value
    ]
  end

  defp encode_list(value) do
    [
      # 4bytes binary length of the List
      value |> length() |> binarify(:u32),
      # encode each item in the list
      Enum.map(value, fn i -> i.__struct__.borsh_encode(i) end)
    ]
  end

  defp binarify(value, size) when size in [:i8, :i16, :i32, :i64, :i128] do
    size = convert_size(size)
    <<value::little-signed-integer-size(size)>>
  end

  defp binarify(value, size) when size in [:u8, :u16, :u32, :u64, :u128] do
    size = convert_size(size)
    <<value::little-unsigned-integer-size(size)>>
  end

  def convert_size(:u8), do: 8
  def convert_size(:u16), do: 16
  def convert_size(:u32), do: 32
  def convert_size(:u64), do: 64
  def convert_size(:u128), do: 128
  def convert_size(:i8), do: 8
  def convert_size(:i16), do: 16
  def convert_size(:i32), do: 32
  def convert_size(:i64), do: 64
  def convert_size(:i128), do: 128
end
