
# MITRE ATT&CK Micro-Techniques Repository

This repository contains atomic implementations of MITRE ATT&CK techniques, decomposed into micro-techniques for precise adversarial behavior simulation and cybersecurity training.

## Overview

The project implements MITRE ATT&CK techniques as atomic, observable actions called "micro-techniques". Each micro-technique performs exactly one function with standardized contracts, behavioral validation, and multi-modal outputs.

## Key Features

- **Atomic Decomposition**: Each technique performs exactly one observable action
- **Behavioral Contracts**: Standardized pre/post-conditions for validation
- **Multi-Platform Support**: Linux and Windows implementations
- **Contract-Driven Architecture**: 4-function architecture (Configuration, Precondition, Action, Verification)
- **Multi-Modal Outputs**: JSON, XML, and human-readable formats
- **Evasion-Aware**: Built-in IDS/IPS evasion techniques

## Project Statistics

- **Total Micro-Techniques**: 250+
- **Categories**: Reconnaissance, Collection, Defense Evasion, Discovery
- **Platforms**: Linux (primary), Windows (secondary)
- **Architecture**: Contract-driven with 4-phase execution
- **Output Formats**: JSON, XML, human-readable

### Category Breakdown
- **Reconnaissance**: 30+ techniques (Linux-focused)
- **Collection**: 65+ techniques (Windows-focused)
- **Defense Evasion**: 65+ techniques (Cross-platform)
- **Discovery**: 90+ techniques (Linux-focused)

## Repository Structure

```
micro-technique/
├── reconnaissance/          # TA0043 - Reconnaissance techniques
│   └── linux/              # Linux implementations
├── collection/             # TA0009 - Collection techniques
│   ├── linux/             # Linux implementations
│   └── windows/           # Windows implementations
├── defense-evasion/        # TA0005 - Defense Evasion techniques
│   ├── linux/             # Linux implementations
│   └── windows/           # Windows implementations
└── discovery/              # TA0007 - Discovery techniques
    ├── linux/             # Linux implementations
    └── windows/           # Windows implementations
```

## Architecture

Each micro-technique follows a standardized 4-phase contract:

1. **Get-Configuration**: Environment variable validation and setup
2. **Precondition-Check**: Network/tool validation and requirements check
3. **Atomic-Action**: Execute the single observable action with evasion
4. **Postcondition-Verify**: Results validation and cleanup

## Usage Examples

### Basic Usage
```bash
# Navigate to technique directory
cd reconnaissance/linux/t1595.001a-scanning_ip_blocks-stealth_syn_scan-linux/

# Configure environment variables
export t1595.001a_TARGETS="192.168.1.0/24"
export t1595.001a_OUTPUT_MODE="simple"

# Execute the micro-technique
./src/main.sh
```

### Advanced Configuration
```bash
# Stealth mode with evasion
export t1595.001a_OUTPUT_MODE="stealth"
export t1595.001a_EVASION_LEVEL="maximum"
export t1595.001a_TIMING_TEMPLATE="paranoid"
./src/main.sh
```

## Output Formats

### JSON Results
```json
{
  "technique_id": "t1595.001a",
  "technique_name": "scanning_ip_blocks-stealth_syn_scan-linux",
  "scan_timestamp": "2024-01-15T10:30:00Z",
  "targets": "192.168.1.0/24",
  "results": {
    "hosts_discovered": 15,
    "ports_found": 23,
    "scan_duration_seconds": 45.2
  }
}
```

### XML Technical Details
Complete Nmap XML output with full technical information.

### Human-Readable Output
```
[INFO] Stealth scan started
[INFO] Targets: 192.168.1.0/24
[INFO] Found 15 hosts, 23 ports open
[INFO] Results saved to: /tmp/mitre_results/t1595.001a_results.json
```

## Configuration Options

### Core Configuration
- `*_TARGETS`: Target specification (IP/range/file)
- `*_OUTPUT_MODE`: Output mode (simple/debug/stealth/silent)
- `*_OUTPUT_BASE`: Base output directory

### Evasion & Security
- `*_EVASION_LEVEL`: Evasion intensity (none/basic/advanced/maximum)
- `*_TIMING_TEMPLATE`: Nmap timing (paranoid/sneaky/polite)
- `*_RATE_LIMIT`: Packets per second limit

### Network & Performance
- `*_TIMEOUT`: Individual probe timeout
- `*_MAX_RETRIES`: Maximum retry attempts
- `*_PARALLELISM`: Parallel scan groups

## Dependencies

### Required
- **bash**: 4.0+ (script execution)
- **nmap**: 7.0+ (network scanning)

### Optional
- **sudo**: For privileged operations
- **jq**: JSON processing
- **xmlstarlet**: XML parsing

## Security Considerations

### Evasion Techniques
- Timing control and rate limiting
- Packet fragmentation
- Decoy host injection
- Source port spoofing
- IDS signature avoidance

### Operational Security
- Minimal network footprint
- DNS resolution control
- Clean exit handling
- Complete audit trails
- Forensic-ready logging

## Error Handling

### Return Codes
- `0`: Success
- `1`: Configuration error
- `2`: Precondition failed
- `3`: Execution error
- `4`: Postcondition error
- `124`: Timeout
- `130`: User interrupt

## Academic Context

This repository is part of a research project on micro-technique decomposition for cyber range training at the Norwegian Cyber Range (NCR). The implementations follow academic standards for:

- Atomic decomposition of adversarial behaviors
- Standardized environment variable patterns
- Contract-driven software architecture
- Multi-modal output capabilities
- Research reproducibility

## Citation

If you use this work in your research:

```
BANKOUEZI, Richard. "Deputy in the Norwegian Cyber Range: From ATT&CK Techniques to Micro-Techniques for Reusable, Policy-Aware Adversary Emulation." 2025.
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

**Richard BANKOUEZI**  
Email: contact@richard-hofrance.com  
Institution: Norwegian Cyber Range (NCR)  
Research: Micro-Technique Decomposition for Cyber Training

## Contributing

This project follows strict standards for:
- Atomic behavior decomposition
- Standardized contract patterns
- Security-first implementation
- Academic reproducibility
- Cross-platform compatibility
