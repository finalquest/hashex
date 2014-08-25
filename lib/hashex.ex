defmodule Hashex do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Hashex.Worker, [arg1, arg2, arg3])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hashex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defprotocol HashUtils do

  def get( hash, lst )
  def set( hash, lst, val )
  def set( hash, keylist )
  def add( hash, lst, val )
  def modify( hash, lst, func )
  def modify_all( hash, lst, func )
  def modify_all( hash, func )
  def delete( hash, lst )

  def keys( hash, lst )
  def keys( hash )
  def values( hash, lst )
  def values( hash )

  def select_changes( new_hash, old_hash ) # like "--" operator 
  def select_changes( new_hash, old_hash, lst_or_condition )  # like "--" operator 
  def select_changes( new_hash, old_hash, lst, condition )  # condition(el1, el2) instead el1 == el2 inside function

end

defimpl HashUtils, for: Map do

  def get( hash, [key | []] ) do
    Map.get( hash, key )
  end
  def get( hash, [key | rest] ) do
    HashUtils.get( Map.get( hash, key ) , rest )
  end
  def get( hash, key )  do # special case for not-nested hashmap
    HashUtils.get( hash, [key] )
  end

  def modify( hash, [key | []], func ) do
    Map.update!( hash, key, func )
  end
  def modify( hash, [key | rest], func ) do
    Map.update!( hash, key, fn(_) -> HashUtils.modify(Map.get( hash, key ) , rest, func) end )
  end
  def modify( hash, key, func ) do # special case for not-nested hashmap
    HashUtils.modify( hash, [key], func )
  end

  def set( hash, lst, new_val ) do
    HashUtils.modify( hash, lst, fn(_) -> new_val end )
  end
  def set( hash, keylist ) do # support keylists for not-nested hash
    Enum.reduce( keylist, hash, fn({k,v}, reshash) -> HashUtils.set( reshash, k, v ) end )
  end
  

  # modify all fields of hash, except :__struct__
  def modify_all( hash, [], func ) do
    Enum.reduce( Map.to_list(hash), hash, fn({k, v}, res) ->
      case k do
        :__struct__ -> Map.update!( res, k, fn(_) -> v end )
        _ -> Map.update!( res, k, func )
      end
    end )
  end
  def modify_all( hash, [key|rest], func ) do
    Map.update!( hash, key, fn(_) -> HashUtils.modify_all(Map.get( hash, key ) , rest, func) end )
  end
  def modify_all( hash, func ) do # special case for not-nested hashmap
    HashUtils.modify_all( hash, [], func )
  end

  def delete( hash, [key|[]] ) do
    case Map.has_key?( hash, :__struct__ ) do
      true -> raise "Can't delete any field of struct #{inspect hash}"
      false -> Map.delete( hash, key )
    end
  end
  def delete( hash, [key|rest] ) do
    Map.update!( hash, key, fn(_) -> HashUtils.delete(Map.get( hash, key ) , rest) end )
  end
  def delete( hash, key ) do # special case for not-nested hashmap
    HashUtils.delete( hash, [key] )
  end

  # it's like set/3 function, but can create new fields if it is need
  def add( hash, [new_key|[]], new_val ) do
    case Map.has_key?( hash, :__struct__ ) do
      true -> raise "Can't create any new field in struct #{inspect hash}"
      false -> Map.put( hash, new_key, new_val )
    end
  end
  def add( hash, [key | rest], new_val ) do
    Map.update!( hash, key, fn(_) -> HashUtils.add(Map.get( hash, key ) , rest, new_val) end )
  end
  def add( hash, new_key, new_val ) do # special case for not-nested hashmap
    HashUtils.add( hash, [new_key], new_val )
  end
  
  # get all keys except :__struct__
  def keys( hash, [] ) do
    Map.keys(hash) -- [:__struct__]
  end
  def keys( hash, [key | rest] ) do
    Map.get(hash, key)
      |> HashUtils.keys( rest )
  end
  def keys( hash ) do
    HashUtils.keys( hash, [] )
  end
  # get all values except :__struct__
  def values( hash, lst ) do
    Enum.map( HashUtils.keys( hash, lst ), 
      fn( key ) -> HashUtils.get(hash, lst++[key] ) end )
  end
  def values( hash ) do
    Enum.map( HashUtils.keys( hash ), 
      fn( key ) -> HashUtils.get(hash, key ) end )
  end
  
  # result - map_of changed elements
  def select_changes( new_hash, old_hash ) do
    HashUtils.select_changes( new_hash, old_hash, [] )
  end
  def select_changes( new_hash, old_hash, [] ) do
    Enum.reduce( HashUtils.keys(new_hash), %{}, fn(key, resmap) ->
      new_val = HashUtils.get(new_hash, key)
      case new_val == HashUtils.get(old_hash, key) do
        true -> resmap
        false -> Map.put( resmap, key, new_val )
      end 
    end )
  end
  def select_changes( new_hash, old_hash, [key | rest] ) do
    HashUtils.select_changes( HashUtils.get(new_hash, key), HashUtils.get(old_hash, key), rest )
  end
  
  # select func with special condition (func/2)
  def select_changes( new_hash, old_hash, condition ) do
    HashUtils.select_changes( new_hash, old_hash, [], condition )
  end
  def select_changes( new_hash, old_hash, [] , condition) do
    Enum.reduce( HashUtils.keys(new_hash), %{}, fn(key, resmap) ->
      new_val = HashUtils.get(new_hash, key)
      case condition.(new_val, HashUtils.get(old_hash, key)) do
        true -> resmap
        false -> Map.put( resmap, key, new_val )
      end
    end )
  end
  def select_changes( new_hash, old_hash, [key | rest], condition ) do
    HashUtils.select_changes( HashUtils.get(new_hash, key), HashUtils.get(old_hash, key), rest, condition )
  end

