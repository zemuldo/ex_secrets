# ExSecrets

App config secret manager for different providers.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_secrets` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_secrets, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_secrets>.

## Basic Usage

Secrets are first fetched using system environment. If found thats the value that is used. For this, no configuration is required.

```elixir
iex(1)> ExSecrets.get("FOO")
nil
iex(2)> System.put_env "FOO", "BAR"
:ok
iex(3)> ExSecrets.get("FOO")
"BAR"
iex(4)>
```

To overide secret fetch from system environment by default, Specify your own default provider.

```elixir
iex(1)> ExSecrets.get("FOO")
nil
iex(2)> Application.put_env(:ex_secrets, :default_provider, :dot_env)
:ok
iex(3)> ExSecrets.get("FOO")
nil
iex(4)> System.put_env "FOO", "BAR"
:ok
iex(5)> ExSecrets.get("FOO")
nil
iex(7)>
```

## Supported Providers

You can configure:

- Dot env file
- Azure Keyvault
- Azure Managed Identity
- Google Secret Manager

## Provider Config

Azure KeyVault configuration:

```
  config :ex_secrets, :providers, %{
    azure_key_vault: %{
      tenant_id: "tenant-id",
      client_id: "client-id",
      client_secret: "client-secret",
      key_vault_name: "key-vault-name"
    }
  }
```

Using certificate. You can use `client_certificate_path` or `client_certificate_string`. See Azure keyvault provider section for more details

```
  config :ex_secrets, :providers, %{
    azure_key_vault: %{
      tenant_id: "tenant-id",
      client_id: "client-id",
      client_certificate_path: "/path-to/mycert.key",
      client_certificate_string: "base 64 encoded string of the cert",
      client_certificate_x5t: "x5t of the cert",
      key_vault_name: "key-vault-name"
    }
  }
```

  Azure Managed Identity Configuration:

  ```
  config :ex_secrets, :providers, %{
    azure_managed_identity: %{
      key_vault_name: "key-vault-name"
    }
  }
  ```

  Google Secret Manager

  Using service account. You can use `service_account_credentials` or `service_account_credentials_path`. See Azure keyvault provider section for more details

```
  config :ex_secrets, :providers, %{
    google_secret_manager: %{
      service_account_credentials: %{
        "type" => "service_account",
        "project_id" => "project-id",
        "private_key_id" => "key-id",
        "private_key" => "-----BEGIN PRIVATE KEY-----...-----END PRIVATE KEY-----\n",
        "client_email" => "secretaccess@project-id.iam.gserviceaccount.com",
        "client_id" => "client-id",
        "auth_uri" => "https://accounts.google.com/o/oauth2/auth",
        "token_uri" => "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url" => "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url" => "https://www.googleapis.com/robot/v1/metadata/x509/secretaccess%40project-id.iam.gserviceaccount.com",
        "universe_domain" => "googleapis.com"
        },
        service_account_credentials_path: "/path-to/cred.json"
    }
  }
```

  Dotenv file:

  ```
  config :ex_secrets, :providers, %{
    dot_env: %{path: "/path/.env"}
  }
  ```
