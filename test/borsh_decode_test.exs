defmodule Borsh.DecodeTest do
  use ExUnit.Case

  defmodule DummyStruct do
    @type t() :: %__MODULE__{first_name: String.t(), last_name: String.t(), age: integer}

    defstruct [
      :first_name,
      :last_name,
      :age,
      :cars_amount,
      :jokes_said,
      :no_idea_whats_this_could_be,
      :still_not_googolplex,
      :var_i8,
      :var_i16,
      :var_i32,
      :var_i64,
      :var_i128
    ]

    use Borsh,
      schema: [
        first_name: :string,
        last_name: :string,
        age: :u8,
        cars_amount: :u16,
        jokes_said: :u32,
        no_idea_whats_this_could_be: :u64,
        still_not_googolplex: :u128,
        var_i8: :i8,
        var_i16: :i16,
        var_i32: :i32,
        var_i64: :i64,
        var_i128: :i128
      ]
  end

  setup do
    struct = %DummyStruct{
      first_name: "Boris",
      last_name: "Johnson",
      age: 58,
      cars_amount: 1000,
      jokes_said: 1_000_000,
      no_idea_whats_this_could_be: 1_000_000_000_000_000_000,
      still_not_googolplex: 1_000_000_000_000_000_000_000_000_000_000,
      var_i8: -10,
      var_i16: -100,
      var_i32: -1_000,
      var_i64: -1_000_000_000,
      var_i128: -1_000_000_000_000_000_000
    }

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
