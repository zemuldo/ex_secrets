defmodule Utils.AwsRequest do
  alias ExSecrets.Utils.Config

  @url "https://secretsmanager.us-east-1.amazonaws.com/"
  @service :secretsmanager

  def headers(secret_name) do
    {:ok, headers} =
      Utils.Aws.headers(:post, @url, @service, config(), base_headers(), body(secret_name))

    headers
  end

  def call(secret_name) do
    with {:ok, %{body: body, status_code: status_code}} <-
           do_request(
             config(),
             :post,
             @url,
             body(secret_name),
             headers(secret_name)
           ),
         true <- status_code in [200, 201],
         {:ok, data} <- Jason.decode(body) do
      {:ok, data |> Map.get("SecretString")}
    else
      _err ->
        nil
    end
  end

  def config() do
    region = Config.provider_config_value(:aws_secret_manager, :region, "us-east-1")

    %{
      access_key_id: Config.provider_config_value(:aws_secret_manager, :access_key_id),
      secret_access_key: Config.provider_config_value(:aws_secret_manager, :secret_access_key),
      region: region
    }
  end

  def body(secret_name) do
    "{\"SecretId\":\"#{secret_name}\"}"
  end

  defp base_headers() do
    [
      {"x-amz-content-sha256", ""},
      {"x-amz-target", "secretsmanager.GetSecretValue"},
      {"content-type", "application/x-amz-json-1.1"}
    ]
  end

  def do_request(config, method, safe_url, req_body, full_headers) do
    adapter = Application.get_env(:ex_secrets, :http_adapter, HTTPoison)

    adapter.request(
      method,
      safe_url,
      req_body,
      full_headers,
      Map.get(config, :http_opts, [])
    )
    |> maybe_transform_response()
  end

  def maybe_transform_response({:ok, %{status: status, body: body, headers: headers}}) do
    # Req and Finch use status (rather than status_code) as a key.
    {:ok, %{status_code: status, body: body, headers: headers}}
  end

  def maybe_transform_response(response), do: response
end
