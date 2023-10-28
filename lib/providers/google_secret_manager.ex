defmodule ExSecrets.Providers.GoogleSecretManager do
  @moduledoc """
  Google Secret Manager provider provides secrets from an Google Secret Manager through a rest API.

  ### Configuration

  Using the Service Account Credentials File
  ```
  Application.put_env(:ex_secrets, :providers, %{
      google_secret_manager: %{
        service_account_credentials_path: ".temp/cred.json"
      }
    })

  ```

  Using the json file contents

  ```
  Application.put_env(:ex_secrets, :providers, %{
      google_secret_manager: %{
        service_account_credentials: %{
        "type" => "service_account",
        "project_id" => "project-id",
        "private_key_id" => "keyid",
        "private_key" => "-----BEGIN PRIVATE KEY-----...-----END PRIVATE KEY-----\n",
        "client_email" => "secretaccess@project-id.iam.gserviceaccount.com",
        "client_id" => "client-id",
        "auth_uri" => "https://accounts.google.com/o/oauth2/auth",
        "token_uri" => "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url" => "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url" => "https://www.googleapis.com/robot/v1/metadata/x509/secretaccess%40project-id.iam.gserviceaccount.com",
        "universe_domain" => "googleapis.com"
        }
      }
    })
  ```
  """

  use ExSecrets.Providers.Base

  alias ExSecrets.Utils.Config

  @process_name :ex_secrets_google_secret_manager
  @token_headers %{"Content-Type" => "application/x-www-form-urlencoded"}
  @token_uri "https://oauth2.googleapis.com/token"

  @secrets_base_uri "https://secretmanager.googleapis.com/v1/projects/PROJECT_NAME/secrets/SECRET_NAME/versions/latest:access"

  def init(_) do
    with {:ok, cred} <- get_service_account_credentials(),
         {:ok, data} <- get_access_token(cred) do
      {:ok, data |> Map.put("issued_at", get_current_epoch())}
    else
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

  def set(_name, _value) do
    {:error, "Not implemented"}
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
    with {:ok, value} <- get_secret_call(name, access_token, state.cred),
         true <- is_binary(value) do
      {:ok, value, state}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  defp get_secret(name, state, _) do
    with {:ok, cred} <- get_service_account_credentials(),
         {:ok, %{"access_token" => access_token} = new_state} <- get_access_token(cred),
         {:ok, value} <- get_secret_call(name, access_token, cred) do
      {:ok, value, state |> Map.merge(new_state)}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  defp get_secret_call(name, access_token, cred) do
    client = http_adpater()

    url =
      @secrets_base_uri
      |> String.replace("PROJECT_NAME", cred["project_id"])
      |> String.replace("SECRET_NAME", name)

    with {:ok, %{body: body, status_code: 200}} <-
           client.get(url, %{"Authorization" => "Bearer #{access_token}"}),
         {:ok, %{"payload" => %{"data" => data}}} <- Poison.decode(body) do
      {:ok, Base.decode64!(data)}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  defp get_access_token(cred) do
    client = http_adpater()

    token_req_body = %{
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt(cred)
    }

    with {:ok, %{body: body, status_code: 200}} <-
           client.post(@token_uri, URI.encode_query(token_req_body), @token_headers),
         {:ok, data} <- Poison.decode(body) do
      {:ok, data |> Map.put("issued_at", get_current_epoch())}
    else
      _ ->
        {:error, "Failed to get access token"}
    end
  end

  defp get_service_account_credentials() do
    path = Config.provider_config_value(:google_secret_manager, :service_account_credentials_path)
    cred = Config.provider_config_value(:google_secret_manager, :service_account_credentials)

    cond do
      is_map(cred) ->
        {:ok, cred}

      is_binary(path) ->
        get_cred_from_path(path)

      true ->
        {:error, :no_auth}
    end
  end

  defp get_cred_from_path(path) do
    with {:ok, s} <- File.read(path),
         {:ok, cred} <- Poison.decode(s) do
      {:ok, cred}
    else
      _ -> {:error, :no_auth}
    end
  end

  defp jwt(cred) do
    t = DateTime.to_unix(DateTime.utc_now())

    signer = Joken.Signer.create("RS256", %{"pem" => cred["private_key"]})

    claims = %{
      "iss" => cred["client_email"],
      "sub" => cred["client_email"],
      "aud" => "https://oauth2.googleapis.com/token",
      "exp" => t + 1200,
      "iat" => t,
      "scope" => "https://www.googleapis.com/auth/cloud-platform"
    }

    case Joken.encode_and_sign(claims, signer) do
      {:ok, jwt, _} -> jwt
      _ -> ""
    end
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
