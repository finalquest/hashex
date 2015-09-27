defprotocol HashUtils do

  ####################
  ### useful funcs ###
  ####################

  def get( hash, lst )
  def set( hash, lst, val )
  def set( hash, keylist )
  def add( hash, lst, val )
  def delete( hash, lst )
  def delete( hash, path, lst_of_keys )

  def modify( hash, lst, func )
  def modify_all( hash, lst, func )
  def modify_all( hash, func )

  def keys( hash, lst )
  def keys( hash )
  def values( hash, lst )
  def values( hash )

  #
  # maybe make it funcs priv
  #

  def to_list( hash )
  def to_map( hash )
  def is_hash?( hash )
  def struct_degradation( hash )

  ####################
  ### legacy shits ###
  ####################

  def maybe_get( hash, lst )
  def addf( hash, lst, val )
  def add_to_list( hash, lst, val )
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

end


use Hashex, [Map]


defimpl HashUtils, for: [BitString, Float, Function, Integer, PID, Port, Reference, Tuple] do
  use Hashex.Defaults
  @type th :: bitstring | float | fun | integer | pid | port | reference | tuple

  @spec get(th, kgen) :: no_return
  @spec maybe_get(th, kgen) :: :not_hash
  def maybe_get(_, _), do: :not_hash
  @spec struct_degradation(th) :: th
  def struct_degradation(hash) when is_tuple(hash), do: Tuple.to_list(hash) |> HashUtils.struct_degradation |> List.to_tuple
  def struct_degradation(hash), do: hash
  @spec is_hash?(th) :: false
  def is_hash?(_), do: false

end




defimpl HashUtils, for: Atom do
  use Hashex.Defaults
  @type th :: atom

  @spec maybe_get(th, kgen) :: :not_hash | nil
  def maybe_get( nil, _ ), do: nil
  def maybe_get( _ , _ ), do: :not_hash
  @spec get(th, kgen) :: nil 
  def get( nil, _ ), do: nil
  @spec struct_degradation(th) :: th
  def struct_degradation(hash), do: hash
  @spec is_hash?(th) :: false
  def is_hash?(_), do: false
end


