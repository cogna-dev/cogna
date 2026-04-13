# CodeIQ VSCode Extension

This extension shells out to the local `codeiq` CLI, reads `dist/check.sarif.json`, turns SARIF results into diagnostics, and opens rule documentation through stable `helpUri` links.

## Commands

- `CodeIQ: Run Analysis`
- `CodeIQ: Refresh Diagnostics`
- `CodeIQ: Open Rule Documentation`

## Settings

- `codeiq.cliPath`
- `codeiq.workingDirectory`
- `codeiq.runOnSave`
- `codeiq.autoOpenPolicyDocs`

## Local verification

```bash
npm install
npm run compile
npm run test
```
