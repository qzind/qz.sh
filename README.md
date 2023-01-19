# qz.sh, pwsh.sh
QZ Tray online scripted installer

<img width="550" alt="Screen Shot 2022-04-19 at 1 30 32 PM" src="https://user-images.githubusercontent.com/6345473/164061886-7f9fac10-3f40-483c-9f1f-031bd88acea1.png">

## MacOS

```bash
# Download and install the latest stable release of QZ Tray
curl qz.sh |bash
```

## Linux

```bash
# Download and install the latest stable release of QZ Tray
wget -O - qz.sh |bash
```

## Windows

```bash
# Download and install the latest stable release of QZ Tray
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser # Optional: Needed to run a remote script the first time
irm pwsh.sh | iex
```

## Advanced

Additional parameters can be provided to specify `beta` or an exact tagged release.

```bash
# Download and install the latest stable release of QZ Tray
curl qz.sh |bash -s -- "beta"   # latest beta release
curl qz.sh |bash -s -- "2.2.1"  # tagged "v2.2.1" release
```
