defmodule PlanningPokerWeb.PageController do
  use PlanningPokerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def join(conn, %{"uuid" => uuid}) when is_binary(uuid) and uuid != "" do
    # Validate UUID format
    case uuid |> String.trim() |> validate_uuid() do
      {:ok, valid_uuid} ->
        redirect(conn, to: ~p"/poker/#{valid_uuid}")

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid poker ID format. Please enter a valid UUID.")
        |> redirect(to: ~p"/")
    end
  end

  def join(conn, _params) do
    conn
    |> put_flash(:error, "Poker ID is required")
    |> redirect(to: ~p"/")
  end

  defp validate_uuid(uuid) do
    uuid_regex = ~r/^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/

    if Regex.match?(uuid_regex, uuid) do
      {:ok, String.downcase(uuid)}
    else
      {:error, :invalid_format}
    end
  end
end
