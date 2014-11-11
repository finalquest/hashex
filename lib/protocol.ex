defprotocol HashUtils do
  @fallback_to_any true

  def maybe_get( hash, lst )

  def get( hash, lst )
  def set( hash, lst, val )
  def set( hash, keylist )
  def add( hash, lst, val )
  def addf( hash, lst, val )
  def add_to_list( hash, lst, val )
  def modify( hash, lst, func )
  def modify_all( hash, lst, func )
  def modify_all( hash, func )
  def delete( hash, lst )
  def delete( hash, path, lst_of_keys )

  def keys( hash, lst )
  def keys( hash )
  def values( hash, lst )
  def values( hash )

  def select_changes_k( new_hash, old_hash ) # -- operator for hashmaps
  def select_changes_k( new_hash, old_hash, lst ) # -- operator for hashmaps

  def select_changes_kv( new_hash, old_hash ) # like "--" operator , but consider new keys AND any changing in values
  def select_changes_kv( new_hash, old_hash, lst_or_condition )  # like "--" operator , but consider new keys AND any changing in values
  def select_changes_kv( new_hash, old_hash, lst, condition )  # condition(el1, el2) instead el1 == el2 inside function

  def plain_update( hash, incoming_data ) # incoming_data - also hashmap
  def plain_update( hash, lst, incoming_data )

  def filter_k( hash, lst, func )
  def filter_k( hash, func )
  def filter_v( hash, lst, func )
  def filter_v( hash, func )

  def to_list( hash )
  def to_map( hash )
  def struct_degradation( hash )
  def is_hash?( hash )

end


use Hashex, [Map]


defimpl HashUtils, for: [BitString, Float, Function, Integer, PID, Port, Reference, Tuple, Any] do

  def maybe_get(_, _) do
    :not_hash
  end

  def struct_degradation(hash) when is_map(hash) do
    Map.delete(hash, :__struct__)
      |> HashUtils.modify_all(&HashUtils.struct_degradation/1)
  end
  def struct_degradation(hash) when is_list(hash) do
    case HashUtils.is_hash?(hash) do
      true -> HashUtils.modify_all(hash, &HashUtils.struct_degradation/1)
      false -> Enum.map(hash, &HashUtils.struct_degradation/1)
    end
  end
  def struct_degradation(hash) when is_tuple(hash) do
    Tuple.to_list(hash)
      |> HashUtils.struct_degradation
          |> List.to_tuple
  end
  def struct_degradation(hash) do
    hash
  end
  def is_hash?(_) do
    false
  end
  

end




defimpl HashUtils, for: Atom do
  
  def maybe_get( nil, _ ) do
    nil
  end
  def maybe_get( _ , _ ) do
    :not_hash
  end
  

  def get( nil, _ ) do
    nil
  end
  def struct_degradation(hash) do
    hash
  end
  def is_hash?(_) do
    false
  end
end


