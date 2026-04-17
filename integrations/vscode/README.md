# Cogna VSCode Extension

This extension shells out to the local `cogna` CLI, reads `dist/check.sarif.json`, turns SARIF results into diagnostics, and opens rule documentation through stable `helpUri` links.

## Commands

- `Cogna: Run Analysis`
- `Cogna: Refresh Diagnostics`
- `Cogna: Open Rule Documentation`

## Settings

- `cogna.cliPath`
- `cogna.workingDirectory`
- `cogna.runOnSave`
- `cogna.autoOpenPolicyDocs`

## Local verification

```bash
npm install
npm run compile
npm run test
```
