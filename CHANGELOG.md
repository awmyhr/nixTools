# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/).
Individual files in this project try to adhere to [Semantic Versioning](http://semver.org/),
however the project itself uses date versioning.

---

## TODO
- Document the things

---

## [Unreleased]
### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

---

## [2017.01.02]
### Added
- Script templates will now output Sphinx/reST-style usage.
- newfile will now output Sphinx/reST-style usage.
- Create .pylink directory w/symlinks to Python scripts using '.py' extension.
  This is needed so Sphinx sees them as Python modules and works its magic.
- Worked out a documentation process using Sphinx/reStructuredText.

### Changed
- Options for newfile (--template-dir & --config-file) have been shortened for 
  better useability (--templates & --config), as well as given short options
  (-T & -c).

---

## [2016.12.23]
### Added
- templates: python-script, shell-script, jinja2-test
- script: newfile (creates new file from templates)

