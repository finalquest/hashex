defmodule HashexTest do
  use ExUnit.Case

  defmodule Some do
  	@derive [HashUtils]
  	defstruct a: 1, b: %{c: [1,2,3]}
  end

  test "struct_get" do
    assert HashUtils.get( %Some{}, [:b, :c] ) == [1,2,3]
  end

  test "struct_set" do
    assert HashUtils.modify( %Some{}, [:b, :c] , fn(_) ->  321 end ) == %Some{a: 1, b: %{c: 321}}
  end

   test "struct_modify" do
    assert HashUtils.modify( %Some{}, [:b, :c] , fn(res) -> Enum.map(res, &(&1*&1)) end ) == %Some{a: 1, b: %{c: [1,4,9]}}
  end

  @keylist [a: 1, b: %{a: [b: 1], b: 2}]

  test "keylist_get" do
  	assert HashUtils.get( @keylist, [:b, :a, :b] ) == 1
  end

  test "nested_get" do
  	assert HashUtils.get( %Some{b: %{c: [a: %{b: [c: 1]}]}}, [:b, :c, :a, :b, :c] ) == 1
  end

  test "nested_set" do
  	assert HashUtils.set( %Some{b: %{c: [a: %{b: [c: 1]}]}}, [:b, :c, :a, :b, :c], 321) == %Some{b: %{c: [a: %{b: [c: 321]}]}}
  end

   test "nested_modify" do
  	assert HashUtils.modify( %Some{b: %{c: [a: %{b: [c: [1,2,3]]}]}}, [:b, :c, :a, :b, :c], fn(res) -> Enum.map(res, &(&1*&1)) end ) == %Some{b: %{c: [a: %{b: [c: [1,4,9]]}]}}
  end

end
