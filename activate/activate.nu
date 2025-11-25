use std log
use std assert

use nixos-unified.nu getData  # This module is generated in Nix

let CURRENT_HOSTNAME = (hostname -s | str trim)
let data = getData

# Get all the data associated with a host
#
# Presently, this only deals with nixosConfigurations and darwinConfigurations.
# But we should also incorporate home-manager configurations.
def get_host_data [ host: string ] {
    if $host not-in $data.nixos-unified-configs {
        log error $"Host '($host)' not found in flake. Available hosts=($data.nixos-unified-configs | columns)"
        exit 1
    }
    $data.nixos-unified-configs
        | get $host
        | insert "host" $host
        | insert "flake" $"($data.cleanFlake)#($host)"
}

# Parse "[srid@]example" into { user: "srid", host: "example" }
#
# localhost hosts are ignored (null'ified)
def parseFlakeOutputRef [ spec: string ] {
    let parts = $spec | split row "@"
    let handleLocalhost = {|h| if $h == "localhost" { null } else { $h } }
    if ($parts | length) == 1 {
        { user: null host: (do $handleLocalhost $parts.0) }
    } else {
        { user: $parts.0 host: (do $handleLocalhost $parts.1) }
    }
}

# Activate system or home configuration
#
# The ref should match the name of the corresponding nixosConfigurations, darwinConfigurations or homeConfigurations attrkey. "localhost" is an exception, which will use the current host.
def main [
  ref: string = "localhost", # Hostname or username (if containing `@`) to activate
  --dry-run # Dry run (don't actually activate)
] {
    let spec = parseFlakeOutputRef $ref
    if $spec.user != null {
        activate_home $spec.user $spec.host --dry-run=$dry_run
    } else {
        let host = if ($spec.host | is-empty) { $CURRENT_HOSTNAME } else { $spec.host }
        let hostData = get_host_data $host
        activate_system $hostData --dry-run=$dry_run
    }
}

def activate_home [ user: string, host: string, --dry-run ] {
    if (($host | is-empty) or ($host == $CURRENT_HOSTNAME)) {
        activate_home_local $user $host --dry-run=$dry_run
    } else {
        activate_home_remote_ssh $user $host --dry-run=$dry_run
    }
}

def activate_home_local [ user: string, host: string, --dry-run ] {
    let name = $"($user)" + (if ($host | is-empty) { "" } else { "@" + $host })
    let extraArgs = if $dry_run { ["--dry-run"] } else { [] }
    log info $"Activating home configuration ($name) (ansi purple)locally(ansi reset)"
    log info $"(ansi blue_bold)>>>(ansi reset) home-manager switch ($extraArgs | str join) --flake ($data.cleanFlake)#($name)"
    home-manager switch ...$extraArgs -b (date now | format date "nixos-unified.%Y-%m-%d-%H:%M:%S.bak") --flake $"($data.cleanFlake)#($name)"
}

def activate_home_remote_ssh [ user: string, host: string, --dry-run ] {
    let name = $"($user)@($host)"
    let sshTarget = $"($user)@($host)"
    log info $"Activating home configuration ($name) (ansi purple_reverse)remotely(ansi reset) on ($sshTarget)"

    # Copy the flake to the remote host.
    nix_copy $data.cleanFlake $"ssh-ng://($sshTarget)"

    # We re-run this activation script, but on the remote host (where it will invoke activate_home_local).
    log info $'(ansi blue_bold)>>>(ansi reset) ssh -t ($sshTarget) nix --extra-experimental-features '"nix-command flakes"' run $"($data.cleanFlake)#activate" -- ($name) --dry-run=($dry_run)'
    ssh -t $sshTarget nix --extra-experimental-features '"nix-command flakes"' run $"($data.cleanFlake)#activate" -- ($name) --dry-run=($dry_run)
}

def activate_system [ hostData: record, --dry-run=false ] {
    log info $"(ansi grey)currentSystem=($data.system) currentHost=(ansi green_bold)($CURRENT_HOSTNAME)(ansi grey) targetHost=(ansi green_reverse)($hostData.host)(ansi reset)(ansi grey) hostData=($hostData)(ansi reset)"

    if ($CURRENT_HOSTNAME == $hostData.host) {
        # Since the user asked to activate current host, do so.
        activate_system_local $hostData --dry-run=$dry_run
    } else {
        # Remote activation request, so copy the flake and the necessary inputs
        # and then activate over SSH.
        if $hostData.sshTarget == null {
            log error $"sshTarget not found in host data for ($hostData.host). Add `nixos-unified.sshTarget = \"user@hostname\";` to your configuration."
            exit 1
        }
        activate_system_remote_ssh $hostData --dry-run=$dry_run
    }
}

def activate_system_local [ hostData: record, --dry-run=false ] {
    log info $"Activating (ansi purple)locally(ansi reset)"
    let darwin = $hostData.outputs.system in ["aarch64-darwin" "x86_64-darwin"]
    if $darwin {
        let subcommand = if $dry_run { "build" } else { "switch" }
        log info $"(ansi blue_bold)>>>(ansi reset) sudo darwin-rebuild ($subcommand) --flake ($hostData.flake) ($hostData.outputs.nixArgs | str join)"
        sudo darwin-rebuild $subcommand --flake $hostData.flake ...$hostData.outputs.nixArgs
    } else {
        let subcommand = if $dry_run { "dry-activate" } else { "switch" }
        log info $"(ansi blue_bold)>>>(ansi reset) nixos-rebuild ($subcommand) --flake ($hostData.flake) ($hostData.outputs.nixArgs | str join) --sudo "
        nixos-rebuild $subcommand --flake $hostData.flake ...$hostData.outputs.nixArgs --sudo
    }
}

def activate_system_remote_ssh [ hostData: record, --dry-run=false ] {
    log info $"Activating (ansi purple_reverse)remotely(ansi reset) on ($hostData.sshTarget)"

    # Copy the flake and the necessary inputs to the remote host.
    nix_copy $data.cleanFlake $"ssh-ng://($hostData.sshTarget)"
    $hostData.outputs.overrideInputs | transpose key value | each { |input|
        nix_copy $input.value $"ssh-ng://($hostData.sshTarget)"
    }

    # We re-run this activation script, but on the remote host (where it will invoke activate_system_local).
    log info $'(ansi blue_bold)>>>(ansi reset) ssh -t ($hostData.sshTarget) nix --extra-experimental-features '"nix-command flakes"' run ($hostData.outputs.nixArgs | str join) $"($data.cleanFlake)#activate" -- ($hostData.host) --dry-run=($dry_run)'
    ssh -t $hostData.sshTarget nix --extra-experimental-features '"nix-command flakes"' run ...$hostData.outputs.nixArgs $"($data.cleanFlake)#activate" -- ($hostData.host) --dry-run=($dry_run)
}

def nix_copy [ src: string dst: string ] {
    log info $"(ansi blue_bold)>>>(ansi reset) nix --extra-experimental-features \"nix-command flakes\" copy ($src) --to ($dst)"
    nix --extra-experimental-features "nix-command flakes" copy $src --to $dst
}
