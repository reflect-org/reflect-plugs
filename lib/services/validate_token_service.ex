defmodule Services.ValidateTokenService do
  def validate(requester_type, token) do
    Tesla.get(
      client(requester_type, token),
      "#{requester_type}/validate_token"
    )
  end

  defp client(requester_type, token) do
    appUrl = System.get_env("REFLECT_#{String.upcase(requester_type)}_URL")

    case appUrl do
      nil ->
        nil

      baseUrl ->
        middleware = [
          {Tesla.Middleware.BaseUrl, baseUrl},
          Tesla.Middleware.JSON,
          {Tesla.Middleware.Headers, [{"authorization", "Token token=" <> token}]}
        ]

        Tesla.client(middleware)
    end
  end
end
