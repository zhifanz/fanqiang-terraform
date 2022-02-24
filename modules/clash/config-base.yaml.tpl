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
rules:
  - DOMAIN-SUFFIX,google.com,auto
  - GEOIP,CN,DIRECT
  %{~ for e in config.proxies.others ~}
  - GEOIP,${upper(e.continent)},${e.continent}
  %{~ endfor ~}
  - MATCH,auto
