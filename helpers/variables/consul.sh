
# Register the resolver
# Default is to prepend the resolver, so it can resolve first
kitbash.vars.register_resolver kitbash.vars.from_consul

# kitbash.vars.from_consul
# Usage: kitbash.vars.from_consul NAME PREFIX
# Looks up NAME from Consul K/V
kitbash.vars.from_consul() {
  local name="$1"
  local ns_prefix="${2:-kitbash}"
  [[ -n "${KIT_NAME:-}" ]] && ns_prefix+="/$KIT_NAME"
  local key="${ns_prefix}/${name}"

  # Prefer the Consul binary, fallback to curl
  if command -v consul >/dev/null 2>&1; then
    consul kv get -http-addr="${CONSUL_HTTP_ADDR:-http://127.0.0.1:8500}" \
      ${CONSUL_HTTP_TOKEN:+-token="$CONSUL_HTTP_TOKEN"} \
      "$key" 2>/dev/null || true
    return
  fi

  if command -v curl >/dev/null 2>&1; then
    local header_opts=()
    [[ -n "${CONSUL_HTTP_TOKEN:-}" ]] && header_opts=(-H "X-Consul-Token: $CONSUL_HTTP_TOKEN")
    curl -fsSL "${header_opts[@]}" \
      "${CONSUL_HTTP_ADDR:-http://127.0.0.1:8500}/v1/kv/${key}?raw" 2>/dev/null || true
  fi
}

