defmodule HashexTest do
  use ExUnit.Case

  defmodule Some do
  	# legacy
    @derive [HashUtils]
  	defstruct a: 1, b: %{c: [1,2,3]}
  end
  defmodule SomeElse do
    defstruct a: 1, b: %{c: [1,2,3]}
  end
  defmodule Nested do
    defstruct a: 1,
              b: %SomeElse{a: 
                [
                  d: 2, 
                  e: %{
                        f: %Some{a: 3}
                     }
                ]
              }
  end
  use Hashex, [SomeElse, Nested]
  defp somekv, do: [a: 1, b: %{c: [1,2,3]}]

  #################
  ### new tests ###
  #################

  @not_hashes [ 1, 1.11, [:qwe,1,2], "foo", [{"hello",1},{:world,2}] ]

  test "get" do
    assert HashUtils.get( %Some{}, [:b, :c] ) == [1,2,3]
    assert HashUtils.get( %Some{}, :a ) == 1
    assert HashUtils.get( %Some{}, "shits" ) == nil
    assert HashUtils.get( %SomeElse{}, [:b, :c] ) == [1,2,3]
    assert HashUtils.get( %SomeElse{}, :a ) == 1
    assert HashUtils.get( %SomeElse{}, "shits" ) == nil
    assert HashUtils.get( somekv, [:b, :c] ) == [1,2,3]
    assert HashUtils.get( somekv, :a ) == 1
    assert HashUtils.get( somekv, :shits ) == nil
    assert HashUtils.get( %Nested{}, [:b, :a, :e, :f, :a] ) == 3
    assert HashUtils.get( %Nested{}, [:b, :a, :e, :shits, :a] ) == nil
    assert Enum.all?(@not_hashes, fn(h) -> 1 == (try do HashUtils.get(h, :qwe); catch _ -> 1; rescue _ -> 1 end) end)
  end

  test "set" do
    assert HashUtils.set( %Some{b: %{c: [a: %{b: [c: 1]}]}}, [:b, :c, :a, :b, :c], 321) == %Some{b: %{c: [a: %{b: [c: 321]}]}}
    assert Enum.all?(@not_hashes ++ [%Some{}, %SomeElse{}, %Nested{}, %{a: 1}], fn(h) -> 1 == (try do HashUtils.set(h, :qwe, 1); catch _ -> 1; rescue _ -> 1 end) end)
    assert Enum.all?(@not_hashes ++ [%Some{}, %SomeElse{}, %Nested{}, %{a: 1}], fn(h) -> 1 == (try do HashUtils.set(h, [:a, :b], 1); catch _ -> 1; rescue _ -> 1 end) end)
    assert HashUtils.set( %Some{}, [a: 666, b: 666]) == %Some{a: 666, b: 666}
    assert HashUtils.set( %Some{}, %{a: 666, b: 666}) == %Some{a: 666, b: 666}
    assert HashUtils.set( [c: 1, a: 0, b: 0], [a: 666, b: 666]) |> Enum.sort == [a: 666, b: 666, c: 1] |> Enum.sort
    assert HashUtils.set( %{c: 1, a: 0, b: 0}, %{a: 666, b: 666}) == %{a: 666, b: 666, c: 1}
  end

  test "add" do
      assert (HashUtils.add( %Some{a: %{1 => %{"some" => 123}}}, [:a, 1, :some_else], 321 ) == %Some{a: %{1 => %{"some" => 123, :some_else => 321}}})
      assert Enum.all?(@not_hashes ++ [%Some{}, %SomeElse{}, %Nested{}], fn(h) -> 1 == (try do HashUtils.add(h, :qwe, 1); catch _ -> 1; rescue _ -> 1 end) end)
      assert [%Some{}, %SomeElse{}, %Nested{}] == [%Some{}, %SomeElse{}, %Nested{}] |> Enum.map(&(HashUtils.add(&1, :a, 1)))
  end

  test "delete" do
    assert HashUtils.delete( %{a: [b: %{c: 1, d: 1, e: 1}]}, [:a, :b, :e] ) == %{a: [b: %{c: 1, d: 1}]}
    assert HashUtils.delete( %{a: [b: [c: 1, d: 1, e: 1]]}, [:a, :b, :e] ) == %{a: [b: [c: 1, d: 1]]}
    assert (HashUtils.delete( %{a: 1, b: 2}, :b ) == %{a: 1}) and ( HashUtils.delete( [a: 1, b: 2], :b ) == [a: 1] )
    assert Enum.all?(@not_hashes ++ [%Some{}, %SomeElse{}, %Nested{}], fn(h) -> 1 == (try do HashUtils.delete(h, :a); catch _ -> 1; rescue _ -> 1 end) end)
  end

  test "modify" do
    assert HashUtils.modify( %Some{}, [:b, :c] , fn(_) ->  321 end ) == %Some{a: 1, b: %{c: 321}}
    assert HashUtils.modify( %Some{}, [:b, :c] , fn(res) -> Enum.map(res, &(&1*&1)) end ) == %Some{a: 1, b: %{c: [1,4,9]}}
    assert HashUtils.modify( %Some{b: %{c: [a: %{b: [c: [1,2,3]]}]}}, [:b, :c, :a, :b, :c], fn(res) -> Enum.map(res, &(&1*&1)) end ) == %Some{b: %{c: [a: %{b: [c: [1,4,9]]}]}}
    assert Enum.all?(@not_hashes ++ [%Some{}, %SomeElse{}, %Nested{}, %{a: 1}], fn(h) -> 1 == (try do HashUtils.modify(h, :qwe, &(inspect(&1)) ); catch _ -> 1; rescue _ -> 1 end) end)
  end

  test "modify_all" do
    assert HashUtils.modify_all( %Some{}, [], fn(_) -> :some_else end ) == %Some{a: :some_else, b: :some_else}
    assert HashUtils.modify_all( %{a: 1, b: %{c: 2, d: 3}}, [:b], fn(el) -> el*el end ) == %{a: 1, b: %{c: 4, d: 9}}
    assert HashUtils.modify_all( %Some{a: [a: %{a: [a: 1, b: 2, c: 3]}]}, [:a, :a, :a], fn(el) -> el*el  end ) == %Some{a: [a: %{a: [a: 1, b: 4, c: 9]}]}
    assert HashUtils.modify_all( %Some{a: [a: %{a: [1,2,3]}]}, [:a, :a, :a], fn(el) -> el*el  end ) == %Some{a: [a: %{a: [1,4,9]}]}
    assert HashUtils.modify_all( %{a: 1, b: 2}, &(&1+&1)) == %{a: 2, b: 4} 
    assert HashUtils.modify_all( %Some{a: 1, b: 2}, &(&1+&1) ) == %Some{a: 2, b: 4}
    assert HashUtils.modify_all( [a: 1, b: 2], &(&1*&1)) == [a: 1, b: 4]
    assert @not_hashes |> Enum.filter(&(not is_list(&1))) |> Enum.all?(fn(h) -> 1 == (try do HashUtils.modify_all(h, &(inspect(&1)) ); catch _ -> 1; rescue _ -> 1 end) end)
  end

  test "keys" do
    assert HashUtils.keys( [a: 1, b: [1,2,3]] ) == [:a, :b]
    assert HashUtils.keys( %Some{a: %{1 => %{"some" => 123}}}, [:a, 1] ) == ["some"]
    assert HashUtils.keys( %Some{a: %{1 => %{"some" => [a: 1, b: 2, c: %{1 => [a: 1, b: 2]}]}}}, [:a, 1, "some", :c, 1] ) == [:a, :b]
    assert HashUtils.keys( somekv ) == [:a, :b]
  end

  test "values" do
    assert HashUtils.values( [a: 1, b: [1,2,3]] ) == [1, [1,2,3]]
    assert HashUtils.values( %Some{a: 1, b: 2} ) == [1,2]
    assert HashUtils.values( %SomeElse{a: 1, b: 3} ) == [1,3]
    assert HashUtils.values( %Some{a: %{1 => %{"some" => 123}}}, [:a, 1] ) == [123]
    assert HashUtils.values( %Some{a: %{1 => %{"some" => [a: 1, b: 2, c: %{1 => [a: 1, b: 2]}]}}}, [:a, 1, "some", :c, 1] ) == [1, 2]
    assert Enum.all?(@not_hashes, fn(h) -> 1 == (try do HashUtils.values(h); catch _ -> 1; rescue _ -> 1 end) end)
  end

  ####################
  ### legacy tests ###
  ####################

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
    assert HashUtils.values( %Some{a: 1, b: 2} ) == [1,2]
    assert HashUtils.values( %SomeElse{a: 1, b: 3} ) == [1,3]
  end

  test "values 2" do
    assert HashUtils.values( %Some{a: %{1 => %{"some" => 123}}}, [:a, 1] ) == [123]
  end

  test "values 3" do
    assert HashUtils.values( %Some{a: %{1 => %{"some" => [a: 1, b: 2, c: %{1 => [a: 1, b: 2]}]}}}, [:a, 1, "some", :c, 1] ) == [1, 2]
  end

  test "select_changes_kv 1" do
    assert HashUtils.select_changes_kv( %Some{a: %{ 1 => "some", 2 => "qweqwe"}}, %Some{a: %{ 1 => "some_else", 3 => "qweqweqwe"}}, [:a] ) == %{ 1 => "some", 2 => "qweqwe"}
  end

  test "select_changes_kv 2" do
    assert HashUtils.select_changes_kv( %Some{a: %{ 1 => "some", 2 => "qweqwe"}}, %Some{a: %{ 1 => "some_else", 3 => "qweqweqwe"}} ) == %{a: %{ 1 => "some", 2 => "qweqwe"}}
  end

  test "select_changes_kv 3" do
    assert HashUtils.select_changes_kv( [a: 1, b: 4, c: 8], [a: 1, b: 2, c: 3], fn(new, old) -> new == old*old end ) == %{a: 1, b: 4}
  end

  test "select_changes_kv 4" do
    assert HashUtils.select_changes_kv( %Some{a: [a: 1, b: 4, c: 8]}, %Some{a: [a: 1, b: 2, c: 3]}, [:a], fn(new, old) -> new == old*old end ) == %{a: 1, b: 4}
  end

  test "delete 1" do
    assert HashUtils.delete( %Some{a: [a: 1, b: 4, c: 8]}, :a, [:a,:b] ) == %Some{a: [c: 8]}
  end
  test "delete 2" do
    assert HashUtils.delete( [a: %{a: 1, b: 4, c: 8}], :a, [:a,:b] ) == [a: %{c: 8}]
  end

  test "nil" do
    assert HashUtils.get( %Some{a: %{1 => [2,3,4]}}, [:b, 2] ) == nil
  end

  test "nil2" do
    assert HashUtils.get( %{}, [:b, 2] ) == nil
  end

  test "select_changes_k 1" do
    assert HashUtils.select_changes_k( %Some{a: [a: 1, b: 5, c: 8]}, %Some{a: [b: 2, c: 3]}, [:a] ) == %{a: 1}
  end

  test "select_changes_k 2" do
    assert HashUtils.select_changes_k( %Some{a: %{a: 1, b: 5, c: 8}}, %Some{a: %{b: 2, c: 3}}, [:a] ) == %{a: 1}
  end

  test "add to list" do
    assert HashUtils.add_to_list(%Some{a: [a: 1, b: 5, c: [1,2,3]]}, [:a, :c], 0) == %Some{a: [a: 1, b: 5, c: [0,1,2,3]]}
  end

  test "plain_update 0" do
    assert HashUtils.plain_update( [a: 1, b: 2], %{a: 2, b: 3, c: 4} ) == [c: 4, b: 3, a: 2]
  end

  test "plain_update 1" do
    assert HashUtils.plain_update( %Some{a: [a: 1, b: 5, c: [1,2,3]]}, [:a], %{a: 2, b: 4, c: 5, d: [1,2,3]} ) == %Some{a: [ d: [1,2,3], c: 5,b: 4,a: 2]}
  end

  test "plain_update 2" do
    assert HashUtils.plain_update( %{a: %{b: %{a: 1, b: 2}}}, [:a, :b], %{a: 0, b: 1, c: 3} ) == %{a: %{b: %{a: 0, b: 1, c: 3}}}
  end

  test "filter_k 1" do
    assert HashUtils.filter_k( %{:a => 13, 2 => 2, "123123" => 3}, fn(key) -> is_integer(key) end ) == %{2 => 2}
  end

  test "filter_k 2" do
    assert HashUtils.filter_k( %Some{a: [a: %{:a => 13, 2 => 2, "123123" => 3}]}, [:a, :a], fn(key) -> is_integer(key) end ) == %Some{a: [a: %{2 => 2}]}
  end

  test "filter_k 3" do
    assert HashUtils.filter_k( %Some{a: [a: 123, b: 321]}, :a, fn(key) -> key == :a end ) == %Some{a: [a: 123]}
  end

  test "filter_v 1" do
    assert HashUtils.filter_v( %{:a => :qwe, 2 => 2, "123123" => 3}, fn(val) -> is_integer(val) end ) == %{2 => 2, "123123" => 3}
  end

  test "filter_v 2" do
    assert HashUtils.filter_v( %Some{a: [a: %{:a => :qwe, 2 => 2, "123123" => 3}]}, [:a, :a], fn(val) -> is_integer(val) end ) == %Some{a: [a:  %{2 => 2, "123123" => 3}]}
  end

  test "filter_v 3" do
    assert HashUtils.filter_v( %Some{a: [a: 123, b: 321]}, :a, fn(val) -> val == 321 end ) == %Some{a: [b: 321]}
  end

  test "to_list 1" do
    assert HashUtils.to_list( %{a: 1} ) == [{:a, 1}]
  end

  test "to_list 2" do
    assert HashUtils.to_list( [a: 1] ) == [{:a, 1}]
  end

  test "addf 1" do
    assert HashUtils.addf(%Some{a: 1}, [:a], "qweqwe") == %Some{a: "qweqwe", b: %{c: [1,2,3]}}
  end

  test "addf 2" do
    assert HashUtils.addf(%Some{b: %{c: %{e: 1}}}, [:b, :e, :c, :d], "qweqwe") == %Some{b: %{c: %{e: 1}, e: %{c: %{d: "qweqwe"}}}}
  end

  test "addf 3" do
    assert HashUtils.addf(%Some{b: []}, [:b, :c, :d], "qweqwe") == %Some{a: 1, b: [c: [d: "qweqwe"]]}
  end

  test "to_map 1" do
    assert HashUtils.to_map([{"qwe",1}, {1,2}]) == %{"qwe" => 1, 1 => 2}
  end

  test "to_map 2" do
    assert HashUtils.to_map([a: 1, b: "qweqwe"]) == %{a: 1, b: "qweqwe"}
  end

  test "to_map 3" do
    assert HashUtils.to_map(%{a: 1, b: "qweqwe"}) == %{a: 1, b: "qweqwe"}
  end

  test "maybe get 1" do
    assert HashUtils.maybe_get(123, :qwe) == :not_hash
    assert HashUtils.maybe_get({}, :qwe) == :not_hash
    assert HashUtils.maybe_get("qwe", :qwe) == :not_hash
    assert HashUtils.maybe_get([{},{:qwe, 1}], :qwe) == :not_hash
    assert HashUtils.maybe_get(123, [:qwe, 123]) == :not_hash
    assert HashUtils.maybe_get(%{qwe: :qweqwe}, [:qwe, :qweqwe]) == :not_hash
    assert HashUtils.maybe_get(%{qwe: [{:qweqwe, 1}, {}]}, [:qwe, :qweqwe]) == :not_hash
  end

  test "maybe get 2" do
    assert HashUtils.maybe_get(%{}, :qwe) == nil
    assert HashUtils.maybe_get([], [:qwe, 123]) == nil
    assert HashUtils.maybe_get([{:qwe, 123}], [:qwe]) == 123
    assert HashUtils.maybe_get(%{qwe: :qweqwe}, :key) == nil
    assert HashUtils.maybe_get(%{qwe: [{:qweqwe, 1}, {}]}, [:qwe]) == [{:qweqwe, 1}, {}]
  end

  test "maybe get 3" do
    assert HashUtils.maybe_get(%{123 => [qwe: 321, qweqwe: 1]}, [123, :qwe]) == 321
    assert HashUtils.maybe_get(%Some{a: %{b: [c: 1]}}, :a) == %{b: [c: 1]}
    assert HashUtils.maybe_get(%Some{a: %{b: [c: 1]}}, [:a, :b, :c]) == 1
    assert HashUtils.maybe_get(%Some{a: %{b: [c: 1]}}, [:a, :b, :c, :d]) == :not_hash
  end

  test "impl on macro" do
    assert HashUtils.maybe_get(%SomeElse{}, [:b, :c]) == [1,2,3]
    assert HashUtils.maybe_get(%SomeElse{}, [:b, :d]) == nil
  end

end
