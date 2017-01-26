## Configuring HTTPS

### Transport Layer Security (TLS)
Transport Layer Security (TLS) is a method for encrypting net coms. TLS is the successor to Secure Sockets Layer (SSL). TLS allows a client to verify the identity of the server and optionally allows the server to verify the identity of the client.

TLS is based around the concepts of certificates. A certificate has multiple parts: a public key, server identity, and a signature from a certificate authority. The corresponding private key is never made public. Any data encrypted w/ the pvt key can only be decrypted w/ the public key and vice versa. 

During the initial handshake, when setting up the enc con, the client and server agree on a set of enc ciphers supported by both the server and the client and they exchange bits of random data. The client uses this random data to generate a session key, a key that will be used for much faster symmetric encryption, where the same key is used for both enc and decryption. To make sure that this key is not compromised, it is sent to the server enc w/ the server's pub key (part of the server cert). 

1. The client initiates a con to the server w/ a ClientHello msg. As part of this msg, the client sends a 32-byte random number including a timestamp, and a list of enc protocols and ciphers supported by the client.
2. The server responds w/ a ServerHello msg, containing another 32-byte random number w/ a timestamp, and the enc protocol and ciphers the client should use. The server also sends the server cert, which consists of a pub key, general server identity information like the FQDN and a signature from a trusted certificate authority (CA). This cert can also include the pub cert ofr all cert authorities that have signed teh cert, up to a root CA.
3. The client verifies the server cert by checking if the supplied identity info matches and by verifying all sigs, checking if they are made by a CA trusted by the client. If the cert verifies the client creates a session key using the random numbers previously exchanged. The client then encrypts this session key using the pub key from the server cert and sends it to the server using a ClientKeyExchange msg.
4. The server decrypts the session key adn the client and server both start enc and decr all data sent over the con using the session key.

Note: This is a simplification of the actual protocol; for ex, the actual session key never gets transmitted w/ many cipher suites, not even in enc form. The server and client both create a pre-master key which gets exchanged, and both the server and client calculate the actual session key from that one. During the negotiations, both the server and client also use a variety of methods to ensure against replay and man-in-the-middle attacks.

### Configuring TLS certificates
To configure a virt host w/ TLS:
1. Obtain a signed cert
2. Install httpd
3. Config vhost to use TLS, using the certs obtained in #2

#### Obtaining a certificate
When obtaining a certificate, there are two options: creating a self-signed certificate (a certificate signed by itself, not an actual CA), or creating a certificate request and having a reputable CA sign that request so it becomes a certificate.

The *crypto-utils* pkg contains a utility callend *genkey* that supports both methods. To create a cert (signing request) w/ genkey, run the following cmd:
```
genkey <FQDN>
```

During the creation, genkey will ask for the desired key size (choose at least 2048 bits), if a signing request should be made (answering no will create a self-signed cert), whether the pvt key should be protected w/ a passphrase and general info about the id of the server.

A few files are created:
- /etc/pki/tls/private/<fqdn>.key: This is the pvt key. The private key should be kept at 0600 or 0400 perms, and SELinux context of cert_t. This key file should never be shared w/ the outside world
- /etc/pki/tls/certs/<fqdn>.0.csr: This file is only generated if you requested a signing request. This is the file that you send to your CA to get it signed. You never need to send the pvt key to your CA
- /etc/pki/tls/certs/<fqdn>.crt: This is the public cert. This file is only generated when a self-signed cert is requested. If a signing request was requested and sent to a CA, this is the file that will be returned from the CA. Permissions should be kept at 0644, w/ an SELinux context of cert_t

#### Install HTTPD Mods
HTTPD needs an extension module to be installed to activate TLS support. On RHEL, you can install this module using the *mod_ssl* pkg.

This pkg will automatically enable httpd for a default vhost listening on port 443/TCP. This default vhost is configured in the file /etc/httpd/conf.d/ssl.conf.

#### Configure a vhost w/ TLS
Vhosts w/ TLS are configured in the same way as reg vhosts w/ some additional parameters. It is possible to use name based vhosting w/ TLS, but some older browsers are not compatible w/ this approach.

The following is a simplified version of the /etc/httpd/conf.d/ssl.conf:
```
1. Listen 443 https
2. SSLPassPhraseDialog exec:/usr/libexec/httpd-ssl-pass-dialog
SSLSessionCache        shmcb:/run/httpd/sslcache(512000)
SSLSessionCacheTimeout 300
SSLRandomSeed startup file:/dev/urandom 256
SSLRandomSeed connect builtin
SSLCryptoDevice builtin

3. <VirtualHost _default_:443>
     ErrorLog logs/ssl_error_log
     TransferLog logs/ssl_access_log
     LogLevel warn

     4. SSLEngine on
     5. SSLProtocol all -SSLv2
     6. SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5
     7. SSLCertificateFile /etc/pki/tls/certs/localhost.crt
     8. SSLCertificateKeyFile /etc/pki/tls/private/localhost.key
     CustomLog logs/ssl_request_log "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
</VirtualHost>
```

