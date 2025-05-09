# Onboarding to Konflux-CI for Image Build and Push

This document provides a step-by-step guide to onboard your Git repository (containing the Fedora devcontainer setup)
to Konflux-CI. The goal is to automate the build of your container image using the `Containerfile` and push the
resulting image to a custom repository in your Quay.io account (`quay.io/arewm/`).

## Prerequisites

Before you begin, ensure you have the following:

1.  **Access to a Konflux-CI Instance**: You should have credentials and access to a running Konflux-CI environment.
2.  **GitHub Repository**: Your project, including the `.devcontainer` directory with the `devcontainer.json` and
    `Containerfile`, must be pushed to a GitHub repository. Konflux-CI will add Tekton pipeline files (typically in a
    `.tekton/` directory) to this repository during the onboarding process.
3.  **Quay.io Account**: An active account on [Quay.io](https://quay.io/).
4.  **Quay.io Robot Account & Token**:
    * A robot account created under your Quay.io namespace (e.g., `arewm+konfluxbuilder`).
    * This robot account must have **write permissions** to the target image repository on Quay.io (e.g.,
        `quay.io/arewm/my-fedora-devcontainer`). If the repository doesn't exist, the robot account might need
        permissions to create repositories, or you may need to create it manually on Quay.io first.
    * The **token** associated with this robot account. Keep this token secure.
5.  **`kubectl` Access (Potentially)**: Depending on your Konflux-CI setup and permissions, you might need `kubectl`
    access to the Kubernetes cluster where Konflux-CI is running, specifically to create secrets in your development
    namespace.

## Step 1: Create Quay.io Robot Account and Token

1.  Log in to your Quay.io account.
2.  Navigate to your user/organization settings where Robot Accounts are managed.
3.  Create a new robot account (e.g., `arewm+konfluxbuilder`).
4.  Grant this robot account the necessary permissions:
    * At a minimum, **write access** to the specific repository you intend to push to (e.g., `arewm/my-fedora-devcontainer`).
    * Optionally, admin access if it needs to create the repository.
5.  Once created, Quay.io will display a token for the robot account. **Copy this token immediately and store it
    securely.** You will not be able to see it again.

## Step 2: Create Kubernetes Secret for Quay.io Credentials

Konflux-CI needs to authenticate with Quay.io to push images. This is typically done by creating a Kubernetes
`docker-registry` secret in the namespace where your Konflux-CI builds will run.

1.  Identify your Konflux-CI development namespace (ask your Konflux-CI administrator if unsure).
2.  Use `kubectl` to create the secret. Replace placeholders with your actual values:
    ```bash
    kubectl create secret docker-registry quay-arewm-robot-creds \
      --namespace <your-konflux-ci-dev-namespace> \
      --docker-server=quay.io \
      --docker-username='arewm+konfluxbuilder' \ # Your Quay.io robot account name
      --docker-password='<YOUR_QUAY_ROBOT_TOKEN_FROM_STEP_1>' \
      --docker-email='<your-email@example.com>' # An email address (can often be a dummy one)
    ```
    * `<your-konflux-ci-dev-namespace>`: The Kubernetes namespace used by Konflux-CI for your applications/builds.
    * `quay-arewm-robot-creds`: A suggested name for your secret.
    * `arewm+konfluxbuilder`: The full name of your Quay.io robot account.
    * `<YOUR_QUAY_ROBOT_TOKEN_FROM_STEP_1>`: The token you saved from Quay.io.

    **Note**: Some Konflux-CI setups might automatically link this secret to the build pipeline's service account if it's
    correctly named or annotated, or if the target registry matches. Consult your Konflux-CI documentation or admin.

## Step 3: Onboard Your Application to Konflux-CI

1.  Log in to your Konflux-CI dashboard.
2.  Look for an option like "Create Application," "Import Application," or "Add Component."
3.  Choose the option to import or create from a Git source.
4.  **Provide Repository URL**: Enter the HTTPS or SSH URL of your GitHub repository.
5.  Konflux-CI will analyze the repository and typically:
    * Detect your `Containerfile` (or Dockerfile).
    * Create and push initial Tekton `PipelineRun` files (e.g., for push and pull request events) to a `.tekton/`
      directory in your repository. These initial `PipelineRun` files will likely reference a default build pipeline
      bundle provided by Konflux-CI (like `docker-build-multi-platform-oci-ta`).

## Step 4: Configure and Customize the Build

After Konflux-CI has onboarded your component and potentially pushed initial Tekton files, you will configure and
customize the build process. This involves editing the `PipelineRun` files in your repository and, optionally,
creating a local, version-controlled `Pipeline` definition.

1.  **Review Initial `PipelineRun` Files**:
    * Pull the changes from your Git repository to get the `.tekton/` directory and `PipelineRun` files created by Konflux-CI.
    * Examine these files. They will contain placeholders (like `{{revision}}`, `{{source_url}}`) that Konflux-CI's
      Pipelines-as-Code controller will replace at runtime.

2.  **(Optional but Recommended) Centralize Pipeline Definition**:
    * To reduce duplication and have better control over the pipeline logic, you can extract the common pipeline
      definition into a local `.tekton/build-pipeline.yaml` file.
    * Populate this file with the desired Tekton `Pipeline` spec (e.g., the `docker-build-multi-platform-oci-ta`
      definition, modified as per your requirements for dynamic labeling and tagging).
    * Update your `PipelineRun` files (e.g., `devcontainer-playground-push.yaml`,
      `devcontainer-playground-on-pull-request.yaml`) to use `pipelineRef: { name: build-pipeline }` (or whatever
      name you give your pipeline in `build-pipeline.yaml`), removing any embedded `pipelineSpec`.

3.  **Configure `PipelineRun` Parameters**:
    Edit your `PipelineRun` files in the `.tekton/` directory to:
    * **Source Configuration**: Ensure `git-url` and `revision` params use the correct PaC variables.
    * **Output Image**: Set `output-image` to your Quay.io path (e.g., `quay.io/arewm/devcontainer-playground:{{revision}}`).
    * **Containerfile/Context**: Set `dockerfile` to `.devcontainer/Containerfile` and `path-context` appropriately.
    * **`artifact-version`**: Pass the `artifact-version` parameter to your `build-pipeline`. This is crucial for the
      dynamic labeling and tagging logic within your customized `build-pipeline.yaml`.
        * For push builds: `value: '{{target_branch}}'`
        * For PR builds: `value: '{{target_branch}}-pr'` (or similar PR-specific logic)
    * **Other Parameters**: Adjust other parameters like `build-platforms`, `skip-checks`, etc., as needed for push vs. PR
      builds. Comment out parameters in the `PipelineRun` if their values match the defaults in your
      `build-pipeline.yaml`.

4.  **Configure Workspaces (in `PipelineRun` files)**:
    * Ensure the `git-auth` workspace correctly references your `{{git_auth_secret}}` if your repository is private.
    * Define other workspaces (like `netrc` or a PVC-backed `workspace` for source code) only if explicitly required by
      your `build-pipeline.yaml` and your build process. For simple builds without PVCs, Tekton often provides
      ephemeral storage for tasks.

5.  **Commit Changes**: Commit and push all modifications to your `.tekton/` directory (the new `build-pipeline.yaml`
    and updated `PipelineRun` files) to your Git repository.

## Step 4a: Understanding Advanced Configuration (Dynamic Labeling and Tagging)

Your `build-pipeline.yaml` (if you've centralized and customized it) is now set up to handle dynamic labeling and tagging:

1.  **Multi-Platform Build**: The `build-platforms` parameter (passed from the `PipelineRun`) controls this.
2.  **Dynamic Image Labeling**: The `generate-image-labels` task within `build-pipeline.yaml` uses the `artifact-version`
    (from `PipelineRun`) and commit timestamp (from `clone-repository` task) to create labels like `build-date`, `release`,
    and `version`.
3.  **Dynamic Image Tagging**: The `apply-tags` task within `build-pipeline.yaml` uses the `artifact-version` and commit
    timestamp to create additional tags. The primary image tag (commit SHA) is set via the `output-image` parameter in
    the `PipelineRun`.

## Step 5: Trigger and Monitor the Build

1.  Konflux-CI, through Pipelines-as-Code, should automatically detect changes to the `.tekton/` directory in your
    repository (on the configured branches, e.g., `main`) and trigger new builds using your updated `PipelineRun` and
    `Pipeline` definitions.
2.  Monitor the build progress in the Konflux-CI dashboard. Pay attention to the logs of `generate-image-labels`,
    `build-images`, and `apply-tags` tasks to verify the dynamic metadata.

## Step 6: Verify the Image in Quay.io

1.  Once the Konflux-CI build pipeline completes successfully, log in to your Quay.io account.
2.  Navigate to the repository you specified.
3.  **Verify Tags**: Check that all expected tags are present (e.g., the commit SHA tag, `{{target_branch}}`,
    `{{target_branch}}-<commit-timestamp>`).
4.  **Verify Labels**: Inspect the image configuration to ensure your dynamic labels (`build-date`, `release`, `version`)
    are correctly applied.
5.  **Verify Multi-Platform**: Quay.io should indicate if the image is a multi-architecture manifest list.

## Troubleshooting Common Issues

* **Build Fails in Konflux-CI**:
    * Examine build logs, especially from `generate-image-labels`, `build-images`, and `apply-tags`.
* **Authentication Failure to Quay.io**:
    * Verify robot account credentials and permissions.
    * Ensure the Kubernetes secret is correct and in the right namespace.
* **Image Not Found in Quay.io**:
    * Double-check `output-image` and tag configurations.
* **Dynamic Variables Not Resolving / Incorrect Labels or Tags**:
    * Confirm PaC variables (`{{target_branch}}`, `{{revision}}`, etc.) are correctly used in `PipelineRun` files.
    * Verify `artifact-version` is passed correctly to `build-pipeline.yaml`.
    * Check logs of `clone-repository`, `generate-image-labels`, and `apply-tags` tasks.

For more specific troubleshooting, refer to your Konflux-CI instance's documentation or seek support from its
administrators.
