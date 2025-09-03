defmodule PlanningPokerWeb.Forms.JoinPokerForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
  end

  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
  end
end
