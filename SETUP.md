# Setup Instructions

This document outlines the steps to set up the Fedora devcontainer environment for both local development and use with
GitHub Codespaces.

## Prerequisites

* **Podman Desktop**: [Download and install Podman Desktop](https://podman-desktop.io/downloads). Ensure it is running
    and the Podman machine is started. (For local development)
* **Visual Studio Code (VS Code)**: [Download and install VS Code](https://code.visualstudio.com/).
* **Dev Containers Extension for VS Code**: Install the "Dev Containers" extension
    (identifier: `ms-vscode-remote.remote-containers`) from the VS Code Marketplace. You may also need to configure the
    Dev Containers extension to use Podman for local development (see VS Code settings: `dev.containers.dockerPath` can
    be set to `podman`).
* **Git**: Ensure Git is installed on your local machine for cloning the repository.
* **GitHub Account**: For using with GitHub Codespaces or GitHub Actions if you plan to use those features.

## Local Development Setup

1.  **Clone the Repository:**
    Open your terminal and clone the repository to your local machine:
    ```bash
    git clone <your-repository-url>
    cd <repository-name>
    ```
    Replace `<your-repository-url>` with the actual URL of the repository and `<repository-name>` with the name of the
    cloned directory.

2.  **Open in VS Code:**
    Launch Visual Studio Code and open the cloned repository folder:
    * Go to `File > Open Folder...`
    * Navigate to and select the `<repository-name>` directory.

3.  **Reopen in Container:**
    * Once the project is open, VS Code should detect the `.devcontainer/devcontainer.json` file. A notification
        toast will typically appear at the bottom right, suggesting "Reopen in Container." Click this button.
    * If you don't see the notification, or if you've dismissed it, you can manually trigger this action:
        * Open the Command Palette (Cmd+Shift+P on macOS, Ctrl+Shift+P on Windows/Linux).
        * Type `Dev Containers: Reopen in Container` and select it from the list.
    * The first time you do this, VS Code (using the Dev Containers extension and Podman) will build the container
        image as defined in the `Containerfile`. This process might take a few minutes as it downloads the base Fedora
        image and runs any setup commands.
    * Subsequent launches of the devcontainer will be much faster as the image will be cached.

4.  **Verify the Environment:**
    * After the container is built and VS Code has connected, a new VS Code window will open, attached to the
        devcontainer. The remote indicator in the bottom-left corner should show the name of your devcontainer (e.g.,
        "Dev Container: Fedora...").
    * Open a new terminal in VS Code (Ctrl+Shift+\` or `Terminal > New Terminal`). This terminal session is now running
        *inside* your Fedora container.
    * You can test the environment by running the sample script provided in the repository:
        ```bash
        # The workspace is typically mounted at /workspaces/<repository-name>
        cd /workspaces/$(basename $PWD)/sample-scripts 
        bash test-fedora.sh
        ```
    * Confirm the Fedora version:
        ```bash
        cat /etc/fedora-release
        ```
    * Test package management by installing a tool (e.g., `neofetch`):
        ```bash
        sudo dnf install -y neofetch
        neofetch
        ```

Your local Fedora devcontainer environment is now ready!

## Using Devcontainers with GitHub Repositories

The `.devcontainer` configuration in this repository allows for a consistent development environment not only locally but
also in cloud-based environments like GitHub Codespaces and for CI/CD pipelines with GitHub Actions.

### GitHub Codespaces

GitHub Codespaces provides cloud-powered development environments that you can configure using devcontainers.

1.  **Commit `.devcontainer` Folder**: Ensure the `.devcontainer` directory (containing `devcontainer.json` and your
    `Containerfile`) is committed and pushed to your GitHub repository.
2.  **Create a Codespace**:
    * Navigate to your repository on GitHub.com.
    * Click the green "<> Code" button.
    * Switch to the "Codespaces" tab.
    * Click "Create codespace on main" (or your desired branch). If you have multiple devcontainer configurations,
        you might be prompted to choose one.
3.  **Automatic Setup**: GitHub Codespaces will automatically detect and use the configuration in your `.devcontainer`
    folder to set up your development environment. This includes building the image from your `Containerfile` and
    applying all settings from `devcontainer.json`. This process is similar to the initial local build and may take a
    few minutes.
4.  **Develop in the Cloud**: Once the Codespace is ready, you can open it directly in your web browser (VS Code for the
    Web) or in your local VS Code desktop application. You will have the same Fedora environment, tools, and extensions
    as defined in your devcontainer configuration.

### GitHub Actions

You can also leverage your devcontainer definition in GitHub Actions workflows. While Actions don't directly "open" a
devcontainer in the same way Codespaces or VS Code do, you can use tools to run your workflow steps inside an environment
built from your `Containerfile`.

* **Build and Run**: You can use community actions (e.g., from the `devcontainers/ci` repository) or write script
    steps in your workflow to build the container image from your `Containerfile` and then execute commands (like tests,
    builds, linters) within that container.
    ```yaml
    # Example snippet for a GitHub Actions workflow
    # jobs:
    #   test:
    #     runs-on: ubuntu-latest
    #     steps:
    #       - uses: actions/checkout@v3
    #       - name: Build and run devcontainer task
    #         uses: devcontainers/ci@v0.3
    #         with:
    #           imageName: my-fedora-app # Optional: specify a name for the built image
    #           runCmd: bash -c "cd /workspaces/$(basename $PWD)/sample-scripts && ./test-fedora.sh"
    ```
* **Consistency**: This helps ensure that your CI/CD pipeline runs in an environment that closely matches your
    development environment, reducing "works on my machine" issues.

For more details, refer to the official documentation for
[GitHub Codespaces](https://docs.github.com/codespaces/overview) and
[GitHub Actions](https://docs.github.com/actions/learn-github-actions).