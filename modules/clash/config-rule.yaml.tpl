mixed-port: 7890
mode: rule
tun:
  enable: true
  stack: system
  macOS-auto-route: true
  macOS-auto-detect-interface: true
dns:
  enable: true
  listen: 0.0.0.0:1053
  enhanced-mode: redir-host
  nameserver:
    - 223.5.5.5
    - 119.29.29.29
    - 114.114.114.114
    - tls://dns.rubyfish.cn:853
proxies:
  - name: auto
    type: ss
    server: ${config.proxies.auto.server}
    port: ${config.proxies.auto.port}
    cipher: ${config.cipher}
    password: ${config.password}
  %{~ for e in config.proxies.others ~}
  - name: ${e.continent}
    type: ss
    server: ${e.server}
    port: ${e.port}
    cipher: ${config.cipher}
    password: ${config.password}
  %{~ endfor ~}
rule-providers:
  domestic:
    type: http
    behavior: domain
    path: ./${basename(domestic_rule_provider_url)}
    url: ${domestic_rule_provider_url}
    interval: 300
  %{~ for i, e in config.proxies.others ~}
  ${e.continent}:
    type: http
    behavior: domain
    path: ./${basename(other_rule_provider_urls[i])}
    url: ${other_rule_provider_urls[i]}
    interval: 300
  %{~ endfor ~}
rules:
  - DOMAIN-SUFFIX,google.com,auto
  - DOMAIN,ad.com,REJECT
  - RULE-SET,domestic,DIRECT
  %{~ for e in config.proxies.others ~}
  - RULE-SET,${e.continent},${e.continent}
  %{~ endfor ~}
  - MATCH,auto
