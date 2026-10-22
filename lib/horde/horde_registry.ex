defmodule CustomIASC.HordeRegistry do
  use Horde.Registry

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    init_arg = Keyword.put_new(opts, :keys, :unique)
    Horde.Registry.start_link(__MODULE__, init_arg, name: name)
  end

  def init(init_arg) do
    name = Keyword.fetch!(init_arg, :name)

    [members: members(name)]
    |> Keyword.merge(init_arg)
    |> Horde.Registry.init()
  end

  defp members(name) do
    Enum.map(Node.list([:this, :visible]), &{name, &1})
  end
end
