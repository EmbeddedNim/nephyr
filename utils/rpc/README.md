
Rpc server examples:

```sh
./rpc_server_example 
```

Example output on startup:

```
createRpcRouter: 1400
starting mpack rpc server: buffer: %s1400
Server: starting 
Server: started on port: 5555
```

Example rpc calls:

```sh
# add two ints, rpc_cli parses in format <method name> <json arg1> <json arg2>
./rpc_cli call --ip=127.0.0.1 -c:1 --pretty addInt 1 2

# call rpc with 'raw json args' args, must be wrapped in outer json array 
./rpc_cli call --ip=127.0.0.1 -c:1 --pretty addAll --rawJsonArgs '[[1, 2, 3, 4, 5]]'
```

