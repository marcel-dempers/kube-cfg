# a Kubernetes config generator

## Requirements

* Endpoint to master
* Name of the cluster (This will be used to generate contexts)
* SSH Key (This will be used to grab things from the master)
* Expiry in days (The generated config will expire after days run out)

## Usage

Parameters : <br/>

```
ENDPOINT=cluster.foo.cloudapp.net
NAME=foo-cluster
SSHKEY=/data/id_rsa
EXPIRY=30
```

Start docker : <br/>

```
docker run -it --rm -v "$PWD":/data kube-cfg:latest "$ENDPOINT" "$NAME" "$SSHKEY" $EXPIRY

```

Example output : 

```
starting kube-cfg...
Processing endpoint : XXXXXXXXXXXXXXXX.cloudapp.azure.com
Processing cluster name: XXXXXXXXXXXXXXXX
Warning: Permanently added 'XXXXXXXXXXXXXXXX.cloudapp.azure.com,13.75.150.100' (ECDSA) to the list of known hosts.
ca.crt                                                                                                                                                                 100% 1720    99.6KB/s   1.7KB/s   00:00    
ca.key                                                                                                                                                                 100% 3243   165.9KB/s   3.2KB/s   00:00    
Processing endpoint : XXXXXXXXXXXXXXXX.cloudapp.azure.com
Processing cluster name: XXXXXXXXXXXXXXXX
Generating RSA private key, 4096 bit long modulus
..................................................................................................................................................................................................++
........................................................................................................................................................................................................................++
e is 65537 (0x10001)
Signature ok
subject=/C=AU/ST=XXXXXXX/L=XXXXXXXX/O=Kubernetes Security/OU=default/CN=cluster-admin
Getting CA Private Key
Cluster "XXXXXXXXXXXXXXXX" set.
User "XXXXXXXXXXXXXXXX-cluster-admin" set.
Context "XXXXXXXXXXXXXXXX" created.
Switched to context "XXXXXXXXXXXXXXXX".
NAME                        STATUS    ROLES     AGE       VERSION
k8s-agentpool1-37126794-0   Ready     agent     18h       v1.8.7
k8s-agentpool1-37126794-1   Ready     agent     19h       v1.8.7
k8s-agentpool1-37126794-2   Ready     agent     19h       v1.8.7
k8s-agentpool1-37126794-3   Ready     agent     19h       v1.8.7
k8s-agentpool1-37126794-4   Ready     agent     19h       v1.8.7
k8s-master-37126794-0       Ready     master    19h       v1.8.7
k8s-master-37126794-1       Ready     master    19h       v1.8.7
k8s-master-37126794-2       Ready     master    19h       v1.8.7
```


#### Install into bashrc (Linux) for easy access

Setup an alias for `kubecfg`

```
echo "alias kubecfg='docker run -it --rm -v \$PWD:/data aimvector/kube-cfg:v1.0.0'" >> ~/.bashrc

```