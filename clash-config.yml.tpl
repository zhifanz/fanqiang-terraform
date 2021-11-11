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
    port: ${port}
    cipher: ${cipher}
    password: ${password}
rule-providers:
  domestic:
    type: http
    behavior: domain
    path: ./direct_domains.yaml
    url: ${domestic_rule_provider_url}
rules:
  - RULE-SET,domestic,DIRECT
  - DOMAIN-SUFFIX,google.com,auto
  - DOMAIN,ad.com,REJECT
  - GEOIP,CN,DIRECT
  - MATCH,auto
