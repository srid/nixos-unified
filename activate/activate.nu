use std log
use nixos-flake.nu getData  # This module is generated in Nix

let CURRENT_HOSTNAME = (hostname | str trim)

# Activate system configuration of local machine
def main [] {
    main host ($CURRENT_HOSTNAME)
}

# Activate system configuration of the given host
def 'main host' [
  host: string # Hostname to activate (must match flake.nix name)
] {
    log info $"Activating (ansi green_bold)($host)(ansi reset) from (ansi green_bold)($CURRENT_HOSTNAME)(ansi reset)"
    let data = getData
    let hostData = ($data | get "nixos-flake-configs" | get $host)
    let currentSystem = ($data | get "system")
    let cleanFlake = ($data | get "cleanFlake")

    log info $"host=($host) data=($hostData)"
    let sshTarget = $hostData.sshTarget
    let overrideInputs = $hostData.outputs.overrideInputs
    let nixArgs = $hostData.outputs.nixArgs
    let system = $hostData.outputs.system
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
            log info $"(ansi blue_bold)>>>(ansi reset) nixos-rebuild switch --flake ($runtime.hostFlake) ($nixArgs | str join) --use-remote-sudo "
            nixos-rebuild switch --flake $runtime.hostFlake ...$nixArgs  --use-remote-sudo
        }
    } else {
        log warning $"Activating *remotely* on ($sshTarget)"
        nix copy ($cleanFlake) --to ($"ssh-ng://($sshTarget)")

        $overrideInputs | transpose key value | each { |input|
            log info $"Copying input ($input.key) to ($sshTarget)"
            log info $"(ansi blue_bold)>>>(ansi reset) nix copy ($input.value) --to ($"ssh-ng://($sshTarget)")"
            nix copy ($input.value) --to ($"ssh-ng://($sshTarget)")
        }

        # TODO: don't delegate, just do it here.
        log info $'(ansi blue_bold)>>>(ansi reset) ssh -t ($sshTarget) nix --extra-experimental-features '"nix-command flakes"' run ($nixArgs | str join) $"($cleanFlake)#activate" host ($runtime.host)'
        ssh -t $sshTarget nix --extra-experimental-features '"nix-command flakes"' run ...$nixArgs $"($cleanFlake)#activate host ($runtime.host)"
    }
}

# TODO: Implement this, resolving https://github.com/srid/nixos-flake/issues/18
def 'main home' [] {
    log error "Home activation not yet supported; use .#activate-home instead"
    exit 1
}

