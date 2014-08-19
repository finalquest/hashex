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
  def modify( hash, lst, func )
end

defimpl HashUtils, for: Map do

  def get( hash, [key | []] ) do
    Map.get( hash, key )
  end
  def get( hash, [key | rest] ) do
    HashUtils.get( Map.get( hash, key ) , rest )
  end

  def modify( hash, [key | []], func ) do
    Map.update!( hash, key, func )
  end
  def modify( hash, [key | rest], func ) do
    Map.update!( hash, key, fn(_) -> HashUtils.modify(Map.get( hash, key ) , rest, func) end )
  end

  def set( hash, lst, new_val ) do
    HashUtils.modify( hash, lst, fn(_) -> new_val end )
  end

end

defimpl HashUtils, for: List do

  def get( hash, [key | []] ) do
    hash[key]
  end
  def get( hash, [key | rest] ) do
    HashUtils.get( hash[key], rest )
  end

  def modify( hash, [key | []], func ) do
    Dict.update!( hash, key, func )
  end
  def modify( hash, [key | rest], func ) do
    Dict.update!( hash, key, fn(_) -> HashUtils.modify(Dict.get( hash, key ) , rest, func) end )
  end

  def set( hash, lst, new_val ) do
    HashUtils.modify( hash, lst, fn(_) -> new_val end )
  end

end