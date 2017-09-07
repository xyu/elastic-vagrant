# Elastic Vagrant

A Vagrant instance that starts 3 nodes on the same VM.

## Getting Started

Provision the VM:

```
$ vagrant up
```

Check that the cluster is up:
```
$ curl 127.0.0.1:9200
{
  "name" : "node-1",
  "cluster_name" : "2017-gm",
  "cluster_uuid" : "ozO9_svsRZuhzF_YqTcr5A",
  "version" : {
    "number" : "2.4.4",
    "build_hash" : "fcbb46dfd45562a9cf00c604b30849a6dec6b017",
    "build_timestamp" : "2017-01-03T11:33:16Z",
    "build_snapshot" : false,
    "lucene_version" : "5.5.2"
  },
  "tagline" : "You Know, for Search"
}
```

Reprovision on config changes:

```
$ vagrant provision
```
