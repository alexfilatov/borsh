defmodule Borsh.Decode do
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
          {decoded_result, rest_bits} = decode(res_map.map, res_map.bits, schema_item)

          {
            schema_item,
            %{bits: rest_bits, map: Map.put(res_map.map, schema_field_name, decoded_result)}
          }
        end
      )

    res_map.map
  end

  @doc """
  Decodes string
  """
  def decode(map, <<str_size::little-integer-size(32), rest_bits::binary>>, {field_name, :string}) do
    <<str::binary-size(str_size), rest_bits::binary>> = rest_bits

    {str, rest_bits}
  end

  @doc """
  Decodes unsigned 8-bit integer
  """
  def decode(map, <<u8::little-integer-size(8), rest_bits::binary>>, {field_name, :u8}) do
    {u8, rest_bits}
  end
end
