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
    let hostData = ($data.nixos-flake-configs | get $host)

    log info $"(ansi grey)currentSystem=($data.system) currentHost=($CURRENT_HOSTNAME) host=($host) hostData=($hostData)(ansi reset)"

    let runtime = {
        host: $host
        hostFlake: $"($data.cleanFlake)#($host)"
        local: ($CURRENT_HOSTNAME == $host)
        darwin: ($hostData.outputs.system in ["aarch64-darwin" "x86_64-darwin"])
    }

    if $runtime.local {
        log info $"Activating locally"
        if $runtime.darwin {
            log info $"(ansi blue_bold)>>>(ansi reset) darwin-rebuild switch --flake ($runtime.hostFlake) ($hostData.outputs.nixArgs | str join)"
            darwin-rebuild switch --flake $runtime.hostFlake ...$hostData.outputs.nixArgs 
        } else {
            log info $"(ansi blue_bold)>>>(ansi reset) nixos-rebuild switch --flake ($runtime.hostFlake) ($hostData.outputs.nixArgs | str join) --use-remote-sudo "
            nixos-rebuild switch --flake $runtime.hostFlake ...$hostData.outputs.nixArgs  --use-remote-sudo
        }
    } else {
        log warning $"Activating *remotely* on ($hostData.sshTarget)"
        nix copy ($data.cleanFlake) --to ($"ssh-ng://($hostData.sshTarget)")

        $hostData.outputs.overrideInputs | transpose key value | each { |input|
            log info $"Copying input ($input.key) to ($hostData.sshTarget)"
            log info $"(ansi blue_bold)>>>(ansi reset) nix copy ($input.value) --to ($"ssh-ng://($hostData.sshTarget)")"
            nix copy ($input.value) --to ($"ssh-ng://($hostData.sshTarget)")
        }

        # TODO: don't delegate, just do it here.
        log info $'(ansi blue_bold)>>>(ansi reset) ssh -t ($hostData.sshTarget) nix --extra-experimental-features '"nix-command flakes"' run ($hostData.outputs.nixArgs | str join) $"($data.cleanFlake)#activate" host ($runtime.host)'
        ssh -t $hostData.sshTarget nix --extra-experimental-features '"nix-command flakes"' run ...$hostData.outputs.nixArgs $"($data.cleanFlake)#activate host ($runtime.host)"
    }
}

# TODO: Implement this, resolving https://github.com/srid/nixos-flake/issues/18
def 'main home' [] {
    log error "Home activation not yet supported; use .#activate-home instead"
    exit 1
}

