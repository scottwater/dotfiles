const RM_RF_PATTERN = /(^|[;&|])\s*rm\s+(-[a-zA-Z]*[rR][a-zA-Z]*[fF]|-[a-zA-Z]*[fF][a-zA-Z]*[rR]|--recursive\s+--force|--force\s+--recursive)\s/

export const DenyRmRf = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") {
        return
      }

      const command = output?.args?.command ?? ""

      if (RM_RF_PATTERN.test(command)) {
        throw new Error("Refusing to run `rm -rf`. Use `trash` instead.")
      }
    }
  }
}
