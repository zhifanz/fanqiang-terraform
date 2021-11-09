port: 7890
socks-port: 7891
redir-port: 7892
tproxy-port: 7893
mixed-port: 7890
mode: rule
dns:
  enable: true
  listen: 0.0.0.0:53
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
rules:
  - DOMAIN-SUFFIX,google.com,auto
  - DOMAIN,ad.com,REJECT
  - GEOIP,CN,DIRECT
  - MATCH,auto
