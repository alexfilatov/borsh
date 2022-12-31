defmodule Borsh.Decode do
  require Logger

  @moduledoc """
  This module contains functions for decoding BORSH binary format into Elixir data structures.

  ## Usage

  ```elixir
  defmodule DummyStruct do
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

  bitstr = <<5, 0, 0, 0, 66, 111, 114, 105, 115, 7, 0, 0, 0, 74, 111, 104, 110, 115, 111, 110, 58>>

  Borsh.Decode.borsh_decode(bitstr, DummyStruct)
  %DummyStruct{first_name: "Boris", last_name: "Johnson", age: 58}
  ```
  """

  @doc """
  Decodes objects according to the schema into the the struct
  """
  @spec borsh_decode(bs :: bitstring(), borsh_module :: keyword) :: struct()
  def borsh_decode(bs, borsh_module) do
    borsh_schema = borsh_module.borsh_schema()

    {_, res_map} =
      Enum.map_reduce(
        borsh_schema,
        %{bits: bs, map: struct(borsh_module)},
        fn {schema_field_name, schema_field_type} = schema_item, res_map ->
          {decoded_result, rest_bits} = decode(res_map.bits, schema_field_type)

          {
            schema_item,
            %{bits: rest_bits, map: Map.put(res_map.map, schema_field_name, decoded_result)}
          }
        end
      )

    {res_map.map, res_map.bits}
  end

  # string
  defp decode(<<str_size::little-integer-size(32), rest_bits::binary>>, :string) do
    <<str::binary-size(str_size), rest_bits::binary>> = rest_bits

    {str, rest_bits}
  end

  # unsigned 8-bit integer
  defp decode(<<u8::little-integer-size(8), rest_bits::binary>>, :u8) do
    {u8, rest_bits}
  end

  # unsigned 16-bit integer
  defp decode(<<u16::little-integer-size(16), rest_bits::binary>>, :u16) do
    {u16, rest_bits}
  end

  # unsigned 32-bit integer
  defp decode(<<u32::little-integer-size(32), rest_bits::binary>>, :u32) do
    {u32, rest_bits}
  end

  # unsigned 64-bit integer
  defp decode(<<u64::little-integer-size(64), rest_bits::binary>>, :u64) do
    {u64, rest_bits}
  end

  # unsigned 128-bit integer
  defp decode(<<u128::little-integer-size(128), rest_bits::binary>>, :u128) do
    {u128, rest_bits}
  end

  # signed 8-bit integer
  defp decode(<<i8::little-integer-signed-size(8), rest_bits::binary>>, :i8) do
    {i8, rest_bits}
  end

  # signed 16-bit integer
  defp decode(<<i16::little-integer-signed-size(16), rest_bits::binary>>, :i16) do
    {i16, rest_bits}
  end

  # signed 32-bit integer
  defp decode(<<i32::little-integer-signed-size(32), rest_bits::binary>>, :i32) do
    {i32, rest_bits}
  end

  # signed 64-bit integer
  defp decode(<<i64::little-integer-signed-size(64), rest_bits::binary>>, :i64) do
    {i64, rest_bits}
  end

  # signed 128-bit integer
  defp decode(<<i128::little-integer-signed-size(128), rest_bits::binary>>, :i128) do
    {i128, rest_bits}
  end

  # borsh struct
  defp decode(bits, :borsh) do
    Logger.error("Cannot decode borsh_struct: #{inspect(bits, pretty: true, limit: 30000)}")

    raise "Cannot decode borsh_struct: #{inspect(bits, pretty: true, limit: 30000)}"
  end

  # borsh struct
  defp decode(bits, {:borsh, module}) do
    module.borsh_decode(bits)
  end

  # list of borsh structs of the same type
  defp decode(<<len::little-integer-signed-size(32), bits::binary>>, [{:borsh, module}]) do
    {structs, rest_bits} =
      Enum.reduce(1..len, {[], bits}, fn _, {structs, rest} ->
        {struct, rest_bits} = decode(rest, {:borsh, module})
        {[struct | structs], rest_bits}
      end)

    {Enum.reverse(structs), rest_bits}
  end

  # list of borsh structs of any type
  defp decode(bits, l, acc \\ [])
  defp decode(bits, [], acc), do: {Enum.reverse(acc), bits}

  defp decode(<<len::little-integer-signed-size(32), bits::binary>>, [{:borsh, module} | t], []) do
    {struct, rest_bits} = decode(bits, {:borsh, module})
    decode(rest_bits, t, [struct])
  end

  defp decode(bits, [{:borsh, module} | t], acc) do
    {struct, rest_bits} = decode(bits, {:borsh, module})
    decode(rest_bits, t, [struct | acc])
  end
end
