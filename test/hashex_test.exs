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

  test "modify_all_struct" do
    assert HashUtils.modify_all( %Some{}, [], fn(_) -> :some_else end ) == %Some{a: :some_else, b: :some_else}
  end

  test "modify_all_map" do
    assert HashUtils.modify_all( %{a: 1, b: %{c: 2, d: 3}}, [:b], fn(el) -> el*el end ) == %{a: 1, b: %{c: 4, d: 9}}
  end

  test "modify_all_nested" do
    assert HashUtils.modify_all( %Some{a: [a: %{a: [a: 1, b: 2, c: 3]}]}, [:a, :a, :a], fn(el) -> el*el  end ) == %Some{a: [a: %{a: [a: 1, b: 4, c: 9]}]}
  end

  test "modify_all_lst" do
    assert HashUtils.modify_all( %Some{a: [a: %{a: [1,2,3]}]}, [:a, :a, :a], fn(el) -> el*el  end ) == %Some{a: [a: %{a: [1,4,9]}]}
  end

  test "delete_from_nested_map" do
    assert HashUtils.delete( %{a: [b: %{c: 1, d: 1, e: 1}]}, [:a, :b, :e] ) == %{a: [b: %{c: 1, d: 1}]}
  end

  test "delete_from_nested_keylist" do
    assert HashUtils.delete( %{a: [b: [c: 1, d: 1, e: 1]]}, [:a, :b, :e] ) == %{a: [b: [c: 1, d: 1]]}
  end

  test "simple_delete" do
    assert (HashUtils.delete( %{a: 1, b: 2}, :b ) == %{a: 1})
              and ( HashUtils.delete( [a: 1, b: 2], :b ) == [a: 1] )
  end

  test "simple_set" do
    assert (HashUtils.set( %{a: 1, b: 2}, :b , 123) == %{a: 1, b: 123} ) 
              and ( HashUtils.set( %Some{a: 1, b: %{c: [1,2,3]}}, :b, 1 ) == %Some{a: 1, b: 1} )
                and ( HashUtils.set( [a: 1, b: 2], :b , 123) == [a: 1, b: 123] )
  end

  test "simple_modify" do
    assert (HashUtils.modify( %{a: 1, b: 2}, :b , &(&1*&1)) == %{a: 1, b: 4} ) 
              and ( HashUtils.modify( %Some{a: 1, b: %{c: [1,2,3]}}, :a , &(&1+&1) ) == %Some{a: 2, b: %{c: [1,2,3]}} )
                and ( HashUtils.modify( [a: 1, b: 2], :b , &(&1*&1)) == [a: 1, b: 4] )
  end

  test "simple_modify_all" do
    assert (HashUtils.modify_all( %{a: 1, b: 2}, &(&1+&1)) == %{a: 2, b: 4} ) 
              and ( HashUtils.modify_all( %Some{a: 1, b: 2}, &(&1+&1) ) == %Some{a: 2, b: 4} )
                and ( HashUtils.modify_all( [a: 1, b: 2], &(&1*&1)) == [a: 1, b: 4] )
  end

  test "add_map" do
    assert (HashUtils.add( %Some{a: %{1 => %{"some" => 123}}}, [:a, 1, :some_else], 321 ) ==
              %Some{a: %{1 => %{"some" => 123, :some_else => 321}}})
  end

  test "add_map_simple" do
    assert HashUtils.add( %{a: 1}, :b, 2 ) == %{a: 1, b: 2}
  end

  test "support of keylists" do
    assert HashUtils.set( %Some{a: 1, b: [1,2,3]}, [b: 2, a: 2] ) == %Some{a: 2, b: 2}
  end

  test "support of keylists 2" do
    assert HashUtils.set( [a: 1, b: [1,2,3]], [b: 2, a: 2] ) == [a: 2, b: 2]
  end

  test "keys 1" do
    assert HashUtils.keys( [a: 1, b: [1,2,3]] ) == [:a, :b]
  end

  test "keys 2" do
    assert HashUtils.keys( %Some{a: %{1 => %{"some" => 123}}}, [:a, 1] ) == ["some"]
  end

  test "keys 3" do
    assert HashUtils.keys( %Some{a: %{1 => %{"some" => [a: 1, b: 2, c: %{1 => [a: 1, b: 2]}]}}}, [:a, 1, "some", :c, 1] ) == [:a, :b]
  end

  test "values 1" do
    assert HashUtils.values( [a: 1, b: [1,2,3]] ) == [1, [1,2,3]]
  end

  test "values 2" do
    assert HashUtils.values( %Some{a: %{1 => %{"some" => 123}}}, [:a, 1] ) == [123]
  end

  test "values 3" do
    assert HashUtils.values( %Some{a: %{1 => %{"some" => [a: 1, b: 2, c: %{1 => [a: 1, b: 2]}]}}}, [:a, 1, "some", :c, 1] ) == [1, 2]
  end

  test "select_changes 1" do
    assert HashUtils.select_changes( %Some{a: %{ 1 => "some", 2 => "qweqwe"}}, %Some{a: %{ 1 => "some_else", 3 => "qweqweqwe"}}, [:a] ) == %{ 1 => "some", 2 => "qweqwe"}
  end

  test "select_changes 2" do
    assert HashUtils.select_changes( %Some{a: %{ 1 => "some", 2 => "qweqwe"}}, %Some{a: %{ 1 => "some_else", 3 => "qweqweqwe"}} ) == %{a: %{ 1 => "some", 2 => "qweqwe"}}
  end

  test "select_changes 3" do
    assert HashUtils.select_changes( [a: 1, b: 4, c: 8], [a: 1, b: 2, c: 3], fn(new, old) -> new == old*old end ) == %{a: 1, b: 4}
  end

  test "select_changes 4" do
    assert HashUtils.select_changes( %Some{a: [a: 1, b: 4, c: 8]}, %Some{a: [a: 1, b: 2, c: 3]}, [:a], fn(new, old) -> new == old*old end ) == %{a: 1, b: 4}
  end

end
