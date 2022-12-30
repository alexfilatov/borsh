defmodule Borsh.Encode do
  require Logger

  @moduledoc """
  This module contains functions for encoding Elixir data structures into BORSH binary format.

  ## Usage

  ```elixir
  iex> defmodule DummyStruct do
  iex>  @type t() :: %__MODULE__{first_name: String.t(), last_name: String.t(), age: integer}
  iex>
  iex>  defstruct [
  iex>    :first_name,
  iex>    :last_name,
  iex>    :age
  iex>  ]
  iex>
  iex>  use Borsh,
  iex>    schema: [
  iex>      first_name: :string,
  iex>      last_name: :string,
  iex>      age: :u8
  iex>    ]
  iex> end
  iex> borsh_struct = %DummyStruct{first_name: "Boris", last_name: "Johnson", age: 58}
  iex> Borsh.Encode.encode(borsh_struct)
  <<5, 0, 0, 0, 66, 111, 114, 105, 115, 7, 0, 0, 0, 74, 111, 104, 110, 115, 111, 110, 58>>
  ```
  """

  @doc """
  Encodes structs according to the schema into the bytestring
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
  defp encode_item(value, {_key, [{:borsh, module}]}), do: encode_list(value)
  defp encode_item(value, {_key, _}) when is_list(value), do: encode_list(value)

  defp encode_list(value) do
    [
      # 4bytes binary length of the List
      value
      |> length()
      |> binarify(:u32),
      Enum.map(
        value,
        fn i ->
          i.__struct__.borsh_encode(i)
        end
      )
    ]
  end

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

  # TODO: add string length validation
  defp encode_item(value, {_key, format}) when format in [[32], [64]], do: value

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
      string_value
      |> byte_size()
      |> binarify(:u32),
      string_value
    ]
  end

  defp binarify(value, size) when size in [:i8, :i16, :i32, :i64, :i128] do
    size = convert_size(size)
    <<value::size(size)-integer-signed-little>>
  end

  defp binarify(value, size) when size in [:u8, :u16, :u32, :u64, :u128] do
    size = convert_size(size)
    <<value::size(size)-integer-unsigned-little>>
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
