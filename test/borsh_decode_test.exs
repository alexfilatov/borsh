defmodule Borsh.DecodeTest do
  use ExUnit.Case

  defmodule ChildStruct do
    @type t() :: %__MODULE__{
            first_name: String.t(),
            age: integer,
            hello: String.t(),
            world: integer
          }

    defstruct [
      :first_name,
      :age,
      :hello,
      :world
    ]

    use Borsh,
      schema: [
        first_name: :string,
        age: :u8,
        hello: :string,
        world: :u8
      ]
  end

  defmodule DogStruct do
    @type t() :: %__MODULE__{name: String.t()}
    defstruct [:name]
    use Borsh, schema: [name: :string]
  end

  defmodule CatStruct do
    @type t() :: %__MODULE__{name: String.t()}
    defstruct [:name]
    use Borsh, schema: [name: :string]
  end

  defmodule ParentStruct do
    @type t() :: %__MODULE__{
            first_name: String.t(),
            last_name: String.t(),
            age: integer,
            cars_amount: integer,
            jokes_said: integer,
            no_idea_whats_this_could_be: integer,
            still_not_googolplex: integer,
            var_i8: integer,
            var_i16: integer,
            var_i32: integer,
            var_i64: integer,
            var_i128: integer,
            son: ChildStruct.t(),
            daughter: ChildStruct.t(),
            children: list(ChildStruct.t()),
            pets: list(any),
            test_value: integer,
            hash_string: String.t()
          }

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
      :var_i128,
      :son,
      :daughter,
      :children,
      :pets,
      :test_value,
      :hash_string
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
        var_i128: :i128,
        son: {:borsh, ChildStruct},
        daughter: {:borsh, ChildStruct},
        # this only limitation is we cannot use arrays of different types
        children: [{:borsh, ChildStruct}],
        pets: [{:borsh, DogStruct}, {:borsh, CatStruct}],
        test_value: :u16,
        hash_string: [32]
      ]
  end

  setup do
    struct = %ParentStruct{
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
      var_i128: -1_000_000_000_000_000_000,
      son: %ChildStruct{first_name: "Alex", hello: "world", age: 12, world: 4},
      daughter: %ChildStruct{first_name: "Kate", hello: "hi", age: 10, world: 6},
      children: [
        %ChildStruct{first_name: "Alex", hello: "world", age: 12, world: 4},
        %ChildStruct{first_name: "Kate", hello: "hi", age: 10, world: 6}
      ],
      pets: [%DogStruct{name: "Rex"}, %CatStruct{name: "Molly"}],
      test_value: 45,
      hash_string: "12345678901234567890123456789012"
    }

    {:ok, struct: struct}
  end

  @tag timeout: :infinity
  describe ".borsh_decode" do
    test "success: encoded into bitstring and decoded back into the struct", %{struct: struct} do
      bitstr = ParentStruct.borsh_encode(struct)
      assert is_bitstring(bitstr)

      {decoded_struct, _should_be_zero_bits} = Borsh.Decode.borsh_decode(bitstr, ParentStruct)

      assert decoded_struct == struct
    end
  end
end
