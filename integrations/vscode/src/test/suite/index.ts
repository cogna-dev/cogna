import * as path from "node:path"

import Mocha from "mocha"
import { glob } from "glob"

export function run(): Promise<void> {
  const mocha = new Mocha({
    color: true,
    timeout: 120000,
    ui: "tdd",
  })
  const testsRoot = __dirname

  return new Promise((resolve, reject) => {
    glob("**/*.test.js", { cwd: testsRoot })
      .then((files) => {
        for (const file of files) {
          mocha.addFile(path.resolve(testsRoot, file))
        }
        mocha.run((failures) => {
          if (failures > 0) {
            reject(new Error(`${failures} extension tests failed.`))
          } else {
            resolve()
          }
        })
      })
      .catch(reject)
  })
}
