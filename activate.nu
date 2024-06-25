
def main [host: string, cleanFlake: string, hostData: string] {
    use std log
    let hostData = $hostData | from json
    let sshTarget = ($hostData | get "sshTarget"  )
    let overrideInputs = ($hostData | get "overrideInputs" )
    let nixArgs = ($hostData | get "outputs" | get "nixArgs" | inspect )
    log info ($hostData | to json)

   let CURRENT_HOSTNAME = (hostname | str trim)
    # Check if the current hostname matches
    if $CURRENT_HOSTNAME == $host {
        log info $"Activating locally"
        # TODO: don't delegate, just do it here.
        nix run ...$nixArgs ($"($cleanFlake)#activate")
    } else {
        log warning $"Activating remotely on ($sshTarget)"
        nix copy ($cleanFlake) --to ($"ssh-ng://($sshTarget)")

        $overrideInputs | each { |input|
            log info $"Copying input ($input) to ($sshTarget)"
            nix copy $input --to ($"ssh-ng://($sshTarget)")
        }

        log info $"(ansi red_bold) ssh'ing (ansi reset) to ($sshTarget)"

        # TODO: don't delegate, just do it here.
        ssh -t $sshTarget nix --extra-experimental-features '"nix-command flakes"' run ...$nixArgs $"($cleanFlake)#activate" 
        p
    }

}