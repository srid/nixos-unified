
def main [host: string, cleanFlake: string, hostData: string] {
    use std log
    let hostData = $hostData | from json
    let sshTarget = ($hostData | get "sshTarget"  )
    let overrideInputs = ($hostData | get "overrideInputs" )
    let nixArgs = ($hostData | get "outputs" | get "nixArgs") 
    log info ($hostData | to json)

    if (hostname | str trim) == $host {
        log info $"Activating locally"
        # TODO: don't delegate, just do it here.
        log info $"(ansi blue_bold)>>>(ansi reset) nix run ...$nixArgs ($"($cleanFlake)#activate")"
        nix run ...$nixArgs ($"($cleanFlake)#activate")
    } else {
        log warning $"Activating remotely on ($sshTarget)"
        nix copy ($cleanFlake) --to ($"ssh-ng://($sshTarget)")

        $overrideInputs | each { |input|
            log info $"Copying input ($input) to ($sshTarget)"
            nix copy $input --to ($"ssh-ng://($sshTarget)")
        }

        # TODO: don't delegate, just do it here.
        log info $'(ansi blue_bold)>>>(ansi reset) ssh -t ($sshTarget) nix --extra-experimental-features '"nix-command flakes"' run ($nixArgs) $"($cleanFlake)#activate" '
        ssh -t $sshTarget nix --extra-experimental-features '"nix-command flakes"' run ...$nixArgs $"($cleanFlake)#activate"
    }

}
