DDclient
==========================


DDclient - http://sourceforge.net/p/ddclient/wiki/Home/ 



Running on the latest Phusion release (ubuntu 14.04), with ddclient 3.8.3
Supports sending update notifications with Gmail account (as relay)

**Pull image**

```
docker pull mace/ddclient
```
**Container config**

* Rename the sample config to ddclient.conf in the host directory
* The sample config will be avaible afer the first run
* Configure Gmail credentials in mail.txt(avaible after first run), Dont forget to setup reciving email address in ddclient.conf
* For enabling mail theese variables need to be added to the run command "-h ddclient.local" "-v MAIL=yes"


**Run container**

```
docker run -d --net="bridge" --name=<container name> -v <path for ddclient config files>:/config -v /etc/localtime:/etc/localtime:ro mace/ddclient
```
Please replace all user variables in the above command defined by <> with the correct values.

Variables that can be added
```
-e MAIL=<yes>
-h <ddclient.example.com>
-e PIPEWORK=<yes>
```

**Example**

```
docker run -d --net="bridge" --name=ddclient -e MAIL=yes -v /mylocal/directory/fordata:/config -v /etc/localtime:/etc/localtime:ro mace/ddclient
```

For use with Gmail as mail-relay 

```
docker run -d --net="bridge" --name=ddclient -h ddclient.example.com -e MAIL=yes -v /mylocal/directory/fordata:/config -v /etc/localtime:/etc/localtime:ro mace/ddclient
```


For use with "pipework" --  https://hub.docker.com/r/dreamcat4/pipework/

```
docker run -d --net=none --name=ddclient  --name=ddclient -v /mylocal/directory/fordata:/config -v /etc/localtime:/etc/localtime:ro -e  PIPEWORK=yes -e 'pipework_cmd=br1 @ddclient@ 192.168.1.10/24@192.168.1.1' mace/ddclient
```


**Add CA Certificates**

For example, download the CACert.org certificates to and mount them in `/usr/local/share/ca-certificates`

```
cd /mylocal/directory/forcerts
wget http://www.cacert.org/certs/root.crt http://www.cacert.org/certs/class3.crt

docker run -d --net="bridge" --name=ddclient -e MAIL=yes -v /mylocal/directory/fordata:/config -v /etc/localtime:/etc/localtime:ro -v /mylocal/directory/forcerts:/usr/local/share/ca-certificates:ro quiffman/ddclient
```


**Additional notes**


* The owner of the config directory needs sufficent permissions (UUID 99 / GID 100).
* Check the manual from the link on the top for how to setup your ddclient config.
* The "-h" option can be anything as long as its a qualified domain name fqdn.
