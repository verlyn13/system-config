---
title: Renovate Config
category: reference
component: renovate_config
status: draft
version: 1.0.0
last_updated: 2025-09-26
tags: []
priority: medium
---

{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended",
    ":dependencyDashboard",
    ":semanticCommitTypeAll(deps)"
  ],
  "timezone": "America/Anchorage",
  "labels": ["dependencies", "automated"],
  "dependencyDashboard": true,
  "dependencyDashboardTitle": "Dependency Dashboard",
  "rangeStrategy": "bump",
  "prHourlyLimit": 6,
  "prConcurrentLimit": 10,
  "rebaseWhen": "conflicted",
  "stabilityDays": 2,
  "rollbackPrs": true,
  "semanticCommits": "enabled",
  "commitMessagePrefix": "deps:",
  
  "schedule": ["after 2am on sunday"],
  
  "separateMajorMinor": true,
  "separateMultipleMajor": true,
  "separateMinorPatch": false,
  
  "packageRules": [
    {
      "description": "Node.js dependencies",
      "matchManagers": ["npm", "pnpm", "yarn", "bun"],
      "groupName": "node dependencies",
      "reviewers": ["team:frontend"]
    },
    {
      "description": "Python dependencies",
      "matchManagers": ["uv", "pip_requirements", "poetry", "pip_setup", "pipenv"],
      "groupName": "python dependencies",
      "reviewers": ["team:backend"]
    },
    {
      "description": "Rust dependencies",
      "matchManagers": ["cargo"],
      "groupName": "rust dependencies"
    },
    {
      "description": "Go dependencies",
      "matchManagers": ["gomod"],
      "groupName": "go dependencies"
    },
    {
      "description": "Gradle/Android dependencies",
      "matchManagers": ["gradle", "gradle-wrapper"],
      "groupName": "android dependencies",
      "reviewers": ["team:mobile"]
    },
    {
      "description": "mise toolchain versions",
      "matchManagers": ["mise"],
      "groupName": "toolchain versions",
      "commitMessageTopic": "toolchain",
      "reviewers": ["team:devops"]
    },
    {
      "description": "GitHub Actions",
      "matchManagers": ["github-actions"],
      "groupName": "github actions",
      "automerge": true,
      "platformAutomerge": true
    },
    {
      "description": "Lockfile maintenance",
      "matchUpdateTypes": ["lockFileMaintenance"],
      "schedule": ["before 3am on monday"],
      "automerge": true,
      "platformAutomerge": true,
      "commitMessageAction": "update"
    },
    {
      "description": "Security patches - automerge",
      "matchUpdateTypes": ["patch"],
      "matchPackagePatterns": ["*"],
      "automerge": true,
      "platformAutomerge": true,
      "groupName": "security patches"
    },
    {
      "description": "Pin digests for Docker",
      "matchUpdateTypes": ["pin", "digest"],
      "automerge": true,
      "platformAutomerge": true
    },
    {
      "description": "Major version updates - require manual review",
      "matchUpdateTypes": ["major"],
      "dependencyDashboardApproval": true,
      "stabilityDays": 7,
      "prCreation": "not-pending"
    },
    {
      "description": "Node 24 - pin to LTS once available",
      "matchManagers": ["mise"],
      "matchPackageNames": ["node"],
      "allowedVersions": "24.x"
    },
    {
      "description": "Python 3.13+ only",
      "matchManagers": ["mise"],
      "matchPackageNames": ["python"],
      "allowedVersions": ">=3.13.0"
    }
  ],
  
  "postUpdateOptions": [
    "pnpmDedupe",
    "gomodTidy",
    "gomodUpdateImportPaths"
  ],
  
  "ignorePaths": [
    "**/node_modules/**",
    "**/vendor/**",
    "**/test/fixtures/**"
  ],
  
  "prBodyDefinitions": {
    "Package": "{{{depNameLinked}}}",
    "Type": "{{{depType}}}",
    "Update": "{{{updateType}}}",
    "Current value": "{{{currentValue}}}",
    "New value": "{{{newValue}}}",
    "Change": "`{{{displayFrom}}}` -> `{{{displayTo}}}`",
    "Pending": "{{{displayPending}}}",
    "References": "{{{references}}}",
    "Package file": "{{{packageFile}}}",
    "Release Notes": "{{{releases}}}"
  },
  
  "prBodyColumns": [
    "Package",
    "Type",
    "Update",
    "Change",
    "Release Notes"
  ]
}
