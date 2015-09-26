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

  defmodule Defaults do
    defmacro __using__(_) do
      quote location: :keep do

        @type h :: term
        @type k :: atom | binary | number
        @type kgen :: [k] | k
        @type v :: term

        def maybe_get( _, _ ), do: (raise "not implemented!")
        def get( _, _ ), do: (raise "not implemented!")
        @spec set(h, kgen, v) :: no_return
        def set( _, _, _ ), do: (raise "not implemented!")
        @spec set(h, [key: v]) :: no_return
        def set( _, _ ), do: (raise "not implemented!")
        @spec add(h, kgen, v) :: no_return
        def add( _, _, _ ), do: (raise "not implemented!")
        @spec addf(h, [k,...], v) :: no_return
        def addf( _, _, _ ), do: (raise "not implemented!")
        @spec add_to_list(h, [k], v) :: no_return
        def add_to_list( _, _, _ ), do: (raise "not implemented!")
        @spec modify(h, kgen, (v -> v)) :: no_return
        def modify( _, _, _ ), do: (raise "not implemented!")
        @spec modify_all(h, kgen, (v -> v)) :: no_return
        def modify_all( _, _, _ ), do: (raise "not implemented!")
        @spec modify_all(h, (v -> v)) :: no_return
        def modify_all( _, _ ), do: (raise "not implemented!")
        @spec delete(h, kgen) :: no_return
        def delete( _, _ ), do: (raise "not implemented!")
        @spec delete(h, kgen, [k]) :: no_return
        def delete( _, _, _ ), do: (raise "not implemented!")
        @spec keys(h, [k]) :: no_return
        def keys( _, _ ), do: (raise "not implemented!")
        @spec keys(h) :: no_return
        def keys( _ ), do: (raise "not implemented!")
        @spec values(h, [v]) :: no_return
        def values( _, _ ), do: (raise "not implemented!")
        @spec values(h) :: no_return
        def values( _ ), do: (raise "not implemented!")
        @spec select_changes_k(h, h) :: no_return
        def select_changes_k( _, _ ), do: (raise "not implemented!") # -- operator for hashmaps
        @spec select_changes_k(h, h, [k]) :: no_return
        def select_changes_k( _, _, _ ), do: (raise "not implemented!") # -- operator for hashmaps
        @spec select_changes_kv(h, h) :: no_return
        def select_changes_kv( _, _ ), do: (raise "not implemented!") # like "--" operator , but consider new keys AND any changing in values
        @spec select_changes_kv(h, h, [k] | (v,v -> boolean)) :: no_return
        def select_changes_kv( _, _, _ ), do: (raise "not implemented!")  # like "--" operator , but consider new keys AND any changing in values
        @spec select_changes_kv(h, h, [k], (v,v -> boolean)) :: no_return
        def select_changes_kv( _, _, _, _ ), do: (raise "not implemented!")  # condition(el1, el2) instead el1 == el2 inside function
        @spec plain_update(h, h) :: no_return
        def plain_update( _, _ ), do: (raise "not implemented!") # incoming_data - also hashmap
        @spec plain_update(h, [k], h) :: no_return
        def plain_update( _, _, _ ), do: (raise "not implemented!")
        @spec filter_k(h, [k], (k -> boolean)) :: no_return
        def filter_k( _, _, _ ), do: (raise "not implemented!")
        @spec filter_k(h, (k -> boolean)) :: no_return
        def filter_k( _, _ ), do: (raise "not implemented!")
        @spec filter_v(h, [k], (v -> boolean)) :: no_return
        def filter_v( _, _, _ ), do: (raise "not implemented!")
        @spec filter_v(h, (v -> boolean)) :: no_return
        def filter_v( _, _ ), do: (raise "not implemented!")
        @spec to_list(h) :: no_return
        def to_list( _ ), do: (raise "not implemented!")
        @spec to_map(h) :: no_return
        def to_map( _ ), do: (raise "not implemented!")
        def struct_degradation( _ ), do: (raise "not implemented!")
        def is_hash?( _ ), do: (raise "not implemented!")
        defoverridable [ 
          maybe_get: 2,
          get: 2,
          set: 3,
          set: 2,
          add: 3,
          addf: 3,
          add_to_list: 3,
          modify: 3,
          modify_all: 3,
          modify_all: 2,
          delete: 2,
          delete: 3,
          keys: 2,
          keys: 1,
          values: 2,
          values: 1,
          select_changes_k: 2,
          select_changes_k: 3,
          select_changes_kv: 2,
          select_changes_kv: 3,
          select_changes_kv: 4,
          plain_update: 2,
          plain_update: 3,
          filter_k: 3,
          filter_k: 2,
          filter_v: 3,
          filter_v: 2,
          to_list: 1,
          to_map: 1,
          struct_degradation: 1,
          is_hash?: 1
        ] 
      end
    end
  end

  defmacro __using__(some) when (is_atom(some) or is_list(some)) do
    quote location: :keep do
      defimpl HashUtils, for: unquote(some) do

        @type h :: %{}
        @type k :: atom | binary | number
        @type kgen :: [k] | k
        @type v :: term

        @spec maybe_get(h, kgen) :: v
        def maybe_get(hash, [key]), do: HashUtils.get(hash, key)
        def maybe_get(hash, [key|rest]), do: HashUtils.get(hash, key) |> HashUtils.maybe_get(rest)
        def maybe_get(hash, key), do: HashUtils.get(hash, key)
        
        @spec is_hash?(h) :: true
        def is_hash?(_), do: true
        @spec to_map(h) :: h
        def to_map(some), do: Map.delete(some, :__struct__)
        
        @spec struct_degradation(h) :: h
        def struct_degradation(hash), do: Map.delete(hash, :__struct__) |> HashUtils.modify_all(&HashUtils.struct_degradation/1)

        @spec get(h, kgen) :: v
        def get( hash, [key | []] ), do: Map.get( hash, key )
        def get( hash, [key | rest] ), do: HashUtils.get( Map.get( hash, key ) , rest )
        def get( hash, key ), do: HashUtils.get( hash, [key] ) # special case for not-nested hashmap

        @spec modify(h, kgen, (v -> v)) :: h
        def modify( hash, [key | []], func ), do: Map.update!( hash, key, func )
        def modify( hash, [key | rest], func ), do: Map.update!( hash, key, fn(inner) -> HashUtils.modify(inner , rest, func) end )
        def modify( hash, key, func ), do: HashUtils.modify( hash, [key], func ) # special case for not-nested hashmap

        @spec set(h, kgen, v) :: h
        def set( hash, lst, new_val ), do: HashUtils.modify( hash, lst, fn(_) -> new_val end )
        @spec set(h, [key: v]) :: h
        def set( hash, keylist ), do: Enum.reduce( keylist, hash, fn({k,v}, reshash) -> HashUtils.set( reshash, k, v ) end ) # support keylists for not-nested hash

        # modify all fields of hash, except :__struct__
        @spec modify_all(h, kgen, (v -> v)) :: h
        def modify_all(hash, key, func) when (is_atom(key) or is_number(key) or is_binary(key)), do: HashUtils.modify_all(hash, [key], func)
        def modify_all( hash, [], func ) do
          Stream.map( Map.to_list(hash) , fn
            {k = :__struct__, v} -> {k,v}
            {k, v} -> {k, func.(v)}
          end ) 
          |> Enum.reduce( %{}, fn({k, v}, res) -> Map.put(res, k, v) end )
        end
        def modify_all( hash, [key|rest], func ), do: Map.update!( hash, key, fn(inner) -> HashUtils.modify_all(inner , rest, func) end )
        @spec modify_all(h, (v -> v)) :: h
        def modify_all( hash, func ), do: HashUtils.modify_all( hash, [], func ) # special case for not-nested maps

        @spec delete(h, kgen) :: h
        def delete( hash, [key|[]] ) do
          case Map.has_key?( hash, :__struct__ ) do
            true -> raise "Can't delete any field of struct #{inspect hash}"
            false -> Map.delete( hash, key )
          end
        end
        def delete( hash, [key|rest] ), do: Map.update!( hash, key, fn(inner) -> HashUtils.delete(inner , rest) end )
        def delete( hash, key ), do: HashUtils.delete( hash, [key] ) # special case for not-nested hashmap

        @spec delete(h, kgen, [k]) :: h
        def delete( hash, [], lst_to_delete ), do: Enum.reduce(lst_to_delete, hash, fn(el, res) -> HashUtils.delete( res, el ) end )
        def delete( hash, [key|rest], lst_to_delete ), do: Map.update!( hash, key, fn(inner) -> HashUtils.delete(inner , rest, lst_to_delete) end )
        def delete( hash, key, lst_to_delete ), do: HashUtils.delete( hash, [key], lst_to_delete )

        # it's like set/3 function, but can create new fields if it is need
        @spec add(h, kgen, v) :: h
        def add( hash, [new_key|[]], new_val ) do
          case (Map.has_key?( hash, :__struct__ ) and not(Map.has_key?(hash, new_key)) ) do
            true -> raise "HashUtils.add : Can't create any new field in struct #{inspect hash}, key #{inspect new_key}, val #{new_val}"
            false -> Map.put( hash, new_key, new_val )
          end
        end
        def add( hash, [key | rest], new_val ), do: Map.update!( hash, key, fn(inner) -> HashUtils.add(inner , rest, new_val) end )
        def add( hash, new_key, new_val ), do: HashUtils.add( hash, [new_key], new_val ) # special case for not-nested hashmap

        @spec add_to_list(h, [k], v) :: h
        def add_to_list(hash, [key|rest], new_val), do: Map.update!( hash, key, fn(inner) -> HashUtils.add_to_list(inner , rest, new_val) end )
        
        # get all keys except :__struct__
        @spec keys(h, [k]) :: [k]
        def keys( hash, [] ), do: Map.keys(hash) |> Enum.filter(&(&1 != :__struct__))
        def keys( hash, [key | rest] ), do: Map.get(hash, key) |> HashUtils.keys( rest )
        @spec keys(h) :: [k]
        def keys( hash ), do: HashUtils.keys( hash, [] )
        # get all values except :__struct__
        @spec values(h, [k]) :: [v]
        def values( hash, lst ), do: Enum.map( HashUtils.keys( hash, lst ), fn( key ) -> HashUtils.get(hash, lst++[key] ) end )
        @spec values(h) :: [v]
        def values( hash ), do: Map.to_list(hash) |> Enum.filter_map(fn({k,_}) -> k != :__struct__ end, fn({_,v}) -> v end)
        
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
        
        # select func with special condition (func/2)
        def select_changes_kv( new_hash, old_hash, condition ), do: HashUtils.select_changes_kv( new_hash, old_hash, [], condition )
        @spec select_changes_kv(h, h, [k], (v,v -> boolean)) :: h
        def select_changes_kv( new_hash, old_hash, [] , condition) do
          Enum.reduce( HashUtils.keys(new_hash), %{}, fn(key, resmap) ->
            new_val = HashUtils.get(new_hash, key)
            case condition.(new_val, HashUtils.get(old_hash, key)) do
              true -> resmap
              false -> Map.put( resmap, key, new_val )
            end
          end )
        end
        def select_changes_kv( new_hash, old_hash, [key | rest], condition ), do: HashUtils.select_changes_kv( HashUtils.get(new_hash, key), HashUtils.get(old_hash, key), rest, condition )

        # simple select_changes func, only by keys
        @spec select_changes_k(h, h) :: h
        def select_changes_k( new_hash, old_hash ), do: HashUtils.select_changes_k( new_hash, old_hash, [] )
        @spec select_changes_k(h, h, [k]) :: h
        def select_changes_k( new_hash, old_hash, [] ), do: HashUtils.delete( new_hash, [], [:__struct__ | HashUtils.keys(old_hash)] )
        def select_changes_k( new_hash, old_hash, [key | rest] ), do: HashUtils.select_changes_k( HashUtils.get(new_hash, key), HashUtils.get(old_hash, key), rest )

        @spec plain_update(h, h) :: h
        def plain_update( hash, incoming_data ), do: plain_update( hash, [], incoming_data )
        @spec plain_update(h, [k], h) :: h
        def plain_update( hash, [], incoming_data ), do: Enum.reduce( HashUtils.keys(incoming_data), hash, fn(key, result) -> HashUtils.add( result, key, HashUtils.get(incoming_data, key)) end )
        def plain_update( hash, [key|rest], incoming_data ), do: Map.update!( hash, key, fn(inner) -> HashUtils.plain_update(inner , rest, incoming_data) end )
        
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
        
        @spec to_list(h) :: [{k,v}]
        def to_list( hash ), do: Enum.reduce( HashUtils.keys(hash), [], &([{&1, HashUtils.get(hash, &1)} | &2 ]) )

        @spec addf(h, [k,...], v) :: h
        def addf(hash, path = [_|_], val), do: addf_proc(hash, path, val)
        def addf(hash, path, val), do: (raise "HashUtils.addf : wrong path #{inspect path} to hash #{inspect hash} and val #{inspect val}")

        @spec addf_proc(h, [k], v) :: h
        defp addf_proc(hash, [first|[]], val), do: HashUtils.add(hash, first, val)
        defp addf_proc(hash, path = [first|rest], val) do
          case HashUtils.get(hash, first) do
            nil -> HashUtils.add( hash, first, HashUtils.addf( %{}, rest, val ) )
            some ->
              case HashUtils.is_hash?(some) do
                false -> (raise "HashUtils.addf : can't apply addf to not hash #{inspect some}. Path #{inspect path}, hash #{inspect hash}, val #{inspect val}")
                true -> HashUtils.add( hash, first, HashUtils.addf( some, rest, val ) )
              end
          end
        end
        

      end
    end
  end
  
end