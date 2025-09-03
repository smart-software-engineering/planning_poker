defmodule PlanningPoker.Poker.Poker do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "poker" do
    field :name, :string
    field :description, :string
    field :secret, :string, virtual: true
    field :secret_hashed, :string
    field :moderator_email, :string
    field :card_type, :string, default: "fibonacci"
    field :all_moderators, :boolean, default: true

    has_many :votings, PlanningPoker.Poker.Voting, preload_order: [asc: :position]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(poker, attrs) do
    poker
    |> cast(attrs, [:name, :description, :secret, :moderator_email, :card_type, :all_moderators])
    |> validate_required([:name, :all_moderators])
    |> validate_inclusion(:card_type, ["fibonacci", "t-shirt"])
    |> validate_format(:moderator_email, ~r/^[^\s]+@[^\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> hash_secret_if_present()
  end

  defp hash_secret_if_present(changeset) do
    case get_change(changeset, :secret) do
      nil -> 
        changeset
      "" -> 
        changeset
      secret when is_binary(secret) ->
        # Hash the secret with lower rounds in test environment
        rounds = Application.get_env(:bcrypt_elixir, :log_rounds, 12)
        hashed_secret = apply(Bcrypt, :hash_pwd_salt, [secret, [rounds: rounds]])
        changeset
        |> put_change(:secret_hashed, hashed_secret)
        |> delete_change(:secret)
    end
  end

  def verify_secret(poker, secret) when is_binary(secret) and secret != "" do
    case poker.secret_hashed do
      nil -> false
      hash -> apply(Bcrypt, :verify_pass, [secret, hash])
    end
  end

  def verify_secret(_, _), do: false
end
