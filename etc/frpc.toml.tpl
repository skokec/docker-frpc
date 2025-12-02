# Generated automatically by docker-gen

serverAddr = "{{ when (not .Env.FRPC_SERVER_ADDRESS) "127.0.0.1" .Env.FRPC_SERVER_ADDRESS }}"
serverPort = {{ when (not .Env.FRPC_SERVER_PORT) "7000" .Env.FRPC_SERVER_PORT }}
loginFailExit = false

{{if .Env.FRPC_LOGFILE }}
[log]
to = "{{ .Env.FRPC_LOGFILE }}"
# trace, debug, info, warn, error
level = "{{ when (not .Env.FRPC_LOG_LEVEL) "warn" .Env.FRPC_LOG_LEVEL }}"
maxDays = {{ when (not .Env.FRPC_LOG_DAYS) "5" .Env.FRPC_LOG_DAYS }}
{{end}}

[auth]
method = "token"
token = "{{ when (not .Env.FRPC_AUTH_TOKEN) "abcdefghi" .Env.FRPC_AUTH_TOKEN }}"

{{if and .Env.FRPC_ADMIN_USER .Env.FRPC_ADMIN_PWD }}
# set admin address for control frpc's action by http api such as reload (we do not expose this port)
[webServer]
addr = "{{ when (not .Env.FRPC_ADMIN_ADDRESS) "127.0.0.1" .Env.FRPC_ADMIN_ADDRESS }}"
port = {{ when (not .Env.FRPC_ADMIN_PORT) "7400" .Env.FRPC_ADMIN_PORT }}
user = "{{ .Env.FRPC_ADMIN_USER }}"
password = "{{ .Env.FRPC_ADMIN_PWD }}"
{{end}}

[transport]
# connections will be established in advance, default value is zero
poolCount = {{ when (not .Env.FRPC_POOL_COUNT) "5" .Env.FRPC_POOL_COUNT }}
tcpMux = {{ when (not .Env.FRPC_TCP_MUX) "true" .Env.FRPC_TCP_MUX }}

[transport.tls]
enable = true

{{ $frpc_prefix := when (not .Env.FRPC_PREFIX) "frp" .Env.FRPC_PREFIX }}

{{ $work_network := when (not .Env.FRPC_NETWORK) "default" .Env.FRPC_NETWORK }}

{{ range $container := whereLabelValueMatches $ "frp.enabled" "true" }}
{{ if $container.Networks }}
{{ $network := first (where $container.Networks "Name" $work_network ) }}

{{ if ($network) }}

{{ $name := $container.Name }}
{{ $id := $container.ID }}
{{ $notify_email := index $container.Labels (printf "frp.notify_email") }} 

{{ range $address := $container.Addresses }}
{{ $service_type := index $container.Labels (printf "frp.%s" $address.Port) }}
{{ $secret_key := index $container.Labels (printf "frp.%s.secret" $address.Port) }}
{{ $encryption := index $container.Labels (printf "frp.%s.encryption" $address.Port) }}
{{ $subdomain := index $container.Labels (printf "frp.%s.http.subdomain" $address.Port) }}
{{ $domains := index $container.Labels (printf "frp.%s.http.domains" $address.Port) }}
{{ $locations := index $container.Labels ( printf "frp.%s.http.locations" $address.Port) }}
{{ $rewrite := index $container.Labels (printf "frp.%s.http.rewrite" $address.Port) }}
{{ $httpuser := index $container.Labels ( printf "frp.%s.http.username" $address.Port) }}
{{ $httppwd := index $container.Labels ( printf "frp.%s.http.password" $address.Port) }}
{{ $healthcheck := index $container.Labels ( printf "frp.%s.health_check" $address.Port) }}
{{ $healthcheck := when ( or (or (eq $healthcheck "") (eq $healthcheck "true" )) (or (eq $healthcheck "True" ) (eq $healthcheck "1" )) )  true false }}
{{ if $service_type }}

[[proxies]]
name = "{{ print $frpc_prefix "_" $name "_" $address.Port }}"
type = "{{ $service_type }}"
localIP = "{{ $network.IP }}"
localPort = {{ $address.Port }}

{{ if $encryption }}
[proxies.transport]
useEncryption = true
{{ end }}

{{ if $healthcheck }}
[proxies.healthCheck]
type = "{{ $service_type }}"
timeoutSeconds = 3
intervalSeconds = 60
{{ end }}

{{ if or (eq $service_type "http") (eq $service_type "https") }}

{{ if and $httpuser $httppwd }}
httpUser = "{{ $httpuser }}"
httpPassword = "{{ $httppwd }}"
{{ end }}

{{ if $subdomain }}
subdomain = "{{ $subdomain }}"
{{ end }}

{{ if $domains }}
customDomains = [{{ $domains }}]
{{ end }}

{{ if $locations }}
locations = [{{ $locations }}]
{{ end }}

{{ if $rewrite }}
hostHeaderRewrite = "{{ $rewrite }}"
{{ end }}

[proxies.healthCheck]
type = "http"
path = "/"

{{ else }}
{{ if eq $service_type "stcp" }}
secretKey = "{{ $secret_key }}"

{{ else }}
# Allocate random free port
remotePort = 0
{{ end }}
{{ end }}

{{ if $notify_email }}
# Provide metadata for notifier plugin
[proxies.metadatas]
frpc_prefix = "{{ $frpc_prefix }}"
local_port = "{{ $address.Port }}"
{{ if  $notify_email }}
notify_email = "{{ $notify_email }}"
{{ end }}

{{ end }}

{{ end }}
{{ end }}
{{ end }}
{{ end }}
{{ end }}
