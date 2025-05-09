# Troubleshooting Devcontainer Issues

This guide provides solutions to common issues you might encounter when working with the Fedora devcontainer setup,
both locally with Podman and in GitHub Codespaces.

## Local Development (Podman on macOS)

* **Issue: Podman Not Running or Machine Not Started**
    * **Symptom**: VS Code fails to connect to the container, errors related to Docker daemon or Podman socket.
    * **Solution**:
        1.  Ensure Podman Desktop is running.
        2.  Open a terminal and start the Podman machine if it's not already running:
            ```bash
            podman machine start
            ```
        3.  Verify the Podman machine status:
            ```bash
            podman machine ls
            ```
            Ensure the desired machine is in the "Running" state.
        4.  Check Podman service status:
            ```bash
            podman info
            ```
            This should execute without errors.

* **Issue: VS Code Podman Configuration**
    * **Symptom**: VS Code doesn't seem to use Podman, or you see errors indicating it's trying to use Docker.
    * **Solution**:
        1.  Explicitly tell the Dev Containers extension where to find Podman.
        2.  Open VS Code settings (File > Preferences > Settings or Code > Settings > Settings).
        3.  Search for `Dev > Containers: Docker Path`.
        4.  Set this value to `podman`. If `podman` is not in your system's PATH, provide the full path to the
            Podman executable (e.g., `/opt/podman/bin/podman` or `/usr/local/bin/podman`, check your Podman installation).
        5.  Restart VS Code.

* **Issue: Container Build Failures**
    * **Symptom**: The "Reopen in Container" process fails during the image build phase. Error messages appear in the
        VS Code output panel (usually under "Dev Containers" or "Docker" logs).
    * **Solution**:
        1.  **Examine Logs**: Carefully read the error messages in the VS Code output panel. They often pinpoint the
            exact instruction in your `Containerfile` (or a feature script) that failed.
        2.  **`Containerfile` Syntax**: Double-check your `Containerfile` for syntax errors.
        3.  **Package Installation Failures**: If a `dnf install` command fails, it could be due to:
            * Typo in a package name.
            * Package not available in configured repositories (you might need to enable additional repos or find an
                alternative package).
            * Network issues preventing package downloads.
            * Conflicts between packages.
        4.  **Feature Failures**: If a devcontainer feature fails to install, check the feature's documentation or GitHub
            repository for known issues or required prerequisites.
        5.  **Permissions**: Ensure commands in your `Containerfile` that require root privileges (like `dnf install`)
            are run as root (which is default for `RUN` instructions unless `USER` is changed).
        6.  **Resource Limits**: Ensure Podman has sufficient resources (CPU, memory, disk space) allocated, especially
            if building a large image or installing many packages. Configure this in Podman Desktop settings.

* **Issue: Extension Conflicts or Failures within Container**
    * **Symptom**: VS Code extensions listed in `devcontainer.json` fail to install or don't work correctly inside the
        container.
    * **Solution**:
        1.  **Check Extension Logs**: VS Code often provides logs for individual extension activations.
        2.  **Compatibility**: Some VS Code extensions might have native components that are not compatible with the
            Linux/glibc version in the Fedora container. Check the extension's documentation for compatibility notes.
        3.  **Dependencies**: An extension might require specific system libraries or tools to be present in the
            container. You may need to add these to your `Containerfile`.
        4.  **Try Disabling Host Extensions**: Rarely, a locally installed VS Code extension might interfere. Try running
            VS Code with extensions disabled (`code --disable-extensions`) and then reopening in the container to see if
            the issue persists.

* **Issue: Slow Performance**
    * **Symptom**: The devcontainer feels sluggish, file operations are slow, or builds take an excessive amount of time.
    * **Solution**:
        1.  **Resource Allocation**: Increase CPU, memory, and disk space allocated to the Podman machine in Podman Desktop.
        2.  **File System Performance (macOS)**: File sharing between macOS and Linux VMs can sometimes be a bottleneck.
            * Ensure you are using the latest version of Podman Desktop, which often includes performance improvements.
            * For I/O intensive tasks, consider if some operations can be performed entirely within the container's
                native filesystem rather than on the mounted workspace.
        3.  **`.containerignore` / `.dockerignore`**: Ensure you have a `.containerignore` (or `.dockerignore`) file at
            the root of your project to exclude unnecessary files/directories (like `node_modules`, build artifacts from
            the host) from being copied into the container's build context or watched by VS Code. This can significantly
            speed up builds and reduce resource usage.

## GitHub Codespaces

* **Issue: Codespace Creation Failure**
    * **Symptom**: GitHub Codespaces fails to build the environment.
    * **Solution**:
        1.  **Check Build Logs**: Similar to local builds, GitHub Codespaces provides detailed logs. Access these from the
            Codespace creation page or the Codespaces management tab in your repository.
        2.  **`Containerfile` / `devcontainer.json` Errors**: The same types of errors that occur locally can occur in
            Codespaces (package not found, script errors, etc.).
        3.  **Repository Access/Secrets**: If your build process needs to clone other private repositories or access secrets,
            ensure your Codespace has the necessary permissions and secrets configured.
        4.  **Resource Limits**: Codespaces have machine types with varying resources. If your build is resource-intensive,
            you might need a larger machine type (configurable in `devcontainer.json` or organization settings).
            ```json
            // In devcontainer.json, to request a larger machine
            // "hostRequirements": {
            //   "cpus": 4,
            //   "memory": "8gb",
            //   "storage": "32gb"
            // }
            ```
        5.  **Billing/Quotas**: Ensure your GitHub account or organization has an active billing setup for Codespaces and
            that you haven't exceeded your usage quotas.

* **Issue: Extensions Not Working in Codespace**
    * **Symptom**: VS Code extensions specified in `devcontainer.json` are missing or malfunctioning.
    * **Solution**:
        1.  Verify the extension IDs in `devcontainer.json` are correct.
        2.  Check the "Remote - WSL/Containers/Codespaces" output channel in VS Code (when connected to the Codespace)
            for extension installation errors.
        3.  Some extensions might behave differently or have limitations in a web-based VS Code environment compared to
            the desktop application.

## General Tips

* **Rebuild Container**: If you've made changes to `devcontainer.json` or `Containerfile`, always rebuild the container
    for changes to take effect. (Command Palette: `Dev Containers: Rebuild Container`).
* **Clean Rebuild**: For persistent issues, try a full clean rebuild. (Command Palette:
    `Dev Containers: Rebuild Without Cache` or manually prune Podman images/volumes if necessary).
* **Check Dev Containers Logs**: The Dev Containers output channel in VS Code is your primary source for diagnosing issues.
* **Simplify**: If you're facing complex issues, temporarily simplify your `devcontainer.json` and `Containerfile` to a
    minimal configuration to isolate the problem. Then, incrementally add back your customizations.
* **Consult Documentation**: Refer to the official [VS Code Dev Containers documentation](https://code.visualstudio.com/docs/devcontainers/containers)
    and [Podman documentation](https://docs.podman.io/) for more in-depth information.