use std log
use std assert

use nixos-flake.nu getData  # This module is generated in Nix

let CURRENT_HOSTNAME = (hostname | str trim)

# Parse "[srid@]example" into { user: "srid", host: "example" }
#
# localhost hosts are ignored (null'ified)
def parseFlakeOutputRef [ spec: string ] {
    if spec == "" {
        { user: null host: null }
    } else {
        let parts = $spec | split row "@"
        let handleLocalhost = {|h| if $h == "localhost" { null } else { $h } }
        if ($parts | length) == 1 {
            { user: null host: (do $handleLocalhost $parts.0) }
        } else {
            { user: $parts.0 host: (do $handleLocalhost $parts.1) }
        }
    }
}

# Activate system configuration of the given host
# 
# To activate a remote machine, use run with subcommands: `host <hostname>`
def main [
  ref: string = "" # Hostname to activate (must match flake.nix name)
] {
    let spec = parseFlakeOutputRef $ref
    print $"Spec: ($spec)"
    if $spec.user != null {
        log error $"Cannot activate home environments yet; use .#activate-home instead"
        exit 1
    }
    let host = if ($spec.host | is-empty) { $CURRENT_HOSTNAME } else { $spec.host }
    let data = getData
    if $host not-in $data.nixos-flake-configs {
        log error $"Host '($host)' not found in flake. Available hosts=($data.nixos-flake-configs | columns)"
        exit 1
    }
    let hostData = $data.nixos-flake-configs 
        | get $host
        | insert "flake" $"($data.cleanFlake)#($host)"

    log info $"(ansi grey)currentSystem=($data.system) currentHost=(ansi green_bold)($CURRENT_HOSTNAME)(ansi grey) targetHost=(ansi green_reverse)($host)(ansi reset)(ansi grey) hostData=($hostData)(ansi reset)"

    let runtime = {
        local: ($CURRENT_HOSTNAME == $host)
        darwin: ($hostData.outputs.system in ["aarch64-darwin" "x86_64-darwin"])
    }

    if $runtime.local {
        # Since the user asked to activate current host, do so.
        log info $"Activating (ansi purple)locally(ansi reset)"
        if $runtime.darwin {
            log info $"(ansi blue_bold)>>>(ansi reset) darwin-rebuild switch --flake ($hostData.flake) ($hostData.outputs.nixArgs | str join)"
            darwin-rebuild switch --flake $hostData.flake ...$hostData.outputs.nixArgs 
        } else {
            log info $"(ansi blue_bold)>>>(ansi reset) nixos-rebuild switch --flake ($hostData.flake) ($hostData.outputs.nixArgs | str join) --use-remote-sudo "
            nixos-rebuild switch --flake $hostData.flake ...$hostData.outputs.nixArgs --use-remote-sudo
        }
    } else {
        # Remote activation request, so copy the flake and the necessary inputs
        # and then activate over SSH.
        if $hostData.sshTarget == null {
            log error $"sshTarget not found in host data for ($host). Add `nixos-flake.sshTarget = \"user@hostname\";` to your configuration."
            exit 1
        }
        log info $"Activating (ansi purple_reverse)remotely(ansi reset) on ($hostData.sshTarget)"
        nix copy ($data.cleanFlake) --to ($"ssh-ng://($hostData.sshTarget)")

        $hostData.outputs.overrideInputs | transpose key value | each { |input|
            log info $"Copying input ($input.key) to ($hostData.sshTarget)"
            log info $"(ansi blue_bold)>>>(ansi reset) nix copy ($input.value) --to ($"ssh-ng://($hostData.sshTarget)")"
            nix copy ($input.value) --to ($"ssh-ng://($hostData.sshTarget)")
        }

        # We re-run this script, but on the remote host.
        log info $'(ansi blue_bold)>>>(ansi reset) ssh -t ($hostData.sshTarget) nix --extra-experimental-features '"nix-command flakes"' run ($hostData.outputs.nixArgs | str join) $"($data.cleanFlake)#activate" ($host)'
        ssh -t $hostData.sshTarget nix --extra-experimental-features '"nix-command flakes"' run ...$hostData.outputs.nixArgs $"($data.cleanFlake)#activate ($host)"
    }
}