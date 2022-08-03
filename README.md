# CoreDNS-DynDNS

This repository holds some basic configurations to enable dynamic DNS updates in an authorative DNS-Server running [CoreDNS](https://github.com/coredns/coredns) without implementing a custom plugin.
Therefore, this repsoitory "simulates" a [DynDNSv2](https://stackoverflow.com/questions/54039095/dyndns2-protocol-specification) endpoint.  
Keep in mind that this is kind of a blueprint and not necessary production-ready.


## How does it work?

CoreDNS is able to reread configuration and zone files on changes.
This project provides a quite simple way to update such a zone file via a [webhook](https://github.com/adnanh/webhook).
Most *decent* routers allow to specify a custom URL with basic auth to send IP updates to.
The webhook provides such a URL and triggers a sh script that updates the dynamic zone file and boom - your dynamic IP updates are done.

**In short (step-by-step):**
1. The client receives a new dynamic IP address.
1. The client sends a [cURL](https://curl.se/) query to the webhook container containing the new IP address.
1. The webhook container triggers the sh script.
1. The sh script updates the CoreDNS zone file --> Includes the new IP address and updates serial.
1. CoreDNS automatically reloads the zone file and serves the new IP address.

**Please notice:**  
The sh script checks if the provided parameter is a valid IPv4 address using a regex.
Currently, the updating of IPv6 addresses is **not** supported.


## Configuration

A [Docker-Compose](https://docs.docker.com/compose/) stack is used for the example configuration.
Feel free to adapt the needed steps to, e.g., a native installation (with binaries) (although Docker-Compose is running just fine for my personal setup).

- Adapt [htpasswd](./config/dynamic) to your needs. You need at least one valid entry with a *username:password* combination. The file is prefilled with the credential `example:0123456789` - Do not forget to change/remove that!
    - This file will be used by an nginx container to provide basic authentification.
- Adapt [db.example.com](./config/zones/example.com/db.example.com) to match your root domain zone. In most cases, you already have such a file and can change the needed parameters in that. The needed parameters are already prefilled in the example file:
    - Three nameserver records for the root zone `example.com` --> These values will not change at all.
    - Three nameserver records for the dynamic zone `dyn.example.com` --> This is the zone that will be updated by web hooks. The records deligate all queries from DNS clients to the CoreDNS server specified for this zone. (It then will handle all DNS queries for the dynamic zone.)
        - In this example, the root zone will also be served by your CoreDNS server. Keep in mind that this is absolutely not neccessary! You just have to deligate the dynamic zone.
- Copy [db.example.com.dyn.template](./config/zones/example.com/db.example.com.dyn) to `db.example.com.dyn`. (This ensures that git does not track your dynamic updates.)
- Use `db.example.com.dyn` to create the dynamic zone. This file will get updated via the sh script.
- Please notice: At least, you have to change all occurences of `example.com` to your own domain in all config/zone files!

After you've adapted the configuration files to your needs, start the Docker-Compose stack:
`$ docker-compose up -d`

Hint: Mostly, you want to use the stack behind a reverse proxy such as nginx secured with a SSL/TLS certificate.
For an easy to use reverse proxy for Docker containers, check out [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) with its [config examples](https://github.com/nginx-proxy/acme-companion/blob/main/docs/Docker-Compose.md).


### OPNsense client example

This example can easily be used to update a dynamic zone with your [OPNsense](https://opnsense.org/) router.

In your OPNsense box go to *Services* --> *Dynamic DNS* and click on *(+) Add*.  
Configure the following settings:

| Field                  | Value           | Explanation                                                                            |
| ---------------------- | --------------- | -------------------------------------------------------------------------------------- |
| *Enable*               | Checked         | Enables this update client                                                             |
| *Service type*         | Custom          | -                                                                                      |
| *Protocol*             | DynDns2         | Sets URL to smth. like *https://host/nic/update?hostname=dyn.example.com&ip=192.0.2.1* |
| *Username*             | example         | Your username for basic auth from *htpasswd*                                           |
| *Password*             | 0123456789      | Your password for basic auth from *htpasswd*                                           |
| *Wildcard*             | Unchecked       | -                                                                                      |
| *Hostname(s)*          | dyn.example.com | Your dynamic zone to update                                                            |
| *Check ip method*      | Interface       | You can also use some of the other provided methods                                    |
| *Force SSL*            | Checked         | Uses HTTPS instead of HTTP                                                             |
| *Interface to monitor* | E.g., *WAN*     | Interface on which the dynamic IP occurs                                               |
| *Description*          |                 | -                                                                                      |
