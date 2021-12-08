# Tunnel Proxy Auto Deployment by Terraform

This project contains terraform configuration files to create tunnel proxy infrastructures on Aliyun and AWS

## Architecture

```
    --------------    --------------    --------------
   | proxy-eu-aws |  | proxy-us-aws |  | proxy-ap-aws |
    --------------    --------------    --------------
           |                 |                 |
            -----------------|-----------------
                             | <--- GEOIP based routing
                     ------------------
                    | tunnel-cn-aliyun |
                     ------------------
                             |
                             | <--- rule based conditional proxy
                             |
         -------------------------------------------
        | Clients:                                  |
        |  ---------   -----   ---------   -------  |
        | | Android | | iOS | | Windows | | MacOS | |
        |  ---------   -----   ---------   -------  |
         -------------------------------------------
```

## Inputs

| Name | Description |
|------|-------------|
| client_region | Aliyun region (city) where end user lives |
| password | used to protect proxy from anonymous user, as complex as possible |
| encryption_algorithm | shadowsocks encryption algorithm |
| bucket | AWS bucket name, must be unique |
| domain_access_timeout_in_seconds | how long can you wait for a web page to open |
| public_key | just for login and debugging |
