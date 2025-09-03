defmodule PlanningPokerWeb.Forms.JoinGameForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
    field :secret, :string, default: ""
  end

  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, [:name, :secret])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
  end
end
