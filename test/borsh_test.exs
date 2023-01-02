defmodule BorshTest do
  use ExUnit.Case

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

  setup do
    struct = %ParentStruct{first_name: "Boris", last_name: "Johnson", age: 58}
    {:ok, struct: struct}
  end

  describe ".borsh_encode" do
    test "success: encoded into bitstring", %{struct: struct} do
      bitstr = ParentStruct.borsh_encode(struct)

      assert is_bitstring(bitstr)

      <<fn_len::binary-size(4), _::binary>> = bitstr
      assert fn_len == <<5, 0, 0, 0>>

      <<_::binary-size(4), first_name::binary-size(5), _::binary>> = bitstr
      assert first_name == "Boris"

      <<_::binary-size(4), _::binary-size(5), ln_len::binary-size(4), _::binary>> = bitstr
      assert ln_len == <<7, 0, 0, 0>>

      <<_::binary-size(4), _::binary-size(5), _::binary-size(4), last_name::binary-size(7),
        _::binary>> = bitstr

      assert last_name == "Johnson"

      <<_::binary-size(4), _::binary-size(5), _::binary-size(4), _::binary-size(7), age::size(8),
        _::binary>> = bitstr

      assert age == 58
    end
  end

  @tag timeout: :infinity
  describe ".borsh_decode" do
    test "success: decoded into the struct", %{struct: struct} do
      bitstr = ParentStruct.borsh_encode(struct)
      assert is_bitstring(bitstr)

      {decoded_struct, _} = ParentStruct.borsh_decode(bitstr)
      assert decoded_struct == struct
    end
  end
end
