# Pianoteq Nix Flake

A Nix flake that installs Pianoteq 7, 8, and 9 on NixOS. The license key and binary are still required and must be acquired manually from https://www.modartt.com/.

## Quick Start

### Install Full Version (recommended)
```bash
nix profile install .#pianoteq9  # Latest version with all formats
```

### Install Specific Format Only
```bash
# VST3 plugin only (for DAW usage)
nix profile install .#pianoteq9-vst3

# Standalone application only
nix profile install .#pianoteq9-standalone

# LV2 plugin only
nix profile install .#pianoteq9-lv2
```

## Available Packages

| Package | Description |
|---------|-------------|
| `pianoteq9` | **Default** - Full version (Standalone + VST3 + LV2) |
| `pianoteq9-standalone` | Standalone only |
| `pianoteq9-vst3` | VST3 plugin only |
| `pianoteq9-lv2` | LV2 plugin only |
| `pianoteq8*` | Standalone + LV2 (VST3 was introduced in v9) |
| `pianoteq7*` | Standalone + LV2 (VST3 was introduced in v9) |

## Installation Steps

### 1. Download Pianoteq

Download the appropriate file from https://www.modartt.com/:

- **Pianoteq 9**: `pianoteq_setup_v911.tar.xz`
- **Pianoteq 8**: `pianoteq_linux_v841.7z`  
- **Pianoteq 7**: `pianoteq_linux_v754.7z`

### 2. Add to Nix Store

```bash
nix store add-file ./downloaded-file.tar.xz
```

### 3. Install Package

```bash
# Install directly
nix profile install .#pianoteq9

# Or add to your flake inputs
inputs = {
  pianoteq.url = "github:yourusername/nix-pianoteq";
};

# Install in configuration.nix or home-manager
environment.systemPackages = [
  inputs.pianoteq.packages.x86_64-linux.default
];
```

**Note**: Hash generation is only needed when updating to a new version. For existing versions, the hash is already provided in the flake.

### Option B: Manual Download (Traditional)

For all users or when auto-download fails:

```bash
# Download from https://www.modartt.com/
# - Pianoteq 9: pianoteq_setup_v911.tar.xz
# - Pianoteq 8: pianoteq_linux_v841.7z  
# - Pianoteq 7: pianoteq_linux_v754.7z

# Add to nix store
nix store add-file ./downloaded-file.tar.xz
```

**Note**: Hash generation is only needed when updating to a new version or adding a new version to the flake. For existing versions, the hash is already provided in the flake.

### 3. Add to Nix Store

```bash
nix store add-file ./downloaded-file.tar.xz
```

### 4. Install Package

```bash
# Add to your flake inputs
inputs = {
  pianoteq.url = "github:yourusername/nix-pianoteq";
};

# Install in configuration.nix or home-manager
environment.systemPackages = [
  inputs.pianoteq.packages.x86_64-linux.default
];

# Or install directly with nix profile
nix profile install .#pianoteq9
```

## Adding New Versions

To add a new Pianoteq version:

### 1. Download and Add to Store
```bash
# Download new version
wget https://www.modartt.com/download?file=pianoteq_linux_vXYZ.7z

# Add to nix store
nix store add-file ./pianoteq_linux_vXYZ.7z
```

### 2. Generate Hash (only for new versions)

When adding a new version to the flake, generate the hash:

```bash
nix hash file --sri ./pianoteq_linux_vXYZ.7z
```

### 3. Update Version Configuration

Add to the `versions` section in `flake.nix`:

```nix
pianoteqX = { 
  version = "X.Y.Z"; 
  file = "pianoteq_linux_vXYZ.7z"; 
  hash = "sha256-GENERATED_HASH_HERE"; 
  compression = "7z"; # or "tar.xz"
  majorVersion = "X";
  hasStandalone = true;  # Set based on actual contents
  hasVst3 = true/false;   # Set based on actual contents  
  hasLv2 = true/false;     # Set based on actual contents
};
```

## Version Support

**VST3 support was introduced in Pianoteq 9** - earlier versions (7 and 8) only support standalone and LV2 formats.

## Troubleshooting

### "Package has unfree license" Error

Pianoteq is proprietary software. Allow unfree packages:

```bash
# For single command
NIXPKGS_ALLOW_UNFREE=1 nix build .#pianoteq9 --impure

# For system-wide
# Add to configuration.nix:
{ nixpkgs.config.allowUnfree = true; }
```

### "File not found in nix store" Error

Make sure to add the downloaded file to the nix store:

```bash
nix store add-file ./pianoteq_setup_v911.tar.xz
```

### Hash Mismatch

If you get a hash mismatch error, regenerate the hash:

```bash
nix hash file --sri ./your-downloaded-file
```

Then update the hash in the `versions` section of `flake.nix`.

## Development

### Development Shell

For easier maintenance and formatting:

```bash
nix develop --impure
```

### Code Formatting

Format Nix files with the built-in formatter:

```bash
nix fmt . --impure
```

### Available Commands

The flake includes a development shell with `nixpkgs-fmt` for code formatting and a formatter for automated formatting.

## License

This Nix flake is licensed under the same terms as Pianoteq itself. Please refer to the Modartt website for licensing information: https://www.modartt.com/