# T1123.004A - System Audio Capture

## Description
This package implements MITRE ATT&CK atomic micro-technique T1123.004A for Linux environments. Capture system audio output for surveillance.

## Technique Details
- **ID**: T1123.004A
- **Name**: System Audio Capture
- **Parent Technique**: T1123
- **Tactic**: TA0009 - Collection
- **Platform**: Linux
- **Permissions Required**: **User** (audio access)

## Manual Execution
```bash
export T1123_004A_OUTPUT_BASE="/tmp/mitre_results" && chmod +x src/main.sh && ./src/main.sh
```

## Atomic Action
**Single Observable Action**: capture system audio ONLY

## Environment Variables
- `T1123_004A_AUDIO_FORMAT`: Audio format [wav/mp3/ogg/flac] (default: wav)
- `T1123_004A_CHANNELS`: Configuration parameter (default: 2)
- `T1123_004A_MAX_RECORDINGS`: Configuration parameter (default: 3)
- `T1123_004A_OUTPUT_BASE`: Base directory for results (default: /tmp/mitre_results)
- `T1123_004A_OUTPUT_MODE`: Output mode [simple/debug/stealth/none] (default: simple)
- `T1123_004A_RECORDING_DURATION`: Configuration parameter (default: 5)
- `T1123_004A_SAMPLE_RATE`: Configuration parameter (default: 44100)
- `T1123_004A_SILENT_MODE`: Enable silent execution [true/false] (default: false)
- `T1123_004A_TIMEOUT`: Timeout in seconds (default: 300)

## Dependencies

### Required Tools
This technique requires the following tools to be installed:

**Core Dependencies:**
- `bash` - Shell interpreter
- `jq` - JSON processor  
- `bc` - Calculator utility
- `grep` - Text search utility
- `find` - File search utility

**Technique-Specific Dependencies:**
- `alsa-utils` - ALSA sound system utilities (arecord, aplay)
- `pulseaudio-utils` - PulseAudio utilities (pactl, pacmd)

### Installation Commands

#### Alternative Tools (Built-in Fallbacks)
If the primary media tools are not available, the package includes automatic fallbacks:
- **arecord**: ALSA recording utility (audio packages)
- **pactl**: PulseAudio control (audio packages)
- **Basic device detection**: Automatic /dev/video0 detection (video packages)
- **Simulation mode**: Works without hardware when needed

**Enhanced Dependencies** (now supported):
- `ffmpeg` - Primary multimedia framework (recommended)
- `arecord` - ALSA recording alternative  
- `pactl` - PulseAudio utilities alternative

**Note**: The package will automatically use the best available method.

#### Ubuntu/Debian
```bash
sudo apt-get update && sudo apt-get install -y \
     alsa-utils bash bc find grep jq pulseaudio-utils
```

#### CentOS/RHEL/Fedora  
```bash
sudo dnf install -y \
     alsa-utils bash bc find grep jq pulseaudio-utils
```

#### Arch Linux
```bash
sudo pacman -S \
     alsa-utils bash bc find grep jq pulseaudio-utils
```

**Note:** If dependencies are missing, you'll see:
```bash
# [ERROR] Missing dependency: <tool_name>
```

