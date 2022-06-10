defmodule ExSecrets.Cache do

  alias ExSecrets.Cache.Store

  def pass_by(_, nil), do: nil
  def pass_by(nil, value), do: value
  def pass_by(key, value) do
    case get(key) do
      nil -> save(key, value)
      value -> value
    end
  end

  def save(key, value) do
    Store.save(key, value)
  end

  def get(key) do
    Store.get(key)
  end
end
