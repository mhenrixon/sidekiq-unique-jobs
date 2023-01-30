module.exports = {
  extends: ["stylelint-config-standard"],
  rules: {
    "at-rule-no-unknown": [
      true,
      {
        ignoreAtRules: [
          "tailwind",
          "apply",
          "variants",
          "responsive",
          "screen",
          "layer"
        ]
      }
    ],
    "declaration-block-trailing-semicolon": null,
    "function-no-unknown": [
      true,
      {
        ignoreFunctions: [/image-(url|path)/]
      }
    ],
    "no-descending-specificity": null,
    "selector-class-pattern": /(_?[a-z][a-z0-9]*)(-+[a-z0-9]+)*$/
  }
}
