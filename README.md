## Conventions

- Modules must be placed inside a `modules/` directory.
- Packaged modules must be placed inside a `modules/[package]/` directory.
- Modules are sourced using `bb.import` instead of `source`.
- Private variables for a module must be prefixed by `__`. The format should be
  `__[package]_[module]_[var]`, for example `__bb_import_scripts` for a package
  `bb`, the module `import`, and the variable named `scripts`.