# Onboarding to Konflux-CI for Image Build and Push

This document provides a step-by-step guide to onboard your Git repository (containing the Fedora devcontainer setup)
to Konflux-CI. The goal is to automate the build of your container image using the `Containerfile` and push the
resulting image to a custom repository in your Quay.io account (`quay.io/arewm/`).

## Prerequisites

Before you begin, ensure you have the following:

1.  **Access to a Konflux-CI Instance**: You should have credentials and access to a running Konflux-CI environment.
2.  **GitHub Repository**: Your project, including the `.devcontainer` directory with the `devcontainer.json` and
    `Containerfile`, must be pushed to a GitHub repository.
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

If you haven't already, create a robot account on Quay.io:

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
2.  Look for an option like "Create Application," "Import Application," or "Add Component." The exact terminology may vary.
3.  Choose the option to import or create from a Git source.
4.  **Provide Repository URL**: Enter the HTTPS or SSH URL of your GitHub repository (e.g.,
    `https://github.com/your-username/your-repo-name.git`).
5.  Konflux-CI will typically analyze the repository. It should detect the `Containerfile` (or `Dockerfile`). If it
    prompts for the path, ensure it's correct (e.g., `./.devcontainer/Containerfile`).
    Upon successful onboarding, Konflux-CI will typically push a `.tekton/` directory to your repository containing the
    generated `PipelineRun` definition. This `PipelineRun` will reference Tekton tasks (like `git-clone-oci-ta`) from
    Tekton Bundles, often pinned to specific digests from a registry like `quay.io/organization/konflux-ci`.

## Step 4: Configure the Build Pipeline (Component Settings)

After the application or component is recognized by Konflux-CI, you'll need to configure its build settings.

1.  Navigate to the component's settings or build configuration page in the Konflux-CI UI.
2.  **Source Configuration**:
    * Verify the **Git Source URL** and the **Branch** (e.g., `main`, `develop`) to build from.
    * Ensure the **Context Directory** is correct if your `Containerfile` is not at the root (e.g., `./.devcontainer`).
    * Confirm the **Containerfile Path** (or Dockerfile Path) points to your `Containerfile` (e.g.,
        `.devcontainer/Containerfile`).

3.  **Build Pipeline Selection**:
    * Select the `docker-build-multi-platform-oci-ta` pipeline (or a similarly named pipeline for multi-platform
        Docker/OCI image builds). This pipeline is designed to build images for multiple architectures (e.g., amd64, arm64).

4.  **Output Image Configuration**:
    * **Image Repository / Name**: Set this to your desired Quay.io image path.
        Example: `quay.io/arewm/my-fedora-devcontainer`
        (Replace `my-fedora-devcontainer` with your preferred image name).
    * **Initial Image Tag**: Specify a default tag, e.g., `latest`. Additional dynamic tags will be configured in the
        next step.

5.  **Registry Credentials / Authentication**:
    * Look for a section related to "Registry Authentication," "Push Secret," or "Image Pull/Push Credentials."
    * You should be able to select or specify the Kubernetes secret you created in Step 2
        (e.g., `quay-arewm-robot-creds`).

## Step 4a: Advanced Build Configuration for Multi-Platform, Dynamic Labeling, and Tagging

To achieve your specific requirements for multi-platform builds, dynamic labels, and custom tagging strategies, you'll likely need
to adjust parameters within the selected Konflux-CI pipeline or component settings. The exact method can vary based on
your Konflux-CI version and UI.

1.  **Multi-Platform Build Verification**:
    * The `docker-build-multi-platform-oci-ta` pipeline should inherently support building for multiple platforms (e.g.,
        `linux/amd64`, `linux/arm64`).
    * Check the pipeline parameters or component build settings for options to specify target platforms if they are not
        automatically detected or if you want to customize them. This might be a comma-separated list like
        `linux/amd64,linux/arm64`.

