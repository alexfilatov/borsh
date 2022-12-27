defmodule Borsh.DecodeTest do
  use ExUnit.Case

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

  setup do
    struct = %DummyStruct{first_name: "Boris", last_name: "Johnson", age: 58}
    {:ok, struct: struct}
  end

  @tag timeout: :infinity
  describe ".borsh_decode" do
    test "success: encoded into bitstring and decoded back into the struct", %{struct: struct} do
      bitstr = DummyStruct.borsh_encode(struct)
      assert is_bitstring(bitstr)

      decoded_struct = Borsh.Decode.borsh_decode(bitstr, DummyStruct)
      assert decoded_struct == struct
    end
  end
end
