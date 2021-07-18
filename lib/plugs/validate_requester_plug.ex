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

  def init(default), do: default

  def call(conn, _) do
    requester_type = conn.params["requester_type"]
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
    tokenKey = System.get_env("REFLECT_AUTH_TOKEN_HEADER")
    case Enum.find_value(conn.req_headers, fn {key, val} -> if key == tokenKey, do: val end)  do
      nil -> {:error, :missing_auth_header}
      reflect_auth_token -> {:ok, reflect_auth_token}
    end
  end
end
