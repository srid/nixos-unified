
# TODO: put cleanFlake in hostData
def main [host: string, currentSystem: string, cleanFlake: string, hostData: string] {
    use std log
    log info $"host=($host) data=($hostData)"
    let hostData = $hostData | from json
    let sshTarget = ($hostData | get "sshTarget"  )
    let overrideInputs = ($hostData | get "overrideInputs" )
    let nixArgs = ($hostData | get "outputs" | get "nixArgs") 
    let system = ($hostData | get "outputs" | get "system") 
    let currentHost = (hostname | str trim)

    log info $"currentSystem=($currentSystem) system=($system); currentHost=($currentHost) host=($host)"

    if $currentHost == $host {
        log info $"Activating locally"
        # TODO: don't delegate, just do it here.
        log info $"(ansi blue_bold)>>>(ansi reset) nix run ($nixArgs | str join) ($"($cleanFlake)#activate")"
        nix run ...$nixArgs ($"($cleanFlake)#activate")
    } else {
        log warning $"Activating remotely on ($sshTarget)"
        nix copy ($cleanFlake) --to ($"ssh-ng://($sshTarget)")

        $overrideInputs | each { |input|
            log info $"Copying input ($input) to ($sshTarget)"
            nix copy $input --to ($"ssh-ng://($sshTarget)")
        }

        # TODO: don't delegate, just do it here.
        log info $'(ansi blue_bold)>>>(ansi reset) ssh -t ($sshTarget) nix --extra-experimental-features '"nix-command flakes"' run ($nixArgs | str join) $"($cleanFlake)#activate" '
        ssh -t $sshTarget nix --extra-experimental-features '"nix-command flakes"' run ...$nixArgs $"($cleanFlake)#activate"
    }
}
