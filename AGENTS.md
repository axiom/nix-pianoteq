# AGENTS.md

This repository is a small Nix flake for packaging Pianoteq 7/8/9 on NixOS.
Use these guidelines when making changes so automated agents behave consistently.

## Scope

- Applies to the entire repository (no nested rules found).

## Quick Commands

### Development Shell

- Enter the dev shell with formatting tools:
  - `nix develop`

### Formatting (Nix)

- Format all Nix files:
  - `nix fmt .`

### Build / Validate

- Build default package (Pianoteq 9 full):
  - `nix build .#pianoteq9`
- Build a specific package:
  - `nix build .#pianoteq9-vst3`
  - `nix build .#pianoteq8-standalone`
  - `nix build .#pianoteq7-lv2`
- Validate flake outputs:
  - `nix flake check`

### “Single Test” Equivalent

- There is no test suite; treat single-package builds as a unit check.
- Run a single build for the target you changed, e.g.:
  - `nix build .#pianoteq9`
- Run `nix run .#pianoteq9 -- --version` to see reported version.

## Repository Structure

- `flake.nix` contains all logic:
  - Version metadata (`versions` set)
  - Derivation builder (`mkPianoteqPackage`)
  - Package outputs (variants per version)
  - Dev shell and formatter
- `README.md` documents usage, version updates, and troubleshooting.

## Code Style (Nix)

### Formatting

- Use `nix fmt .` before finalizing changes.
- Preserve existing indentation (2 spaces) and layout.
- Keep long strings and shell snippets aligned with current style.

### Imports & Module Structure

- Follow the existing pattern:
  - `inputs.nixpkgs` declared at top level
  - `outputs` defines `systems`, `forAllSystems`, `versions`, and helpers
  - `pkgs = import nixpkgs { inherit system; config.allowUnfree = true; }`
  - `lib = pkgs.lib`
- Avoid introducing new imports unless necessary.

### Version Metadata

- Keep version configuration in `versions` only.
- Each version entry should include:
  - `version`, `file`, `hash`, `compression`, `majorVersion`, `hasVst3`, `hasLv2`
- Use `mkVersion` for file naming consistency.

### Package Naming

- Follow existing names:
  - `pianoteq9`, `pianoteq9-standalone`, `pianoteq9-vst3`, `pianoteq9-lv2`
  - Same pattern for `pianoteq8` and `pianoteq7`
- Use `versionKey = "pianoteqX"` and enable flags to control variants.

### Build Logic

- Reuse `mkPianoteqPackage` for all variants.
- Keep `buildInputs` and `nativeBuildInputs` in one place.
- Prefer `lib.optionals` / `lib.optionalString` for conditionals.
- Use `lib.throwIf` for feature validation errors.

### Error Handling

- Validate unsupported plugin selections with `lib.throwIf`.
- Ensure errors include the major version and missing feature.
- Avoid `throw` in the middle of build steps; keep validation centralized.

### Derivation Structure

- Keep the derivation fields in a consistent order:
  - `pname`, `version`, `src`, `buildInputs`, `nativeBuildInputs`, phases
- Avoid adding extra phases unless necessary.
- Prefer `runHook preBuild` / `postBuild` and `preInstall` / `postInstall`.

### Shell Snippets

- Use `${lib.optionalString ... '' ... ''}` for conditional install blocks.
- Use `install -Dm` to create directories and install binaries.
- Keep paths stable and quote paths with spaces.

### Types & Values

- Nix values should be explicit and predictable:
  - Use booleans for flags (`enableVst3`, `enableLv2`).
  - Use strings for versions and filenames.
  - Use lists for dependencies and categories.

### Naming Conventions

- Functions: `mkSomething`, `forAllSystems`
- Variables: `versionConfig`, `srcFile`, `runtimeDependencies`
- Packages: `pianoteq<major>` and `pianoteq<major>-<variant>`

## Updating Versions

- Add new versions only inside `versions`.
- Steps:
  1. Download the new archive.
  2. Add to the store: `nix store add-file ./pianoteq_linux_vXYZ.7z`
  3. Hash it: `nix hash file --sri ./pianoteq_linux_vXYZ.7z`
  4. Update `versions` and `README.md` accordingly.
- Keep `compression` accurate: `7z` or `tar.xz`.

## Documentation Updates

- Update `README.md` when adding versions or changing package names.
- Keep tables and examples aligned with the package outputs.

## Review Checklist

- `nix fmt .` passes
- `nix build .#<changed-package>` succeeds
- `nix flake check` succeeds
- `README.md` updated if interfaces changed

## Notes for Agents

- Pianoteq is proprietary; `allowUnfree` is required.
- `pkgs.requireFile` expects users to add archives to the store.
- Avoid adding new files unless requested; keep changes minimal.
