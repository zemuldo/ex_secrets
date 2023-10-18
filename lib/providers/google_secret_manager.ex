defmodule ExSecrets.Providers.GoogleSecretManager do
  @moduledoc """
  Google Secret Manager provider provides secrets from an Google Secret Manager through a rest API.
  To create GCP secretb
  """

  use ExSecrets.Providers.Base

  alias ExSecrets.Utils.Config

  @process_name :ex_secrets_google_secret_manager
  @token_headers %{"Content-Type" => "application/x-www-form-urlencoded"}
  @token_uri "https://oauth2.googleapis.com/token"

  @secrets_base_uri "https://secretmanager.googleapis.com/v1/projects/PROJECT_NAME/secrets/SECRET_NAME/versions/latest:access"

  def init(_) do
    case get_access_token() do
      {:ok, data} ->
        {:ok, data |> Map.put("issued_at", get_current_epoch())}

      _ ->
        {:ok, %{}}
    end
  end

  def reset() do
    :ok
  end

  def get(name) do

    with process when not is_nil(process) <-
           GenServer.whereis(@process_name) do
      GenServer.call(@process_name, {:get, name})
    else
      nil ->
        case get_secret(name, %{}, nil) do
          {:ok, value, _} -> value
          _ -> nil
        end
    end
  end

  def handle_call({:get, name}, _from, state) do
    case get_secret(name, state, get_current_epoch()) do
      {:ok, secret, state} -> {:reply, secret, state}
      _ -> {:reply, nil, state}
    end
  end

  defp get_secret(
         name,
         %{"access_token" => access_token, "issued_at" => issued_at, "expires_in" => expires_in} =
           state,
         current_time
       )
       when issued_at + expires_in - current_time > 5 do
    with {:ok, value} <- get_secret_call(name, access_token) do
      {:ok, value, state}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  defp get_secret(name, state, _) do
    with {:ok, %{"access_token" => access_token} = new_state} <- get_access_token() ,
         {:ok, value} <- get_secret_call(name, access_token)  do
      {:ok, value, state |> Map.merge(new_state)}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  defp get_secret_call(name, access_token) do
    client = http_adpater()
    service_account_info = Config.provider_config_value(:google_secret_manager, :service_account)
    url = @secrets_base_uri |> String.replace("PROJECT_NAME", service_account_info["project_id"]) |> String.replace("SECRET_NAME", name)

    with {:ok, %{body: body, status_code: 200}} <- client.get(url, %{"Authorization" => "Bearer #{access_token}"}),
         {:ok, %{"payload" => %{"data" => data}}} <- Poison.decode(body) do
      {:ok, Base.decode64!(data)}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  defp get_access_token() do
    client = http_adpater()

    {:ok, jwt, _} = jwt()

    token_req_body = %{grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: jwt}


    with {:ok, %{body: body, status_code: 200}} <- client.post(@token_uri, URI.encode_query(token_req_body), @token_headers),
         {:ok, data} <- Poison.decode(body) do
      {:ok, data |> Map.put("issued_at", get_current_epoch())}
    else
      _ ->
        {:error, "Failed to get access token"}
    end
  end

  defp jwt do
    service_account_info = Config.provider_config_value(:google_secret_manager, :service_account)
    t = DateTime.to_unix(DateTime.utc_now())

    signer = Joken.Signer.create("RS256", %{"pem" => service_account_info["private_key"]})

    claims = %{
      "iss" => service_account_info["client_email"],
      "sub" => service_account_info["client_email"],
      "aud" => "https://oauth2.googleapis.com/token",
      "exp" => t + 1200,
      "iat" => t,
      "scope" => "https://www.googleapis.com/auth/cloud-platform"
    }

    Joken.encode_and_sign(claims, signer)
  end

  defp http_adpater() do
    Application.get_env(:ex_secrets, :http_adapter, HTTPoison)
  end

  defp get_current_epoch() do
    System.system_time(:second)
  end
  def process_name() do
    @process_name
  end
end
