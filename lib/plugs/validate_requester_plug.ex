defmodule ReflectPlugs.ValidateRequesterPlug do
  @moduledoc """
  Documentation for `ReflectPlugs`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ReflectPlugs.hello()
      :world

  """
  import Plug.Conn

  alias Services.ValidateTokenService

  @reflect_token_header System.get_env("REFLECT_AUTH_TOKEN_HEADER")

  def init(default), do: default

  def call(conn, %{"requester_type" => requester_type}) do
    case get_token(conn) do
      {:ok, token} ->
        case ValidateTokenService.validate(requester_type, token) do
          {:ok, response} when response.status == 200 -> authorized(conn)
          nil -> unauthorized(conn)
        end

      _ ->
        unauthorized(conn)
    end
  end

  defp authorized(conn) do
    conn
    |> assign(:is_valid_reflect_auth_token, :true)
  end

  defp unauthorized(conn) do
    conn |> send_resp(401, "Unauthorized") |> halt()
  end

  defp get_token(conn) do
    case Plug.Conn.get_req_header(conn, @reflect_token_header) do
      [reflect_auth_token] -> {:ok, reflect_auth_token}
      _ -> {:error, :missing_auth_header}
    end
  end
end
