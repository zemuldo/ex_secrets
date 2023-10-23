defmodule ExSecrets.Providers.AzureKeyVault do
  use ExSecrets.Providers.Base

  alias ExSecrets.Utils.Config

  @scope "https://vault.azure.net/.default"

  @moduledoc """
  Azure Key Vault provider provides secrets from an [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/overview) through a rest API.

  ## Configuration

  You can configure this provider as shown below. Either `client_secret` or `client_cert_path` is required to implement authentication.
  Client `client_certificate` is recommended for security. If you provide both, `client_certificate` is used. All other config options are mandatory.
  ```
  Azure KeyVault configuration:
      config :ex_secrets, :providers, %{
        azure_key_vault: %{
          tenant_id: "tenant-id",
          client_id: "client-id",
          client_secret: "client-secret",
          client_certificate: "/path/cert.key",
          client_certificate_x5t: "x5t",
          key_vault_name: "key-vault-name"
        }
  ```

  See notes below on setting up authentication.

  ## Authentication
  The service pricipal being used must have a role that can access the secrets eg `Key Vault Secrets User`.

  ### Secret Authentication
  This is prety straing forward. See the stps below from Being Chat
  Here is a step-by-step guide to generate a secret for an app on Azure AD App Registration Secrets page:

    1. Sign in to the Azure portal.
    2. Navigate to the Azure Active Directory > App registrations > Owned applications.
    3. Select your application.
    4. Click on Certificates & secrets > Client secrets > New client secret.
    5. Type a description and an expiration for the client’s secret.
    6. Click Add.

    [For more information on generating client secrets in Azure AD, please refer to 12](https://o365info.com/create-unlimited-client-secret/)

  ### Certificate Authentication
  MacOS and many Linux distributions come with pre-compiled OpenSSL packages. You can run the following command directly from a shell to confirm if OpenSSL has already been installed.

  Create a Certificate Signing Request (.csr file) and generate a private key (.key file) using the following command:

  ```
  openssl req -newkey rsa:4096 -nodes -keyout mycert.key -batch -out mycert.csr
  ```

  This command will generate a simple CSR and download a 4096-bit private key in your current directory for self-signature.

  Next, self-sign the certificate using the private key that was just generated:
  ```
  openssl x509 -key mycert.key -in mycert.csr -req -days 3650 -out mycert.crt
  ```

  You may replace validity period 3650 with any number of days you wish. Just be aware that once the period of validity has expired, you will need to replace the certificate with a new one.

  Upload the .crt file to Azure portal using the Being Chat steps below.

  Here is a step-by-step guide to upload a certificate for an app on Azure AD App Registration Secrets page:

    1. Sign in to the Azure portal.
    2. Navigate to the Azure Active Directory > App registrations > Owned applications.
    3. Select your application.
    4. Click on Certificates & secrets > Certificates > Upload certificate.
    4. Browse to the `.crt` certificate file saved on your local machine and select it.
    5. Type a description for the certificate.
    7. Click Add.

  Finally generate the `x5t` JWT header required by Entra using the command below. See https://learn.microsoft.com/en-us/entra/identity-platform/certificate-credentials#assertion-format.
  ```
  openssl x509 -in mycert.crt -fingerprint -noout) | sed 's/SHA1 Fingerprint=//g' | sed 's/://g' | xxd -r -ps | base64
  ```
  """

  @headers %{"Content-Type" => "application/x-www-form-urlencoded"}
  @process_name :ex_secrets_azure_key_vault

  def reset() do
    :ok
  end

  def init(_) do
    case get_access_token() do
      {:ok, data} ->
        {:ok, data}

      _ ->
        {:ok, %{}}
    end
  end

  def get(name) do
    name = name |> String.split("_") |> Enum.join("-")

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

  defp token_uri(tenant_id) do
    "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token"
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
    with {:ok, %{"access_token" => access_token} = new_state} <-
           get_access_token(),
         {:ok, value} <- get_secret_call(name, access_token) do
      {:ok, value, state |> Map.merge(new_state) |> Map.put("issued_at", get_current_epoch())}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  defp get_secret_call(name, access_token) do
    client = http_adpater()
    key_vault_name = Config.provider_config_value(:azure_key_vault, :key_vault_name)

    with {:ok, %{body: body, status_code: 200}} <-
           client.get(
             "https://#{key_vault_name}.vault.azure.net/secrets/#{name}?api-version=2016-10-01",
             %{"Authorization" => "Bearer #{access_token}"}
           ),
         {:ok, %{"value" => value}} <- Poison.decode(body) do
      {:ok, value}
    else
      _ -> {:error, "Failed to get secret"}
    end
  end

  defp get_access_token() do
    client = http_adpater()
    client_secret = Config.provider_config_value(:azure_key_vault, :client_secret)
    client_certificate = Config.provider_config_value(:azure_key_vault, :client_certificate)
    tenant_id = Config.provider_config_value(:azure_key_vault, :tenant_id)

    with req_body when is_binary(req_body) <-
           build_claims_body(%{"secret" => client_secret, "cert" => client_certificate}),
         {:ok, %{body: body, status_code: 200}} <-
           tenant_id
           |> token_uri()
           |> client.post(req_body, @headers),
         {:ok, data} <- Poison.decode(body) do
      {:ok, data |> Map.put("issued_at", get_current_epoch())}
    else
      {:error, term} ->
        {:error, term}

      _ ->
        {:error, "Failed to get access token"}
    end
  end

  defp build_claims_body(%{"cert" => cert}) when is_binary(cert) do
    client_id = Config.provider_config_value(:azure_key_vault, :client_id)

    URI.encode_query(%{
      "client_id" => client_id,
      "scope" => @scope,
      "grant_type" => "client_credentials",
      "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      "client_assertion" => jwt()
    })
  end

  defp build_claims_body(%{"secret" => secret}) when is_binary(secret) do
    client_id = Config.provider_config_value(:azure_key_vault, :client_id)

    URI.encode_query(%{
      "client_id" => client_id,
      "client_secret" => secret,
      "scope" => @scope,
      "grant_type" => "client_credentials"
    })
  end

  defp build_claims_body(_), do: {:error, :no_auth}

  defp jwt() do
    client_id = Config.provider_config_value(:azure_key_vault, :client_id)
    client_certificate = Config.provider_config_value(:azure_key_vault, :client_certificate)

    client_certificate_x5t =
      Config.provider_config_value(:azure_key_vault, :client_certificate_x5t)

    tenant_id = Config.provider_config_value(:azure_key_vault, :tenant_id)
    t = DateTime.to_unix(DateTime.utc_now())

    signer =
      Joken.Signer.create("RS256", %{"pem" => File.read!(client_certificate)}, %{
        "x5t" => client_certificate_x5t
      })

    claims = %{
      "iss" => client_id,
      "sub" => client_id,
      "aud" => "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token",
      "exp" => t + 1200,
      "iat" => t
    }

    case Joken.encode_and_sign(claims, signer) do
      {:ok, jwt, _} -> jwt
      _ -> ""
    end
  end

  defp get_current_epoch() do
    DateTime.utc_now() |> DateTime.to_unix()
  end

  defp http_adpater() do
    Application.get_env(:ex_secrets, :http_adapter, HTTPoison)
  end

  def process_name() do
    @process_name
  end
end
