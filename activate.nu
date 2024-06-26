
# TODO: put host & cleanFlake in hostData
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

    let runtime = {
        system: $system
        host: $host
        hostFlake: $"($cleanFlake)#($host)"
        # currentSystem: $currentSystem
        # currentHost: $currentHost
        local: ($currentHost == $host)
        darwin: ($system == "aarch64-darwin" or $system == "x86_64-darwin")
    }

    if $runtime.local {
        log info $"Activating locally"
        if $runtime.darwin {
            log info $"(ansi blue_bold)>>>(ansi reset) darwin-rebuild switch --flake ($runtime.hostFlake) ($nixArgs | str join)"
            darwin-rebuild switch --flake $runtime.hostFlake ...$nixArgs 
        } else {
            log info $"(ansi blue_bold)>>>(ansi reset) nixos-rebuild switch --flake ($runtime.hostFlake) --use-remote-sudo ($nixArgs | str join)"
            nixos-rebuild switch --flake $runtime.hostFlake ...$nixArgs  --use-remote-sudo
        }
    } else {
        log warning $"Activating *remotely* on ($sshTarget)"
        nix copy ($cleanFlake) --to ($"ssh-ng://($sshTarget)")

        $overrideInputs | each { |input|
            log info $"Copying input ($input) to ($sshTarget)"
            nix copy $input --to ($"ssh-ng://($sshTarget)")
        }

        # TODO: don't delegate, just do it here.
        log info $'(ansi blue_bold)>>>(ansi reset) ssh -t ($sshTarget) nix --extra-experimental-features '"nix-command flakes"' run ($nixArgs | str join) $"($cleanFlake)#activate" '
        ssh -t $sshTarget nix --extra-experimental-features '"nix-command flakes"' run ...$nixArgs $"($cleanFlake)#activate-v2 $runtime.host"
    }
}
