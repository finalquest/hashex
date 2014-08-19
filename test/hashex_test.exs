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

  test "modify_each_struct" do
    assert HashUtils.modify_each( %Some{}, [], fn(_) -> :some_else end ) == %Some{a: :some_else, b: :some_else}
  end

  test "modify_each_map" do
    assert HashUtils.modify_each( %{a: 1, b: %{c: 2, d: 3}}, [:b], fn(el) -> el*el end ) == %{a: 1, b: %{c: 4, d: 9}}
  end

  test "modify_each_nested" do
    assert HashUtils.modify_each( %Some{a: [a: %{a: [a: 1, b: 2, c: 3]}]}, [:a, :a, :a], fn(el) -> el*el  end ) == %Some{a: [a: %{a: [a: 1, b: 4, c: 9]}]}
  end

  test "modify_each_lst" do
    assert HashUtils.modify_each( %Some{a: [a: %{a: [1,2,3]}]}, [:a, :a, :a], fn(el) -> el*el  end ) == %Some{a: [a: %{a: [1,4,9]}]}
  end

end
