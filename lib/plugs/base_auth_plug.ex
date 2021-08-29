defmodule ReflectPlugs.BaseAuthPlug do
  defmacro __using__(_) do
    quote do
      import Plug.Conn

      def init(default), do: default

      def call(conn, _default) do
        case extract_token(conn) do
          {:ok, token} ->
            case repo().get_by(model(), %{token: token}) do
              nil -> unauthorized(conn)
              current_user -> authorized(conn, current_user)
            end
          _ -> unauthorized(conn)
        end
      end

      defp authorized(conn, current_user) do
        conn
        |> assign(:role, role())
        |> assign(:current_user, current_user)
      end

      defp unauthorized(conn) do
        conn |> send_resp(401, "Unauthorized") |> halt()
      end

      defp extract_token(conn) do
        case Plug.Conn.get_req_header(conn, "authorization") do
          [auth_header] -> get_token_from_header(auth_header)
          _ -> {:error, :missing_auth_header}
        end
      end

      defp get_token_from_header(auth_header) do
        {:ok, reg} = Regex.compile("Token token=(.*)$", "i")
        case Regex.run(reg, auth_header) do
          [_, match] -> {:ok, String.trim(match)}
          _ -> {:error, "token not found"}
        end
      end
    end
  end
end
