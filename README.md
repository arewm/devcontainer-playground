# Fedora Devcontainer on macOS: Sample Repository

This repository demonstrates how to set up and use a Development Container (devcontainer) with Visual Studio Code to run
Fedora-native tooling on a macOS host. This approach avoids the need for managing a full Virtual Machine.

## Overview

Devcontainers provide isolated, reproducible, and fully-configured development environments. By using a Fedora-based
devcontainer, you can seamlessly work with tools and packages that are specific to the Fedora Linux distribution
directly from your Mac.

## Contents

* **`.devcontainer/`**: This directory contains the configuration for the development container.
    * **`devcontainer.json`**: The primary configuration file.
    * **`Containerfile`**: Used to build the custom Fedora container image.
* **`.vscode/`**: Contains workspace-specific VS Code settings.
    * **`settings.json`**: Recommended settings for this project.
* **`sample-scripts/`**: Contains example scripts.
    * **`test-fedora.sh`**: An example script to verify the Fedora environment.
* **`README.md`**: This file.
* **`SETUP.md`**: Detailed instructions for setting up the devcontainer environment locally and with GitHub.
* **`CUSTOMIZATION.md`**: Guide on how to customize the devcontainer.
* **`TROUBLESHOOTING.md`**: Solutions for common issues.
* **`KONFLUX_CI_ONBOARDING.md`**: Guide for onboarding this repository to Konflux-CI.
* **`.gitignore`**: To exclude unnecessary files from version control.
* **`LICENSE`**: Contains the Apache License 2.0 for this project.

For detailed instructions, please refer to the following files:

* **[Setup Instructions](./SETUP.md)**
* **[Customization Guide](./CUSTOMIZATION.md)**
* **[Troubleshooting Tips](./TROUBLESHOOTING.md)**
* **[Konflux-CI Onboarding Guide](./KONFLUX_CI_ONBOARDING.md)**

## How it Works (Local and Codespaces)

The Dev Containers extension in VS Code (or GitHub Codespaces service) reads the `devcontainer.json` file.
1.  It uses the specified container image (or builds one from the `Containerfile` using the configured container runtime)
    to create a container.
2.  It mounts your project workspace into the container.
3.  It installs any specified VS Code extensions inside the container, so they operate within the Fedora environment.
4.  It forwards specified ports from the container to your host machine (or makes them accessible in Codespaces).
5.  VS Code then connects to this container, allowing you to edit code locally while commands, debugging, and terminals run
    inside the isolated Fedora environment.

## Benefits

* **Isolation**: Keep your host system clean. All Fedora-specific tools and dependencies are within the container.
* **Consistency**: Ensure everyone on a project uses the exact same development environment, whether locally or in the
  cloud.
* **Reproducibility**: Easily recreate the development environment on any machine or in any Codespace.
* **Full-Featured IDE**: Leverage all the power of VS Code, including IntelliSense, debugging, and extensions, tailored
  to the containerized environment.

---

## Acknowledgements

The structure and initial content of this repository, including this `README.md`, `devcontainer.json`, `Containerfile`,
`.vscode/settings.json`, sample scripts, `SETUP.md`, `CUSTOMIZATION.md`, `TROUBLESHOOTING.md`,
`KONFLUX_CI_ONBOARDING.md`, and `LICENSE` file, were created with the assistance of Google's Gemini.

---

This `README.md` provides a high-level overview. For detailed information, please consult the linked Markdown files.
