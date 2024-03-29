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

```powershell
# Download and install the latest stable release of QZ Tray
irm pwsh.sh | iex
```

<details>
<summary>Click to expand what to do if you recieve a security error</summary>

```powershell
# Optional: Needed to run a remote script the first time
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
</details>
   

## Advanced

Additional parameters can be provided to specify `beta` or an exact tagged release.

### Curl
```bash
curl qz.sh |bash -s -- "beta"   # latest beta release
curl qz.sh |bash -s -- "2.2.1"  # tagged "v2.2.1" release
```

### Wget
```bash
wget -O - qz.sh |bash -s -- "beta"   # latest beta release
wget -O - qz.sh |bash -s -- "2.2.1"  # tagged "v2.2.1" release
```

### PowerShell
```powershell
& ([scriptblock]::Create((irm pwsh.sh))) beta   # latest beta release
& ([scriptblock]::Create((irm pwsh.sh))) 2.2.1  # tagged "v2.2.1" release
```
