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
    server: ${server}
    port: ${auto_port}
    cipher: ${cipher}
    password: ${password}
  %{~ for e in continent_rules ~}
  - name: ${e.continent}
    type: ss
    server: ${server}
    port: ${e.port}
    cipher: ${cipher}
    password: ${password}
  %{~ endfor ~}
rule-providers:
  domestic:
    type: http
    behavior: domain
    path: ./${basename(domestic_rule_provider_url)}
    url: ${domestic_rule_provider_url}
    interval: 60
  %{~ for e in continent_rules ~}
  ${e.continent}:
    type: http
    behavior: classical
    path: ./${basename(e.rule_provider_url)}
    url: ${e.rule_provider_url}
  %{~ endfor ~}
rules:
  - DOMAIN-SUFFIX,google.com,auto
  - DOMAIN,ad.com,REJECT
  - RULE-SET,domestic,DIRECT
  - GEOIP,CN,DIRECT
  %{~ for e in continent_rules ~}
  - RULE-SET,${e.continent},${e.continent}
  %{~ endfor ~}
  - MATCH,auto
