defmodule PlanningPokerWeb.Forms.VotingForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :title, :string
    field :link, :string
    field :decision, :string
  end

  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, [:title, :link, :decision])
    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 200)
    |> validate_length(:link, max: 500)
    |> validate_length(:decision, max: 100)
    |> validate_url(:link)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn field, value ->
      case value do
        nil -> []
        "" -> []
        url ->
          uri = URI.parse(url)
          if uri.scheme in ["http", "https"] and uri.host do
            []
          else
            [{field, "must be a valid URL"}]
          end
      end
    end)
  end
end