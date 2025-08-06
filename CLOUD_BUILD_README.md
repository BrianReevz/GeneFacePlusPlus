# GeneFace++ Cloud Build Configuration

This directory contains Google Cloud Build configurations for building the GeneFace++ Docker images.

## Files

- `cloudbuild.yaml` - Basic cloud build configuration
- `cloudbuild-advanced.yaml` - Advanced configuration with caching and optimizations

## Prerequisites

1. **Google Cloud Project**: You need a Google Cloud project with Cloud Build API enabled
2. **Artifact Registry**: Enable Artifact Registry API
3. **Permissions**: Ensure your account has the necessary permissions to create Cloud Build triggers

## Setup Instructions

### 1. Enable Required APIs and Set Up Artifact Registry

```bash
# Check your gcloud version first
gcloud version

# Update gcloud if needed
gcloud components update

# Enable required APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com

# Create an Artifact Registry repository (replace REGION with your preferred region)
gcloud artifacts repositories create geneface-repo \
  --repository-format=docker \
  --location=REGION \
  --description="GeneFace++ Docker images"

# Configure Docker to authenticate to Artifact Registry
gcloud auth configure-docker REGION-docker.pkg.dev
```

### 2. Set Up Cloud Build Trigger

#### Option A: Using gcloud CLI

```bash
# First, connect your GitHub repository (if not already done)
gcloud builds triggers create github \
  --repo-name=GeneFacePlusPlus \
  --repo-owner=YOUR_GITHUB_USERNAME \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml \
  --name=geneface-basic-build

# Create a trigger for the advanced configuration
gcloud builds triggers create github \
  --repo-name=GeneFacePlusPlus \
  --repo-owner=YOUR_GITHUB_USERNAME \
  --branch-pattern="^main$" \
  --build-config=cloudbuild-advanced.yaml \
  --name=geneface-advanced-build
```

**Alternative syntax (if the above doesn't work):**

```bash
# Create triggers using the newer syntax
gcloud builds triggers create github \
  --name=geneface-basic-build \
  --repo-owner=YOUR_GITHUB_USERNAME \
  --repo-name=GeneFacePlusPlus \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml

gcloud builds triggers create github \
  --name=geneface-advanced-build \
  --repo-owner=YOUR_GITHUB_USERNAME \
  --repo-name=GeneFacePlusPlus \
  --branch-pattern="^main$" \
  --build-config=cloudbuild-advanced.yaml
```

#### Option B: Using Google Cloud Console

1. Go to Cloud Build > Triggers
2. Click "Create Trigger"
3. Connect your GitHub repository
4. Select the branch (e.g., `main`)
5. Choose "Cloud Build configuration file (yaml or json)"
6. Specify the path to `cloudbuild.yaml` or `cloudbuild-advanced.yaml`

### 3. Manual Build (Alternative)

You can also trigger builds manually:

```bash
# Basic build
gcloud builds submit --config=cloudbuild.yaml .

# Advanced build with custom tag and region
gcloud builds submit --config=cloudbuild-advanced.yaml . \
  --substitutions=_TAG_NAME=v1.0.0,_REGION=us-central1

# Or run with default tag (latest) and custom region
gcloud builds submit --config=cloudbuild-advanced.yaml . \
  --substitutions=_REGION=us-central1

# Or run with default values
gcloud builds submit --config=cloudbuild-advanced.yaml .
```

## Configuration Details

### Basic Configuration (`cloudbuild.yaml`)

- Builds both Dockerfiles in sequence
- Simple push to Container Registry
- 30-minute timeout
- Uses E2_HIGHCPU_8 machine type

### Advanced Configuration (`cloudbuild-advanced.yaml`)

- Includes Docker layer caching for faster rebuilds
- Multi-platform support (linux/amd64)
- Version tagging support
- 60-minute timeout
- Larger disk size (100GB)
- Streaming logs enabled

## Build Process

The build process follows the same steps as the local Docker installation:

1. **Base Image**: Builds `ubuntu22.04-cu118-conda:torch2.0.1-py39` from `Dockerfile.cu118.torch2.0.1.py39`
2. **Application Image**: Builds `genfaceplus:latest` from `Dockerfile.genface`

## Using the Built Images

After a successful build, you can pull and run the images:

```bash
# Pull the image
docker pull REGION-docker.pkg.dev/YOUR_PROJECT_ID/geneface-repo/genfaceplus:latest

# Run the container (as per the installation notes)
docker run -it --name geneface -p 7869:7860 --gpus all \
  -v ~/.cache:/root/.cache \
  -v ~/workspace/GeneFacePlusPlus:/data/geneface/ \
  REGION-docker.pkg.dev/YOUR_PROJECT_ID/geneface-repo/genfaceplus:latest /bin/bash
```

## Troubleshooting

### Common Issues

1. **Build Timeout**: The builds can take 30-60 minutes. If they timeout, increase the timeout value in the configuration.

2. **Memory Issues**: The advanced configuration uses E2_HIGHCPU_8 for better performance. If you encounter memory issues, consider using a different machine type.

3. **Cache Issues**: If the build cache becomes corrupted, you can disable caching by removing the `--cache-from` and `--cache-to` flags.

4. **Trigger Creation Issues**: If you get "invalid arguments" errors when creating triggers:
   - Ensure you're using the latest version of gcloud: `gcloud components update`
   - Try the alternative syntax provided above
   - Use the Google Cloud Console method instead
   - Check that your GitHub repository is properly connected to Cloud Build

### Monitoring Builds

```bash
# List recent builds
gcloud builds list

# Get detailed logs for a specific build
gcloud builds log BUILD_ID
```

## Cost Optimization

- Use the basic configuration for development/testing
- Use the advanced configuration with caching for production builds
- Consider setting up build schedules to avoid unnecessary builds
- Monitor build costs in the Google Cloud Console

## Security Notes

- The built images are stored in Google Artifact Registry
- Ensure your project has appropriate IAM permissions
- Review the Dockerfiles for any security concerns before building

## Next Steps

After building the images, follow the [Docker installation notes](Docker.installation.md) for:
1. Preparing model checkpoints
2. Running the inference
3. Starting the Gradio demo app 