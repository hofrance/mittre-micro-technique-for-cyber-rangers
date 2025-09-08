# T1113.001A - Screen Capture: X11 Screenshots Linux

## Description
This package implements MITRE ATT&CK atomic micro-technique T1113.001A for Linux environments. Capture X11 desktop screenshots for reconnaissance and data collection.

## Technique Details
- **ID**: T1113.001A
- **Name**: Screen Capture: X11 Screenshots
- **Parent Technique**: T1113
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User**

## Manual Execution
```bash
export T1113_001A_OUTPUT_BASE="/tmp/mitre_results" && export T1113_001A_SILENT_MODE=false
chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: capture X11 desktop screenshots ONLY
- Scope: One specific capture action
- Dependency: Bash + X11/display access
- Privilege: User

## Environment Variables

### Configuration Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1113_001A_OUTPUT_BASE` | Base directory for results | `/tmp/mitre_results`, `/home/user/screenshots` | `/tmp/mitre_results` | Yes |
| `T1113_001A_OUTPUT_MODE` | Output verbosity level | `simple`, `debug`, `stealth`, `none` | `simple` | No |
| `T1113_001A_TIMEOUT` | Maximum execution time in seconds | `30`, `60`, `300`, `600` | `300` | No |
| `T1113_001A_DEBUG_MODE` | Enable debug logging | `true`, `false` | `false` | No |
| `T1113_001A_VERBOSE_LEVEL` | Verbosity level | `0` (silent), `1` (normal), `2` (verbose), `3` (debug) | `1` | No |

### Capture Variables
| Variable | Description | Values | Default | Required |
|----------|-------------|---------|---------|----------|
| `T1113_001A_CAPTURE_INTERVAL` | Interval between captures in seconds | `1`, `5`, `10`, `30` | `5` | No |
| `T1113_001A_MAX_SCREENSHOTS` | Maximum number of screenshots | `1`, `3`, `5`, `10` | `3` | No |
| `T1113_001A_IMAGE_FORMAT` | Screenshot image format | `png`, `jpg`, `bmp` | `png` | No |
| `T1113_001A_IMAGE_QUALITY` | Image quality (for JPEG) | `50`, `75`, `90`, `100` | `90` | No |

### Examples

#### Single Screenshot
```bash
export T1113_001A_OUTPUT_BASE="/tmp/screenshots"
export T1113_001A_MAX_SCREENSHOTS="1"
```

#### Multiple Screenshots with Interval
```bash
export T1113_001A_CAPTURE_INTERVAL="10"
export T1113_001A_MAX_SCREENSHOTS="5"
export T1113_001A_DEBUG_MODE="true"
```

#### Stealth Mode Capture
```bash
export T1113_001A_STEALTH_MODE="true"
export T1113_001A_MAX_SCREENSHOTS="1"
export T1113_001A_IMAGE_FORMAT="jpg"
export T1113_001A_IMAGE_QUALITY="75"
```

## Output Files
- `t1113_001a_x11_screenshots_[timestamp]/`: Directory containing screenshots
- `screenshots/`: Subdirectory with PNG image files
- `metadata/`: Subdirectory with capture information

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `bash` - Shell interpreter
- `jq` - JSON processor
- `bc` - Calculator utility

**Technique-Specific Dependencies:**
- `imagemagick` - Image processing utilities
- `x11-utils` - X11 utilities (xwininfo, xdpyinfo)
- `scrot` or `maim` - Screenshot utilities

### Installation Commands

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     bash bc jq imagemagick x11-utils scrot
```

#### CentOS/RHEL/Fedora
```bash
sudo dnf install -y \
     bash bc jq ImageMagick xorg-x11-utils scrot
```

#### Arch Linux
```bash
sudo pacman -S \
     bash bc jq imagemagick xorg-utils scrot
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```
