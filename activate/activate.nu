use std log
use std assert

use nixos-flake.nu getData  # This module is generated in Nix

let CURRENT_HOSTNAME = (hostname -s | str trim)
let data = getData

# Get all the data associated with a host
#
# Presently, this only deals with nixosConfigurations and darwinConfigurations.
# But we should also incorporate home-manager configurations.
def get_host_data [ host: string ] {
    if $host not-in $data.nixos-flake-configs {
        log error $"Host '($host)' not found in flake. Available hosts=($data.nixos-flake-configs | columns)"
        exit 1
    }
    $data.nixos-flake-configs 
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

# Activate system configuration of the given host 
#
# The hostname should match the name of the corresponding nixosConfigurations or
# darwinConfigurations attrkey. "localhost" is an exception, which will use the
# current host. 
def main [
  ref: string = "localhost" # Hostname to activate 
] {
    let spec = parseFlakeOutputRef $ref
    if $spec.user != null {
        activate_home $spec.user $spec.host
    } else {
        let host = if ($spec.host | is-empty) { $CURRENT_HOSTNAME } else { $spec.host }
        let hostData = get_host_data $host
        activate_system $hostData
    }
}

def activate_home [ user: string, host: string ] {
    if (($host | is-empty) or ($host == $CURRENT_HOSTNAME)) {
        activate_home_local $user $host
    } else {
        log error $"Remote activation not yet supported for homeConfigurations"
        exit 1
    }
}

def activate_home_local [ user: string, host: string ] {
    let name = $"($user)" + (if ($host | is-empty) { "" } else { "@" + $host })
    log info $"Activating home configuration ($name) (ansi purple)locally(ansi reset)"
    log info $"(ansi blue_bold)>>>(ansi reset) home-manager switch --flake ($data.cleanFlake)#($name)"
    home-manager switch --flake $"($data.cleanFlake)#($name)"
}

def activate_system [ hostData: record ] {
    log info $"(ansi grey)currentSystem=($data.system) currentHost=(ansi green_bold)($CURRENT_HOSTNAME)(ansi grey) targetHost=(ansi green_reverse)($hostData.host)(ansi reset)(ansi grey) hostData=($hostData)(ansi reset)"

    if ($CURRENT_HOSTNAME == $hostData.host) {
        # Since the user asked to activate current host, do so.
        activate_system_local $hostData
    } else {
        # Remote activation request, so copy the flake and the necessary inputs
        # and then activate over SSH.
        if $hostData.sshTarget == null {
            log error $"sshTarget not found in host data for ($hostData.host). Add `nixos-flake.sshTarget = \"user@hostname\";` to your configuration."
            exit 1
        }
        activate_system_remote_ssh $hostData
    }
}

def activate_system_local [ hostData: record ] {
    log info $"Activating (ansi purple)locally(ansi reset)"
    let darwin = $hostData.outputs.system in ["aarch64-darwin" "x86_64-darwin"]
    if $darwin {
        log info $"(ansi blue_bold)>>>(ansi reset) darwin-rebuild switch --flake ($hostData.flake) ($hostData.outputs.nixArgs | str join)"
        darwin-rebuild switch --flake $hostData.flake ...$hostData.outputs.nixArgs 
    } else {
        log info $"(ansi blue_bold)>>>(ansi reset) nixos-rebuild switch --flake ($hostData.flake) ($hostData.outputs.nixArgs | str join) --use-remote-sudo "
        nixos-rebuild switch --flake $hostData.flake ...$hostData.outputs.nixArgs --use-remote-sudo
    }
}

def activate_system_remote_ssh [ hostData: record ] {
    log info $"Activating (ansi purple_reverse)remotely(ansi reset) on ($hostData.sshTarget)"

    # Copy the flake and the necessary inputs to the remote host.
    nix_copy $data.cleanFlake $"ssh-ng://($hostData.sshTarget)"
    $hostData.outputs.overrideInputs | transpose key value | each { |input|
        nix_copy $input.value $"ssh-ng://($hostData.sshTarget)"
    }

    # We re-run this activation script, but on the remote host (where it will invoke activate_system_local).
    log info $'(ansi blue_bold)>>>(ansi reset) ssh -t ($hostData.sshTarget) nix --extra-experimental-features '"nix-command flakes"' run ($hostData.outputs.nixArgs | str join) $"($data.cleanFlake)#activate" ($hostData.host)'
    ssh -t $hostData.sshTarget nix --extra-experimental-features '"nix-command flakes"' run ...$hostData.outputs.nixArgs $"($data.cleanFlake)#activate ($hostData.host)"
}

def nix_copy [ src: string dst: string ] {
    log info $"(ansi blue_bold)>>>(ansi reset) nix copy ($src) --to ($dst)"
    nix copy $src --to $dst
}
