$ORIGIN example.com.
$TTL 3600

; SOA Record
@       3600            IN      SOA     ns1.example.com.   hostmaster.example.com. (
                                2021012221      ; serial
                                7200            ; refresh (7200 = 2 hours)
                                3600            ; retry (3600 = 1 hour)
                                1209600         ; expire (1209600 = 2 weeks)
                                3600            ; minimum (3600 = 1 hour)
                                )

; NS Records
@       3600            IN      NS      ns1.example.com.
@       3600            IN      NS      ns2.example.com.
@       3600            IN      NS      ns3.example.com.
dyn     3600            IN      NS      ns1.example.com.
dyn     3600            IN      NS      ns2.example.com.
dyn     3600            IN      NS      ns3.example.com.

; A / AAAA Records
*                       IN      A       192.0.2.1
@                       IN      A       192.0.2.1

; Lets Encrypt challenge
;_acme-challenge IN TXT "a"
_acme-challenge         IN      CNAME           _acme-challenge.dyn.example.com.