#1. This directive instructs https to listen on port 443/TCP. The second argument (https) is optional, since https is the default protocol for port 443/TCP.
#2. If the pvt key is enc w/ passphrase, httpd needs a method of requesting pass from a user at the console at startup. This directive specifies what program to execute to retrieve that passphrase.
#3. This is the vhost definition for a catch-all vhost on port 443/TCP
#4. This is the directive that actually turns on TLS for this vhost
#5. This directive specifies the list of protocols that httpd is willing to speak w/ clients. For sec, the older, unsafe SSLv3 protocol should also be disabled (append: -SSLv3)
#6. This directive lists what enc ciphers httpd is willing to use when com w/ clients. The selection of ciphers can have a big impact on both perf and sec. 
#7. This directive instructs httpd where it can read the cert for this vhost
#8. This directive instructs httpd where it can read the pvt key for this vhost. httpd reads all pvt keys before privs are dropped so file perms on the pvt key can remain locked down

If a cert signed by a CA is used and the cert itself does not have copies of all the CA certs used in signing, up to a root CA, embedded in it, the server will also need to provide  certificate chain, a copy of all CA certs used in the signing process concatenated together. The SSLCertificateChainFile directive is used to id such a file.

When defining a new TLS enc vhost, it is not needed to copy the entire contents of ssl.conf. Only a <VirtualHost> block w/ the SSLEngine On directive and config for certs is strictly needed. Here is an ex:
```
<VirtualHost *:443>
  ServerName demo.example.com
  SSLEngine On
  SSLCertificateFile /etc/pki/tls/certs/demo.example.com.crt
  SSLCertificateKeyFile /etc/pki/tls/private/demo.example.com.key
  SSLCertificateChainFile /etc/pki/tls/certs/example-ca.crt
</VirtualHost>
```

This ex misses some important directives such as DocumentRoot; these will be inherited from the main config.

Note: Not defining what protocols and ciphers can be used will result in httpd using default options for these. httpd defaults are not considered secure, and it is highly recommeneded to restrict both to a more secure subset.

### Configuring forward secrecy
As mentioned earlier, the client and the server select the enc cipher to be used to secure the TLS con based on a negotiation during the initial handshake. Both the client and the server must find a cipher that both sides of the com support.

If a weaker enc cipher has been used, and the pvt key of the server has been compromised, for ex, after a server break-in or due to a bug in the cryptography code - an attacker could possibly decrypt a recorded session.

One way to protect against these types of attacks is to use ciphers that ensure forward secrecy. Session enc using ciphers with this characteristic can not be decry if the pvt key is compromised at some later date. Fwd secrecy can be established by carefully tuning allowed ciphers in the SSLCipherSuite directive, to preferentially pick ciphers that support fwd secrecy, which both the server and client can use. 

The following is an ex, that at the date of publication was considered a very good set of ciphers to allow. Thi slist prioritizes ciphers that perform the initial session key exchange using eliptic curve Diffie-Hellman (EECDH) algos which support fwd secrecy before falling back to less secure algos. Using EECDH the actual session key is never transmitted, but rather calculated by both sides. 
```
SSLCipherSuite "EECDH+EDSA+AESGCM EECDH+aRSA+AESGCM EECDH+EDSA+SHA384 EECDH+EDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH EDH+aRSA DES-CBC3-SHA !RC4 !aNULL !SSLHonorCipherOrder on
```

The example also disable rc4, due to its increasing vulnerability. This has the somewhat negative side effect of removing server-side BEAST (CVE-2011-3389) mitigation for very old web clients that only support TLSv1.0 and earlier. DES-CBC3-SHA is used to place of RC4 as a "last resort" cipher for support of old IE8/winXP clients. (In addition, to protect against other issues, the insecure SSLv3 and SSLv2 protocols hsould also be disabled on the web server, as prev discussed).

The SSLHonorCipherOrder On directive instructs httpd to preferentially select ciphers based on the order of the SSLCipherSuite list, regardless of the order preferred by the client. 

Note: Securty research is an always ongoing arms race. It is recommended that administrators re-evaluate their selected ciphers on a regular basis.

### Configuring HTTP Strict Transport Security (HSTS)
A common misconfiguration and one that will result in warnings in most modern browsers, is having a web page that is served out over https include resources served out over clear-text http.

To protect against this type of misconfig, add the following line inside a <VirtualHost> block that has TLS enabled:
```
Header always set Strict-Transport-Security "max-age=15768000"
```

Sending this extra header informs clients that they are not allowed to fetch any resources for this pg that are not served using TLS.

Another possible issue comes from clients connecting over http to a resource they should have been using htps for.

Simply not serving any content over http would alleviate this issue, but a more subtle approach is to automatically redirect clients connecting over http to the same resource using https. 

To set up these redirects, configure a http virtual host for the same ServerName and ServerAlias as the TLS protected virtual host (a catch-all virtual host can be used) and add the following lines inside the <VirtualHost *:80> block:
```
RewriteEngine on
RewriteRule ^(/.*)$ https://%{HTTP_HOST}$1 [redirect=301]
```

The RewriteEngine on directive turns on the URL rewrite module for this virtual host, and the RewriteRule matches any resource (^(/.*)$) and redirects it using a http Moved Permanently message ([redirect=301]) to the same resource served out over https. The %{HTTP_HOST} variable uses the hostname that was requested by the client, while the $1 part is a back reference to whatever was matched b/w the first set of parentheses in the regular expressions. 
