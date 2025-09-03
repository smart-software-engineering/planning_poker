defmodule PlanningPokerWeb.GameLive do
  use PlanningPokerWeb, :live_view

  alias PlanningPoker.Poker
  alias PlanningPokerWeb.Forms.JoinGameForm

  # Get the PokerServer implementation from config
  @game_server Application.compile_env(:planning_poker, :game_server)

  def mount(%{"id" => id}, _session, socket) do
    case Poker.get_poker(id) do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/")}

      game ->
        # Subscribe to game updates (only for real PokerServer, not test)
        unless @game_server == PlanningPoker.PokerServerTest do
          Phoenix.PubSub.subscribe(PlanningPoker.PubSub, "game:#{id}")
        end

        # Find or start the PokerServer using injected implementation
        case @game_server.find_or_start(id) do
          :ok ->
            {:ok,
             socket
             |> assign(:page_title, game.name)
             |> assign(:game_id, id)
             |> assign(:game, game)
             |> assign(:user_identified, false)
             |> assign(:user_name, nil)
             |> assign(:user_role, :user)
             |> assign(:users, %{})
             |> assign(:game_state, nil)
             |> assign(:identification_form, to_form(JoinGameForm.changeset(%JoinGameForm{}), as: :join_game_form))}

          {:error, reason} ->
            {:ok,
             socket
             |> put_flash(:error, "Failed to start game session: #{inspect(reason)}")
             |> push_navigate(to: ~p"/")}
        end
    end
  end

  def handle_event("identify_user", %{"join_game_form" => form_params}, socket) do
    %{game: game, game_id: game_id} = socket.assigns
    
    changeset = JoinGameForm.changeset(%JoinGameForm{}, form_params)
    
    if changeset.valid? do
      data = Ecto.Changeset.apply_changes(changeset)
      user_name = String.trim(data.name)
      secret = String.trim(data.secret)

      # Determine role based on all_moderators flag or secret
      case determine_user_role(game, secret) do
        {:ok, role} ->
          handle_user_identification(socket, game_id, user_name, role)
        
        {:error, :invalid_secret} ->
          {:noreply, put_flash(socket, :error, "Invalid moderator secret")}
      end
    else
      {:noreply, assign(socket, :identification_form, to_form(changeset, as: :join_game_form))}
    end
  end

  def terminate(_reason, socket) do
    # Remove user from PokerServer when LiveView terminates
    if socket.assigns[:user_identified] && socket.assigns[:user_name] do
      @game_server.remove_user(socket.assigns.game_id, socket.assigns.user_name)
    end

    :ok
  end

  # Handle PubSub messages
  def handle_info({:user_joined, user_name, _user_role}, socket) do
    # Update users list when someone joins
    case @game_server.get_users(socket.assigns.game_id) do
      {:ok, users} ->
        {:noreply,
         socket
         |> assign(:users, users)
         |> put_flash(:info, "#{user_name} joined")}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info({:user_left, user_name}, socket) do
    # Update users list when someone leaves
    case @game_server.get_users(socket.assigns.game_id) do
      {:ok, users} ->
        {:noreply,
         socket
         |> assign(:users, users)
         |> put_flash(:info, "#{user_name} left")}

      _ ->
        {:noreply, socket}
    end
  end

  # Private helper to handle user identification and reduce nesting
  defp handle_user_identification(socket, game_id, user_name, role) do
    # Add user using injected PokerServer implementation
    case @game_server.add_user(game_id, user_name, role) do
      :ok ->
        handle_successful_user_addition(socket, game_id, user_name, role)

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to join game: #{inspect(reason)}")}
    end
  end

  # Private helper to handle successful user addition
  defp handle_successful_user_addition(socket, game_id, user_name, role) do
    case @game_server.get_game_state(game_id) do
      {:ok, game_state} ->
        welcome_message =
          "Welcome#{if role == :moderator, do: " moderator", else: ""}, #{user_name}!"

        {:noreply,
         socket
         |> assign(:user_identified, true)
         |> assign(:user_name, user_name)
         |> assign(:user_role, role)
         |> assign(:game_state, game_state)
         |> assign(:users, game_state.users)
         |> put_flash(:info, welcome_message)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to load game state: #{inspect(reason)}")}
    end
  end

  # Determine user role based on game settings
  defp determine_user_role(game, secret) do
    cond do
      game.all_moderators -> 
        {:ok, :moderator}
      
      secret == "" ->
        {:ok, :user}
      
      Poker.Poker.verify_secret(game, secret) ->
        {:ok, :moderator}
      
      true ->
        {:error, :invalid_secret}
    end
  end
end
