defmodule Floki.IdsSeeder do
  def seed([]), do: 1
  def seed([h | _t]), do: h + 1
end
