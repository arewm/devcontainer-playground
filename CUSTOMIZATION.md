# Customizing Your Devcontainer Environment

The Fedora devcontainer environment is defined by the files in the `.devcontainer` directory. You can customize it to
suit your project's specific needs.

## Key Configuration Files

* **`.devcontainer/devcontainer.json`**: This is the primary configuration file for the Dev Containers extension. It
    defines aspects like the container image to use, VS Code extensions to install inside the container, ports to
    forward, lifecycle scripts, and user interface settings for VS Code when connected to the container.
* **`.devcontainer/Containerfile`** (or `Dockerfile`): This file contains the instructions to build your custom Fedora
    container image. You can specify the base Fedora image, install system packages, add files, set environment
    variables, and configure users.

## Customizing `devcontainer.json`

Here are some common customizations you can make in `devcontainer.json`:

* **Change Fedora Version or Base Image**:
    Modify the `image` property (if using a pre-built image) or the `build.dockerfile` and `build.args` (if building
    from a `Containerfile`) to use a different Fedora version or a more specialized base image.
    ```json
    // Example: Using a specific Fedora version image directly
    // "image": "fedora:39",

    // Example: Building a specific version via Containerfile arg
    // "build": {
    //   "dockerfile": "Containerfile",
    //   "args": { "FEDORA_VERSION": "39" }
    // },
    ```

* **Install VS Code Extensions**:
    Add VS Code extension IDs to the `customizations.vscode.extensions` array. These extensions will be automatically
    installed inside the devcontainer, not on your local VS Code.
    ```json
    "customizations": {
        "vscode": {
            "extensions": [
                "ms-python.python",         // For Python development
                "redhat.java",              // For Java development
                "dbaeumer.vscode-eslint"    // For JavaScript/TypeScript linting
            ]
        }
    }
    ```

* **Add Devcontainer Features**:
    "Features" are self-contained units of installation code and dev container configuration. They allow you to easily
    add common tools (like Docker client, kubectl, specific language runtimes) without complex `Containerfile` scripting.
    Browse available features at [containers.dev/features](https://containers.dev/features).
    ```json
    "features": {
        "ghcr.io/devcontainers/features/node:1": { // Adds Node.js
            "version": "lts"
        },
        "ghcr.io/devcontainers/features/docker-in-docker:2": {} // Adds Docker CLI within the container
    }
    ```

* **Forward Ports**:
    If your application listens on specific ports, list them in `forwardPorts`. These ports will be automatically
    forwarded from the container to your local machine.
    ```json
    "forwardPorts": [3000, 8080], // Forwards ports 3000 and 8080
    ```

* **Lifecycle Scripts**:
    * `postCreateCommand`: Runs once after the container is created. Ideal for installing project dependencies (e.g.,
        `npm install`, `pip install -r requirements.txt`) or running initial setup scripts.
    * `postStartCommand`: Runs every time the container starts.
    * `postAttachCommand`: Runs every time VS Code attaches to the container.
    ```json
    "postCreateCommand": "sudo dnf install -y my-custom-tool && npm install"
    ```

* **VS Code Settings**:
    You can define container-specific VS Code settings under `customizations.vscode.settings`. These will override your
    user/workspace settings when connected to the container.
    ```json
    "customizations": {
        "vscode": {
            "settings": {
                "editor.formatOnSave": true,
                "python.defaultInterpreterPath": "/usr/local/bin/python"
            }
        }
    }
    ```

* **Remote User**:
    By default, the `common-utils` feature often creates a non-root user named `vscode`. You can specify a different
    user with `remoteUser`. Running as non-root is generally recommended.
    ```json
    "remoteUser": "vscode" // or "root" if absolutely necessary for initial setup
    ```

## Customizing `Containerfile`

The `Containerfile` gives you full control over the operating system image.

* **Install System Packages**:
    Use `RUN dnf install -y <package-name>` to add any Fedora packages your project requires. Always combine `dnf update`
    and `dnf install` with `dnf clean all` in the same `RUN` instruction to reduce image layer size.
    ```dockerfile
    RUN dnf update -y && \
        dnf install -y \
            gcc \
            make \
            openssl-devel \
            libffi-devel \
        && dnf clean all
    ```

* **Add Custom Scripts or Configuration Files**:
    Use the `COPY` instruction to add files from your project's `.devcontainer` directory (or other locations in your
    build context) into the container image.
    ```dockerfile
    COPY my-custom-script.sh /usr/local/bin/my-custom-script
    RUN chmod +x /usr/local/bin/my-custom-script && my-custom-script
    ```

* **Set Environment Variables**:
    Use the `ENV` instruction to set environment variables that will be available within the container.
    ```dockerfile
    ENV MY_APP_ENV=development
    ENV PATH="/usr/local/node/bin:${PATH}"
    ```

* **User Configuration**:
    While features often handle user setup, you can manually create users and groups if needed.
    ```dockerfile
    # ARG USERNAME=myuser
    # RUN groupadd mygroup && useradd -ms /bin/bash -g mygroup ${USERNAME}
    # USER ${USERNAME}
    ```

After making changes to `devcontainer.json` or your `Containerfile`, you'll need to rebuild the devcontainer for the
changes to take effect. In VS Code, open the Command Palette and select `Dev Containers: Rebuild Container`.