defimpl HashUtils, for: List do

  def maybe_get(hash, [key]) do
    case HashUtils.is_hash?(hash) do
      true -> HashUtils.get(hash, key)
      false -> :not_hash
    end
  end
  def maybe_get(hash, [key|rest]) do
    case HashUtils.is_hash?(hash) do
      true -> HashUtils.get(hash, key)
                |> HashUtils.maybe_get(rest)
      false -> :not_hash
    end
  end
  def maybe_get(hash, key) do
    case HashUtils.is_hash?(hash) do
      true -> HashUtils.get(hash, key)
      false -> :not_hash
    end
  end


  def to_map lst do
    Enum.reduce(lst, %{}, 
      fn({key,value}, res) ->
        Map.put(res, key, value)
      end )
  end
  def struct_degradation(hash) do
    case HashUtils.is_hash?(hash) do
      true -> HashUtils.modify_all(hash, &HashUtils.struct_degradation/1)
      false -> Enum.map(hash, &HashUtils.struct_degradation/1)
    end
  end

  def is_hash?(hash) do
    is_keylist(hash)
  end

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
  def modify_all(hash, key, func) when (is_atom(key) or is_number(key) or is_binary(key)) do
    HashUtils.modify_all(hash, [key], func)
  end
  def modify_all( lst, [], func ) do
    case is_keylist( lst ) do
      true -> Enum.map( lst, fn({k,v}) -> {k, ExTask.run( fn() -> func.(v) end )} end ) 
                |> Enum.map( fn({k,v}) -> {k, {:result, data} = ExTask.await(v, :infinity)}; {k, data} end )
      false -> Enum.map( lst, fn(v) -> ExTask.run( fn() -> func.(v) end ) end ) 
                |> Enum.map( fn(v) -> {:result, data} = ExTask.await(v, :infinity); data end )
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

  def delete( hash, [], lst_to_delete ) do
    Enum.reduce(lst_to_delete, hash, fn(el, res) -> 
      HashUtils.delete( res, el )
    end )
  end
  def delete( hash, [key|rest], lst_to_delete ) do
    Dict.update!( hash, key, fn(_) -> HashUtils.delete(Dict.get( hash, key ) , rest, lst_to_delete) end )
  end
  def delete( hash, key, lst_to_delete ) do
    HashUtils.delete( hash, [key], lst_to_delete )
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

  def add_to_list(lst, [], new_val) do
    [new_val | lst]
  end
  def add_to_list(hash, [key|rest], new_val) do
    Dict.update!( hash, key, fn(_) -> HashUtils.add_to_list(Dict.get( hash, key ) , rest, new_val) end )
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
  def select_changes_kv( new_hash, old_hash ) do
    HashUtils.select_changes_kv( new_hash, old_hash, [] )
  end
  def select_changes_kv( new_hash, old_hash, [] ) do
    Enum.reduce( HashUtils.keys(new_hash), %{}, fn(key, resmap) ->
      new_val = HashUtils.get(new_hash, key)
      case new_val == HashUtils.get(old_hash, key) do
        true -> resmap
        false -> Map.put( resmap, key, new_val )
      end
    end )
  end
  def select_changes_kv( new_hash, old_hash, [key | rest] ) do
    HashUtils.select_changes_kv( HashUtils.get(new_hash, key), HashUtils.get(old_hash, key), rest )
  end
  def select_changes_kv( new_hash, old_hash, condition ) do
    HashUtils.select_changes_kv( new_hash, old_hash, [], condition )
  end
  # select func with special condition (func/2)
  def select_changes_kv( new_hash, old_hash, [] , condition) do
    Enum.reduce( HashUtils.keys(new_hash), %{}, fn(key, resmap) ->
      new_val = HashUtils.get(new_hash, key)
      case condition.(new_val, HashUtils.get(old_hash, key)) do
        false -> resmap
        true -> Map.put( resmap, key, new_val )
      end
    end )
  end
  def select_changes_kv( new_hash, old_hash, [key | rest], condition ) do
    HashUtils.select_changes_kv( HashUtils.get(new_hash, key), HashUtils.get(old_hash, key), rest, condition )
  end

  # simple select_changes func, only by keys
  def select_changes_k( new_hash, old_hash ) do
    HashUtils.select_changes_k( new_hash, old_hash, [] )
  end
  def select_changes_k( new_hash, old_hash, [] ) do
    HashUtils.delete( new_hash, [], HashUtils.keys(old_hash) )
      |> Enum.reduce(%{}, fn({k,v}, res) -> Map.put(res, k, v) end)
  end
  def select_changes_k( new_hash, old_hash, [key | rest] ) do
    HashUtils.select_changes_k( HashUtils.get(new_hash, key), HashUtils.get(old_hash, key), rest )
  end

  def plain_update( hash, incoming_data ) do
    plain_update( hash, [], incoming_data )
  end
  def plain_update( hash, [], incoming_data ) do
    Enum.reduce( HashUtils.keys(incoming_data), hash, fn(key, result) ->
      HashUtils.add( result, key, HashUtils.get(incoming_data, key)) end )
  end
  def plain_update( hash, [key|rest], incoming_data ) do
    Dict.update!( hash, key, fn(_) -> HashUtils.plain_update(Dict.get( hash, key ) , rest, incoming_data) end )
  end


  def filter_k( hash, func ) do
    HashUtils.filter_k( hash, [], func )
  end
  def filter_k( hash, [], func ) do
    HashUtils.delete( hash, [],
      Enum.filter( HashUtils.keys(hash), fn(key) -> not(func.(key)) end ) )
  end
  def filter_k( hash, lst, func ) do
    HashUtils.modify( hash, lst, fn(target) -> HashUtils.filter_k(target, func) end )
  end
  
  def filter_v( hash, func ) do
    HashUtils.filter_v( hash, [], func )
  end
  def filter_v( hash, [], func ) do
    HashUtils.delete( hash, [],
      Enum.filter( HashUtils.keys(hash), fn(key) -> not(func.( HashUtils.get(hash, key) )) end ) )
  end
  def filter_v( hash, lst, func ) do
    HashUtils.modify( hash, lst, fn(target) -> HashUtils.filter_v(target, func) end )
  end

  def to_list hash do
    hash
  end
  

  def addf(hash, path, val) when (is_list(path) and (path != [])) do
    addf_proc(hash, path, val)
  end
  def addf(hash, path, val) do
    raise "HashUtils.addf : wrong path #{inspect path} to hash #{inspect hash} and val #{inspect val}"
  end
  

  defp addf_proc(hash, [first|[]], val) do
    HashUtils.add(hash, first, val)
  end
  defp addf_proc(hash, path = [first|rest], val) do
    case HashUtils.get(hash, first) do
      nil -> HashUtils.add( hash, first, 
              HashUtils.addf( [], rest, val ) )
      some ->
        case HashUtils.is_hash?(some) do
          false -> raise "HashUtils.addf : can't apply addf to not hash #{inspect some}. Path #{inspect path}, hash #{inspect hash}, val #{inspect val}"
          true -> HashUtils.add( hash, first, HashUtils.addf( some, rest, val ) )
        end
    end
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