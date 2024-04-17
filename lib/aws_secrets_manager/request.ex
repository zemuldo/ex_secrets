defmodule Utils.AwsRequestBuilder do
  alias ExSecrets.Utils.Config

  @url "https://secretsmanager.us-east-1.amazonaws.com/"
  @service :secretsmanager

  def headers(secret_name) do
    {:ok, headers} =
      Utils.Aws.headers(:post, @url, @service, config(), base_headers(), body(secret_name))

    headers
  end

  def call(secret_name) do
    {:ok, headers} =
      Utils.Aws.headers(:post, @url, @service, config(), base_headers(), body(secret_name))

    HTTPoison.post(@url, body(secret_name), headers)
  end

  def config() do
    region = Config.provider_config_value(:aws_secret_manager, :region, "us-east-1")

    %{
      port: 443,
      scheme: "https://",
      host: "secretsmanager.#{region}.amazonaws.com",
      json_codec: Jason,
      http_client: ExAws.Request.Hackney,
      access_key_id: Config.provider_config_value(:aws_secret_manager, :access_key_id),
      secret_access_key: Config.provider_config_value(:aws_secret_manager, :secret_access_key),
      region: region,
      retries: [max_attempts: 10, base_backoff_in_ms: 10, max_backoff_in_ms: 10000],
      normalize_path: true,
      require_imds_v2: false
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

  def do_request(config, method, safe_url, req_body, full_headers, attempt, service) do
    telemetry_event = Map.get(config, :telemetry_event, [:ex_secrets, :request])
    telemetry_options = Map.get(config, :telemetry_options, [])

    telemetry_metadata = %{
      options: telemetry_options,
      attempt: attempt,
      service: service,
      request_body: req_body,
      operation: extract_operation(full_headers)
    }

    adapter = Application.get_env(:ex_secrets, :http_adapter, HTTPoison)

    :telemetry.span(telemetry_event, telemetry_metadata, fn ->
      result =
        adapter.request(
          method,
          safe_url,
          req_body,
          full_headers,
          Map.get(config, :http_opts, [])
        )
        |> maybe_transform_response()

      stop_metadata =
        case result do
          {:ok, %{status_code: status} = resp} when status in 200..299 or status == 304 ->
            %{result: :ok, response_body: Map.get(resp, :body)}

          error ->
            %{result: :error, error: extract_error(error)}
        end

      telemetry_metadata = Map.merge(telemetry_metadata, stop_metadata)
      {result, telemetry_metadata}
    end)
  end

  defp extract_operation(headers), do: Enum.find_value(headers, &match_operation/1)
  defp match_operation({"x-amz-target", value}), do: value
  defp match_operation({_key, _value}), do: nil
  def maybe_transform_response({:ok, %{status: status, body: body, headers: headers}}) do
    # Req and Finch use status (rather than status_code) as a key.
    {:ok, %{status_code: status, body: body, headers: headers}}
  end

  def maybe_transform_response(response), do: response
  defp extract_error({:ok, %{body: body}}), do: body
  defp extract_error({:ok, response}), do: response
  defp extract_error({:error, error}), do: error
  defp extract_error(error), do: error
end
