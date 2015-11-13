DDclient
==========================


DDclient - http://sourceforge.net/p/ddclient/wiki/Home/ 



Running on the latest Phusion release (ubuntu 14.04), with ddclient 3.8.3

**Pull image**

```
docker pull mace/ddclient
```
**Container config**

*Rename the sample config to ddclient.conf in the host directory
*The sample config will be avaible afer the first run


**Run container**

```
docker run -d --net="bridge" --name=<container name> -v <path for ddclient config files>:/config -v /etc/localtime:/etc/localtime:ro mace/ddclient
```
Please replace all user variables in the above command defined by <> with the correct values.
```
-e PIPEWORK=<yes>
```

**Example**

```
docker run -d --net="bridge" --name=ddclient -v /mylocal/directory/fordata:/config -v /etc/localtime:/etc/localtime:ro mace/ddclient
```

For use with "pipework" --  https://hub.docker.com/r/dreamcat4/pipework/

```
docker run -d --net=none --name=ddclient -v /mylocal/directory/fordata:/config -v /etc/localtime:/etc/localtime:ro -e  PIPEWORK=yes -e 'pipework_cmd=br1 @ddclient@ 192.168.1.10/24@192.168.1.1' mace/ddclient
```


**Additional notes**


* The owner of the config directory needs sufficent permissions (UUID 99 / GID 100).
* Check the manual from the link on the top for how to setup your ddclient config.