defimpl HashUtils, for: List do

  @type h :: list
  @type k :: atom
  @type kgen :: [k] | k
  @type v :: term

  @spec maybe_get(h, kgen) :: v
  def maybe_get(hash, [key]) do
    case HashUtils.is_hash?(hash) do
      true -> HashUtils.get(hash, key)
      false -> :not_hash
    end
  end
  def maybe_get(hash, [key|rest]) do
    case HashUtils.is_hash?(hash) do
      true -> HashUtils.get(hash, key) |> HashUtils.maybe_get(rest)
      false -> :not_hash
    end
  end
  def maybe_get(hash, key) do
    case HashUtils.is_hash?(hash) do
      true -> HashUtils.get(hash, key)
      false -> :not_hash
    end
  end

  @spec to_map([key: v]) :: map
  def to_map(lst), do: Enum.reduce(lst, %{}, fn({key,value}, res) -> Map.put(res, key, value) end )
  @spec struct_degradation(h) :: h
  def struct_degradation(hash) do
    case HashUtils.is_hash?(hash) do
      true -> HashUtils.modify_all(hash, &HashUtils.struct_degradation/1)
      false -> Enum.map(hash, &HashUtils.struct_degradation/1)
    end
  end

  @spec is_hash?(h) :: boolean
  def is_hash?(hash), do: Keyword.keyword?(hash)

  @spec get(h, kgen) :: v
  def get( hash, [key | []] ) do 
    case is_hash?(hash) do
      true -> hash[key]
      false -> (raise "data is not hash #{inspect hash}")
    end
  end
  def get( hash, [key | rest] ), do: HashUtils.get( hash[key], rest )
  def get( hash, key ), do: HashUtils.get( hash, [key] ) # special case for not-nested hashmap

  @spec modify(h, kgen, (v -> v)) :: h
  def modify( hash, [key | []], func ), do: Dict.update!( hash, key, func )
  def modify( hash, [key | rest], func ), do: Dict.update!( hash, key, fn(_) -> HashUtils.modify(Dict.get( hash, key ) , rest, func) end )
  def modify( hash, key, func ), do: HashUtils.modify( hash, [key], func ) # special case for not-nested hashmap

  @spec set(h, kgen, v) :: h
  def set( hash, lst, new_val ), do: HashUtils.modify( hash, lst, fn(_) -> new_val end )
  @spec set(h, [key: v]) :: h
  def set( hash, keylist ), do: Enum.reduce( keylist, hash, fn({k,v}, reshash) -> HashUtils.set( reshash, k, v ) end ) # support keylists for not-nested hash

  # modify all fields of hash if hash is keylist, or just do Enum.map for this list
  @spec modify_all(h, kgen, (v -> v)) :: h
  def modify_all(hash, key, func) when (is_atom(key) or is_number(key) or is_binary(key)), do: HashUtils.modify_all(hash, [key], func)
  def modify_all( lst, [], func ) do
    case HashUtils.is_hash?( lst ) do
      true -> Enum.map( lst, fn({k,v}) -> {k, func.(v)} end ) 
      false -> Enum.map( lst, fn(v) -> func.(v) end )
    end
  end
  def modify_all( hash, [key | rest], func ), do: Dict.update!( hash, key, fn(_) -> HashUtils.modify_all(Dict.get( hash, key ) , rest, func) end )
  @spec modify_all(h, (v -> v)) :: h
  def modify_all( hash, func ), do: HashUtils.modify_all( hash, [], func ) # special case for not-nested hashmap

  @spec delete(h, kgen) :: h
  def delete( hash, [key|[]] ) do
    case is_hash?(hash) do
      true -> Dict.delete( hash, key )
      false -> (raise "data is not hash #{inspect hash}")
    end
  end
  def delete( hash, [key|rest] ), do: Dict.update!( hash, key, fn(_) -> HashUtils.delete(Dict.get( hash, key ) , rest) end )
  def delete( hash, key ), do: HashUtils.delete( hash, [key] ) # special case for not-nested hashmap

  @spec delete(h, kgen, [k]) :: h
  def delete( hash, [], lst_to_delete ), do: Enum.reduce(lst_to_delete, hash, fn(el, res) -> HashUtils.delete( res, el ) end )
  def delete( hash, [key|rest], lst_to_delete ), do: Dict.update!( hash, key, fn(_) -> HashUtils.delete(Dict.get( hash, key ) , rest, lst_to_delete) end )
  def delete( hash, key, lst_to_delete ), do: HashUtils.delete( hash, [key], lst_to_delete )
  

  # it's like set/3 function, but can create new fields if it is need
  @spec add(h, kgen, v) :: h
  def add( hash, [new_key|[]], new_val ) do 
    case is_hash?(hash) do
      true -> Dict.put( hash, new_key, new_val )
      false -> (raise "not hash struct #{inspect hash}")
    end
  end
  def add( hash, [key | rest], new_val ), do: Dict.update!( hash, key, fn(_) -> HashUtils.add(Dict.get( hash, key ) , rest, new_val) end )
  def add( hash, new_key, new_val ), do: HashUtils.add( hash, [new_key], new_val ) # special case for not-nested hashmap

  @spec add_to_list(h, [k], v) :: h
  def add_to_list(lst, [], new_val), do: [new_val | lst]
  def add_to_list(hash, [key|rest], new_val), do: Dict.update!( hash, key, fn(_) -> HashUtils.add_to_list(Dict.get( hash, key ) , rest, new_val) end )


  # get all keys except :__struct__
  @spec keys(h, [k]) :: [k]
  def keys( hash, [] ), do: Dict.keys(hash)
  def keys( hash, [key | rest] ), do: Dict.get(hash, key) |> HashUtils.keys( rest )
  @spec keys(h) :: [k]
  def keys( hash ), do: HashUtils.keys( hash, [] )
  # get all values except :__struct__
  @spec values(h, [k]) :: [v]
  def values( hash, lst ), do: Enum.map( HashUtils.keys( hash, lst ), fn( key ) -> HashUtils.get(hash, lst++[key] ) end )
  @spec values(h) :: [v]
  def values( hash ), do: Enum.map( HashUtils.keys( hash ), fn( key ) -> HashUtils.get(hash, key ) end )


  # result - map_of changed elements
  @spec select_changes_kv(h, h) :: h
  def select_changes_kv( new_hash, old_hash ), do: HashUtils.select_changes_kv( new_hash, old_hash, [] )
  @spec select_changes_kv(h, h, [k] | (v,v -> boolean)) :: h
  def select_changes_kv( new_hash, old_hash, [] ) do
    Enum.reduce( HashUtils.keys(new_hash), %{}, fn(key, resmap) ->
      new_val = HashUtils.get(new_hash, key)
      case new_val == HashUtils.get(old_hash, key) do
        true -> resmap
        false -> Map.put( resmap, key, new_val )
      end
    end )
  end
  def select_changes_kv( new_hash, old_hash, [key | rest] ), do: HashUtils.select_changes_kv( HashUtils.get(new_hash, key), HashUtils.get(old_hash, key), rest )
  def select_changes_kv( new_hash, old_hash, condition ), do: HashUtils.select_changes_kv( new_hash, old_hash, [], condition )
  # select func with special condition (func/2)
  @spec select_changes_kv(h, h, [k], (v,v -> boolean)) :: h
  def select_changes_kv( new_hash, old_hash, [] , condition) do
    Enum.reduce( HashUtils.keys(new_hash), %{}, fn(key, resmap) ->
      new_val = HashUtils.get(new_hash, key)
      case condition.(new_val, HashUtils.get(old_hash, key)) do
        false -> resmap
        true -> Map.put( resmap, key, new_val )
      end
    end )
  end
  def select_changes_kv( new_hash, old_hash, [key | rest], condition ), do: HashUtils.select_changes_kv( HashUtils.get(new_hash, key), HashUtils.get(old_hash, key), rest, condition )

  # simple select_changes func, only by keys
  @spec select_changes_k(h, h) :: h
  def select_changes_k( new_hash, old_hash ), do: HashUtils.select_changes_k( new_hash, old_hash, [] )
  @spec select_changes_k(h, h, [k]) :: h
  def select_changes_k( new_hash, old_hash, [] ), do: HashUtils.delete( new_hash, [], HashUtils.keys(old_hash) ) |> Enum.reduce(%{}, fn({k,v}, res) -> Map.put(res, k, v) end)
  def select_changes_k( new_hash, old_hash, [key | rest] ), do: HashUtils.select_changes_k( HashUtils.get(new_hash, key), HashUtils.get(old_hash, key), rest )

  @spec plain_update(h, h) :: h
  def plain_update( hash, incoming_data ), do: plain_update( hash, [], incoming_data )
  @spec plain_update(h, [k], h) :: h
  def plain_update( hash, [], incoming_data ), do: Enum.reduce( HashUtils.keys(incoming_data), hash, fn(key, result) -> HashUtils.add( result, key, HashUtils.get(incoming_data, key)) end )
  def plain_update( hash, [key|rest], incoming_data ), do: Dict.update!( hash, key, fn(_) -> HashUtils.plain_update(Dict.get( hash, key ) , rest, incoming_data) end )


  @spec filter_k(h, (k -> boolean)) :: h
  def filter_k( hash, func ), do: HashUtils.filter_k( hash, [], func )
  @spec filter_k(h, [k], (k -> boolean)) :: h
  def filter_k( hash, [], func ), do: HashUtils.delete( hash, [], Enum.filter( HashUtils.keys(hash), fn(key) -> not(func.(key)) end ) )
  def filter_k( hash, lst, func ), do: HashUtils.modify( hash, lst, fn(target) -> HashUtils.filter_k(target, func) end )
  
  @spec filter_v(h, (v -> boolean)) :: h
  def filter_v( hash, func ), do: HashUtils.filter_v( hash, [], func )
  @spec filter_v(h, [k], (v -> boolean)) :: h
  def filter_v( hash, [], func ), do: HashUtils.delete( hash, [], Enum.filter( HashUtils.keys(hash), fn(key) -> not(func.( HashUtils.get(hash, key) )) end ) )
  def filter_v( hash, lst, func ), do: HashUtils.modify( hash, lst, fn(target) -> HashUtils.filter_v(target, func) end )

  @spec to_list(h) :: h
  def to_list(hash), do: hash
  
  @spec addf(h, [k,...], v) :: h
  def addf(hash, path = [_|_], val), do: addf_proc(hash, path, val)
  def addf(hash, path, val), do: (raise "HashUtils.addf : wrong path #{inspect path} to hash #{inspect hash} and val #{inspect val}")

  @spec addf_proc(h, [k], v) :: h
  defp addf_proc(hash, [first|[]], val), do: HashUtils.add(hash, first, val)
  defp addf_proc(hash, path = [first|rest], val) do
    case HashUtils.get(hash, first) do
      nil -> HashUtils.add( hash, first, HashUtils.addf( [], rest, val ) )
      some ->
        case HashUtils.is_hash?(some) do
          false -> raise "HashUtils.addf : can't apply addf to not hash #{inspect some}. Path #{inspect path}, hash #{inspect hash}, val #{inspect val}"
          true -> HashUtils.add( hash, first, HashUtils.addf( some, rest, val ) )
        end
    end
  end

end