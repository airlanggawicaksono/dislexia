# Taste (Continuously Learned by [CommandCode][cmd])

[cmd]: https://commandcode.ai/

# nginx
- Serve `.wasm` files with `application/wasm` MIME type only — do NOT use `application/octet-stream` for WASM files. Confidence: 0.80

# deployment
- Do not restart, stop, or modify production containers/services without first asking for user confirmation. Confidence: 0.70
- Rebuild Docker images via CI/CD GitHub workflow, not by running docker build manually over SSH. Confidence: 0.65