2.  **Dynamic Image Labels**:
    Konflux-CI allows for dynamic labels using Tekton's result substitution and predefined variables. Refer to the
    [Konflux-CI documentation on Dynamic Labels/Annotations](https://konflux-ci.dev/docs/building/labels-and-annotations/#generating-dynamic-labels-or-annotations).
    * **Version Label (from Branch Name)**:
        * You'll want to add a label like `org.opencontainers.image.version=$(params.git-branch)`.
        * This often involves editing the `PipelineRun` definition (if you manage it directly after initial generation) or
            finding a section in the Konflux-CI UI for "Build Parameters," "Pipeline Parameters," or "Image Labels" where
            you can inject parameters into the build process. The `docker-build-multi-platform-oci-ta` pipeline might
            have a parameter for extra labels.
        * The parameter `$(params.git-branch)` or a similar variable (e.g., `{{build.branch}}`, `{{git_branch_name}}`)
            should be available from the `git-clone` task or provided by Konflux-CI.
    * **Source Date Epoch Label**:
        * To add a label for `SOURCE_DATE_EPOCH`, you'd typically use a value provided by the build system or git metadata.
            Konflux-CI might expose this as a build parameter or it could be derived from `$(tasks.git-clone.results.commit-timestamp)`
            or similar, potentially requiring formatting.
        * The label would be `org.opencontainers.image.created=$(tasks.git-clone.results.commit-timestamp)` or
            `SOURCE_DATE_EPOCH={{source_date_epoch_variable}}`.
        * Look for pipeline parameters like `image-labels` or similar in the `docker-build-multi-platform-oci-ta` pipeline
            or component settings. You might pass it as:
            `image-labels='org.opencontainers.image.version=$(params.git-branch) org.opencontainers.image.created=$(tasks.git-clone.results.commit-timestamp)'`
            (The exact syntax for multiple labels depends on how the pipeline consumes this parameter).

3.  **Dynamic Image Tagging**:
    The `docker-build-multi-platform-oci-ta` pipeline typically includes a parameter for specifying additional tags.
    This parameter is often named `tags`, `additional-tags`, or similar.
    * **Tag with Branch Name**:
        * You will want to pass the branch name as a tag.
        * Example value for the `tags` parameter: `$(params.git-branch)`
    * **Tag with Branch Name and Epoch**:
        * This requires combining the branch name and an epoch timestamp. The epoch might come from a pipeline parameter
            like `$(params.source-date-epoch)` or derived from git commit timestamp.
        * You might need to use Tekton's string manipulation capabilities if the pipeline allows for complex parameter
            templating, or this might be a feature request/customization for the pipeline itself if not directly supported.
        * A simpler approach if direct epoch concatenation is hard: if Konflux-CI provides a unique build ID or a
            short commit SHA, you could use that: `$(params.git-branch)-$(tasks.git-clone.results.commit-short)`
        * If the pipeline accepts a comma-separated list for the `tags` parameter, you would provide:
            `tags='$(params.git-branch),$(params.git-branch)-{{epoch_or_build_id_variable}}'`
            (Again, `{{epoch_or_build_id_variable}}` needs to be a variable Konflux-CI makes available).

    **Modifying the PipelineRun or Component Configuration**:
    * **Directly in `.tekton/` files (Advanced)**: If Konflux-CI allows, you might directly edit the generated
        `PipelineRun` YAML in your `.tekton/` directory to adjust parameters passed to the `buildah` or `docker-build`
        Tekton task responsible for building and pushing. This gives you fine-grained control but requires understanding
        Tekton syntax. You would look for the task that performs the image build and push (often using `buildah`) and
        modify its `params` section for labels and tags.
    * **Konflux-CI UI**: The preferred method is usually to find these settings in the Konflux-CI UI under the
        "Component Settings," "Build Configuration," or "Pipeline Parameters." Look for fields related to "Image Labels,"
        "Additional Tags," or general "Build Parameters."

    **Example (Conceptual `PipelineRun` modification for labels and tags):**
    If you were to modify a Tekton Task definition or how parameters are passed to it, it might look something like this (this is illustrative, actual implementation depends on the specific Tekton Task):
    ```yaml
    # --- In a Tekton Task that uses buildah ---
    # params:
    #   - name: IMAGE_LABELS
    #     type: array
    #     description: Extra labels to apply to the image
    #   - name: ADDITIONAL_TAGS
    #     type: array
    #     description: Additional tags to push
    # steps:
    #   - name: build-and-push
    #     image: quay.io/buildah/stable
    #     script: |
    #       buildah --label "org.opencontainers.image.version=$(params.IMAGE_LABELS[0])" \
    #               --label "SOURCE_DATE_EPOCH=$(params.IMAGE_LABELS[1])" \
    #               --tag "$(params.IMAGE)" \
    #       for tag in $(params.ADDITIONAL_TAGS); do
    #         buildah tag "$(params.IMAGE)" "$tag"
    #       done
    #       buildah push --all "$(params.IMAGE)"
    ```
    You would then ensure your `PipelineRun` or Konflux-CI component settings correctly populate these `IMAGE_LABELS` and `ADDITIONAL_TAGS` parameters using available dynamic variables.

## Step 5: Trigger and Monitor the Build

1.  Save your build pipeline configuration.
2.  Trigger a new build. This might be done manually through the Konflux-CI UI, or it might automatically trigger upon
    a commit to the configured branch if a webhook is set up.
3.  Monitor the build progress in the Konflux-CI dashboard.
    * Examine the build logs for detailed output.
    * Key stages to watch for:
        * Cloning your Git repository.
        * Starting the container image build using your `Containerfile` for specified platforms.
        * Application of labels.
        * Successfully pushing the built image to `quay.io/arewm/your-image-name` with all specified tags.

## Step 6: Verify the Image in Quay.io

1.  Once the Konflux-CI build pipeline completes successfully, log in to your Quay.io account.
2.  Navigate to the repository you specified (e.g., `quay.io/arewm/my-fedora-devcontainer`).
3.  You should see the newly pushed image.
4.  **Verify Tags**: Check that all expected tags are present (e.g., `latest`, the branch name, branch name + epoch/commit).
5.  **Verify Labels**: Inspect the image configuration (Quay.io UI usually allows this) to ensure your dynamic labels
    (`org.opencontainers.image.version` and `SOURCE_DATE_EPOCH` or `org.opencontainers.image.created`) are correctly applied.
6.  **Verify Multi-Platform**: Quay.io should indicate if the image is a multi-architecture manifest list and show the
    available architectures.

## Troubleshooting Common Issues

* **Build Fails in Konflux-CI**:
    * Thoroughly examine the build logs in Konflux-CI. Errors are usually descriptive.
    * Common issues include errors in the `Containerfile`, missing build dependencies, or incorrect paths.
    * For multi-platform builds, ensure your `Containerfile` is compatible with all target architectures.
* **Authentication Failure to Quay.io**:
    * Verify that the robot account name and token used in the Kubernetes secret are correct.
    * Ensure the robot account has the necessary write permissions to the target repository on Quay.io.
    * Double-check that the Kubernetes secret (`quay-arewm-robot-creds`) was created in the correct namespace that
        Konflux-CI uses for builds.
    * Confirm that Konflux-CI is configured to use this secret for pushing to `quay.io`.
* **Image Not Found in Quay.io After Successful Build**:
    * Verify the image name and tag configured in Konflux-CI exactly match what you expect on Quay.io.
    * Check for any typos in `quay.io/arewm/your-image-name`.
* **Dynamic Variables Not Resolving**:
    * Consult the Konflux-CI documentation or the specific Tekton task documentation to confirm the correct syntax and
        availability of variables like `$(params.git-branch)`, `$(tasks.git-clone.results.commit-timestamp)`, etc.
    * Ensure the tasks that produce these results run before the tasks that consume them.
* **Incorrect Labels or Tags**:
    * Double-check the parameters passed to the build pipeline/task.
    * Review the build logs for how these parameters are interpreted and used by the build tools (`buildah`, `docker`).

For more specific troubleshooting, refer to your Konflux-CI instance's documentation or seek support from its
administrators.