end

defimpl HashUtils, for: List do

  def get( hash, [key | []] ) do
    hash[key]
  end
  def get( hash, [key | rest] ) do
    HashUtils.get( hash[key], rest )
  end
  def get( hash, key )  do # special case for not-nested hashmap
    HashUtils.get( hash, [key] )
  end

  def modify( hash, [key | []], func ) do
    Dict.update!( hash, key, func )
  end
  def modify( hash, [key | rest], func ) do
    Dict.update!( hash, key, fn(_) -> HashUtils.modify(Dict.get( hash, key ) , rest, func) end )
  end
  def modify( hash, key, func ) do # special case for not-nested hashmap
    HashUtils.modify( hash, [key], func )
  end

  def set( hash, lst, new_val ) do
    HashUtils.modify( hash, lst, fn(_) -> new_val end )
  end
  def set( hash, keylist ) do # support keylists for not-nested hash
    Enum.reduce( keylist, hash, fn({k,v}, reshash) -> HashUtils.set( reshash, k, v ) end )
  end

  # modify all fields of hash if hash is_keylist, or just do Enum.map for this list
  def modify_all( lst, [], func ) do
    case is_keylist( lst ) do
      true -> Enum.reduce( lst, lst, fn({k, _}, res) ->
                Dict.update!( res, k, func )
              end )
      false -> Enum.map( lst, func )
    end
  end
  def modify_all( hash, [key | rest], func ) do
    Dict.update!( hash, key, fn(_) -> HashUtils.modify_all(Dict.get( hash, key ) , rest, func) end )
  end
  def modify_all( hash, func ) do # special case for not-nested hashmap
    HashUtils.modify_all( hash, [], func )
  end

  def delete( hash, [key|[]] ) do
    Dict.delete( hash, key )
  end
  def delete( hash, [key|rest] ) do
    Dict.update!( hash, key, fn(_) -> HashUtils.delete(Dict.get( hash, key ) , rest) end )
  end
  def delete( hash, key ) do # special case for not-nested hashmap
    HashUtils.delete( hash, [key] )
  end

  # it's like set/3 function, but can create new fields if it is need
  def add( hash, [new_key|[]], new_val ) do
      Dict.put( hash, new_key, new_val )
  end
  def add( hash, [key | rest], new_val ) do
    Dict.update!( hash, key, fn(_) -> HashUtils.add(Dict.get( hash, key ) , rest, new_val) end )
  end
  def add( hash, new_key, new_val ) do # special case for not-nested hashmap
    HashUtils.add( hash, [new_key], new_val )
  end


  # get all keys except :__struct__
  def keys( hash, [] ) do
    Dict.keys(hash)
  end
  def keys( hash, [key | rest] ) do
    Dict.get(hash, key)
      |> HashUtils.keys( rest )
  end
  def keys( hash ) do
    HashUtils.keys( hash, [] )
  end
  # get all values except :__struct__
  def values( hash, lst ) do
    Enum.map( HashUtils.keys( hash, lst ), 
      fn( key ) -> HashUtils.get(hash, lst++[key] ) end )
  end
  def values( hash ) do
    Enum.map( HashUtils.keys( hash ), 
      fn( key ) -> HashUtils.get(hash, key ) end )
  end


  # result - map_of changed elements
  def select_changes( new_hash, old_hash ) do
    HashUtils.select_changes( new_hash, old_hash, [] )
  end
  def select_changes( new_hash, old_hash, [] ) do
    Enum.reduce( HashUtils.keys(new_hash), %{}, fn(key, resmap) ->
      new_val = HashUtils.get(new_hash, key)
      case new_val == HashUtils.get(old_hash, key) do
        true -> resmap
        false -> Map.put( resmap, key, new_val )
      end
    end )
  end
  def select_changes( new_hash, old_hash, [key | rest] ) do
    HashUtils.select_changes( HashUtils.get(new_hash, key), HashUtils.get(old_hash, key), rest )
  end
  def select_changes( new_hash, old_hash, condition ) do
    HashUtils.select_changes( new_hash, old_hash, [], condition )
  end
  # select func with special condition (func/2)
  def select_changes( new_hash, old_hash, [] , condition) do
    Enum.reduce( HashUtils.keys(new_hash), %{}, fn(key, resmap) ->
      new_val = HashUtils.get(new_hash, key)
      case condition.(new_val, HashUtils.get(old_hash, key)) do
        false -> resmap
        true -> Map.put( resmap, key, new_val )
      end
    end )
  end
  def select_changes( new_hash, old_hash, [key | rest], condition ) do
    HashUtils.select_changes( HashUtils.get(new_hash, key), HashUtils.get(old_hash, key), rest, condition )
  end


  # priv funcs for modify_all
  defp is_keylist lst do
    is_lst_of_tuples(lst)
      |> is_tuples_size2(lst)
        |> is_fist_elem_atom(lst)
  end

  defp is_lst_of_tuples lst do
    Enum.all?( lst, fn(el) -> is_tuple(el) end )
  end
  defp is_tuples_size2 false, _ do
    false
  end
  defp is_tuples_size2 true, lst do
    Enum.all?( lst, fn(el) -> :erlang.size(el) == 2 end )
  end
  defp is_fist_elem_atom false, _ do
    false
  end
  defp is_fist_elem_atom true, lst do
    Enum.all?( lst, fn({k, _}) -> is_atom(k) end )
  end


end