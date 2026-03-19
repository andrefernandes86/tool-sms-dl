# 🐳 Docker Hub Setup Instructions

## 📋 **Required GitHub Secrets**

To enable automatic Docker image building and pushing, you need to add these secrets to your GitHub repository:

### **1. Go to Repository Settings**
1. Navigate to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

### **2. Add Docker Hub Credentials**

#### **DOCKERHUB_USERNAME**
- **Name:** `DOCKERHUB_USERNAME`
- **Value:** `andrefernandes86` (your Docker Hub username)

#### **DOCKERHUB_TOKEN**
- **Name:** `DOCKERHUB_TOKEN`
- **Value:** Your Docker Hub access token

## 🔑 **Creating Docker Hub Access Token**

1. Go to [Docker Hub](https://hub.docker.com/)
2. Sign in to your account
3. Click your profile → **Account Settings**
4. Go to **Security** → **Access Tokens**
5. Click **New Access Token**
6. Name: `GitHub Actions - Smish Detector`
7. Permissions: **Read, Write, Delete**
8. Click **Generate**
9. **Copy the token** (you won't see it again!)
10. Add it as `DOCKERHUB_TOKEN` secret in GitHub

## 🚀 **Workflow Triggers**

The GitHub Actions workflow will automatically run when:

- **Push to main branch** (with changes to `Smish Detector/` folder)
- **Pull request** to main branch
- **New release** is published
- **Manual trigger** via GitHub Actions tab

## 📦 **Docker Image Tags**

The workflow creates multiple tags:
- `latest` - Latest main branch build
- `main` - Main branch builds
- `v1.0.0` - Semantic version tags (if using releases)
- `main-abc1234` - Branch + commit SHA

## 🔍 **Monitoring Builds**

1. Go to **Actions** tab in your repository
2. Click on **Build and Push Docker Image** workflow
3. Monitor build progress and logs
4. Check [Docker Hub](https://hub.docker.com/r/andrefernandes86/smishdetector) for published images

## 🛠️ **Multi-Architecture Support**

The workflow builds for:
- `linux/amd64` (Intel/AMD x64)
- `linux/arm64` (Apple Silicon, ARM servers)

## ✅ **Verification**

After setup, test the workflow:
1. Make a small change to any file in `Smish Detector/`
2. Commit and push to main branch
3. Check Actions tab for build status
4. Verify new image appears on Docker Hub

## 🔧 **Troubleshooting**

### **Build Fails**
- Check GitHub Actions logs
- Verify Docker Hub credentials
- Ensure Dockerfile is valid

### **Push Fails**
- Verify DOCKERHUB_TOKEN has write permissions
- Check repository name matches exactly
- Ensure Docker Hub repository exists

### **Multi-arch Build Issues**
- May need to enable experimental features
- Check platform-specific dependencies

## 📋 **Docker Hub Repository Settings**

Make sure your Docker Hub repository:
1. **Name:** `andrefernandes86/smishdetector`
2. **Visibility:** Public (for easy access)
3. **Description:** Auto-updated from workflow
4. **README:** Auto-updated from DOCKER.md