# GitHub Actions Workflows Template

## Overview
This template provides GitHub Actions workflows following our CI/CD standards with NX monorepo support, security scanning, automated testing, and deployment to GitHub Container Registry.

## Main CI/CD Workflow

### 1. Continuous Integration and Deployment
```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  setup:
    runs-on: ubuntu-latest
    outputs:
      affected-apps: ${{ steps.affected.outputs.apps }}
      affected-libs: ${{ steps.affected.outputs.libs }}
      has-affected: ${{ steps.affected.outputs.has-affected }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Derive appropriate SHAs for base and head for `nx affected` commands
        uses: nrwl/nx-set-shas@v4

      - name: Get affected projects
        id: affected
        run: |
          AFFECTED_APPS=$(npx nx show projects --affected --type=app --json | jq -r 'join(",")')
          AFFECTED_LIBS=$(npx nx show projects --affected --type=lib --json | jq -r 'join(",")')
          HAS_AFFECTED=$([ -n "$AFFECTED_APPS" ] || [ -n "$AFFECTED_LIBS" ] && echo "true" || echo "false")
          
          echo "apps=$AFFECTED_APPS" >> $GITHUB_OUTPUT
          echo "libs=$AFFECTED_LIBS" >> $GITHUB_OUTPUT
          echo "has-affected=$HAS_AFFECTED" >> $GITHUB_OUTPUT
          
          echo "Affected apps: $AFFECTED_APPS"
          echo "Affected libs: $AFFECTED_LIBS"
          echo "Has affected: $HAS_AFFECTED"

  lint-and-test:
    runs-on: ubuntu-latest
    needs: setup
    if: needs.setup.outputs.has-affected == 'true'
    strategy:
      matrix:
        node-version: [18, 20]
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Derive appropriate SHAs for base and head for `nx affected` commands
        uses: nrwl/nx-set-shas@v4

      - name: Lint affected projects
        run: npx nx affected -t lint --parallel=3

      - name: Test affected projects
        run: npx nx affected -t test --parallel=3 --coverage

      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          directory: ./coverage
          flags: unittests
          name: codecov-umbrella
          fail_ci_if_error: true

  build:
    runs-on: ubuntu-latest
    needs: [setup, lint-and-test]
    if: needs.setup.outputs.has-affected == 'true'
    strategy:
      matrix:
        app: ${{ fromJson(format('[{0}]', needs.setup.outputs.affected-apps)) }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build application
        run: npx nx build ${{ matrix.app }} --prod

      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: build-${{ matrix.app }}
          path: dist/apps/${{ matrix.app }}
          retention-days: 7

  security-scan:
    runs-on: ubuntu-latest
    needs: setup
    if: needs.setup.outputs.has-affected == 'true'
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run security audit
        run: npm audit --audit-level=high

      - name: Run Snyk security scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

      - name: Run CodeQL Analysis
        uses: github/codeql-action/analyze@v3
        with:
          languages: javascript

      - name: Run GitLeaks secret scan
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }}

      - name: Run Checkov infrastructure scan
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          framework: terraform,kubernetes,dockerfile
          output_format: sarif
          output_file_path: checkov-results.sarif

      - name: Upload Checkov scan results
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: checkov-results.sarif

  e2e-tests:
    runs-on: ubuntu-latest
    needs: [setup, build]
    if: needs.setup.outputs.has-affected == 'true' && github.event_name == 'pull_request'
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 18
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright Browsers
        run: npx playwright install --with-deps

      - name: Download build artifacts
        uses: actions/download-artifact@v4
        with:
          pattern: build-*
          path: dist/apps/
          merge-multiple: true

      - name: Run E2E tests
        run: npx nx affected -t e2e --parallel=1
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          REDIS_URL: redis://localhost:6379
          BASE_URL: http://localhost:3000

      - name: Upload Playwright report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30

  build-and-push-images:
    runs-on: ubuntu-latest
    needs: [setup, lint-and-test, security-scan]
    if: needs.setup.outputs.has-affected == 'true' && github.ref == 'refs/heads/main'
    strategy:
      matrix:
        app: ${{ fromJson(format('[{0}]', needs.setup.outputs.affected-apps)) }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ github.repository }}/${{ matrix.app }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: apps/${{ matrix.app }}/Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64,linux/arm64

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: '${{ env.REGISTRY }}/${{ github.repository }}/${{ matrix.app }}:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy scan results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'

  deploy-test:
    runs-on: ubuntu-latest
    needs: [setup, build-and-push-images]
    if: needs.setup.outputs.has-affected == 'true' && github.ref == 'refs/heads/main'
    environment: test
    strategy:
      matrix:
        app: ${{ fromJson(format('[{0}]', needs.setup.outputs.affected-apps)) }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Google Cloud CLI
        uses: google-github-actions/setup-gcloud@v2
        with:
          service_account_key: ${{ secrets.GCP_SA_KEY }}
          project_id: ${{ secrets.GCP_PROJECT_ID }}

      - name: Configure kubectl
        run: |
          gcloud container clusters get-credentials horizon-test-gke --region us-central1

      - name: Deploy to test environment
        run: |
          # Update image tag in Kubernetes manifests
          sed -i "s|ghcr.io/${{ github.repository }}/${{ matrix.app }}:.*|ghcr.io/${{ github.repository }}/${{ matrix.app }}:${{ github.sha }}|g" k8s/apps/${{ matrix.app }}/deployment.yaml
          
          # Apply Kubernetes manifests
          kubectl apply -f k8s/apps/${{ matrix.app }}/
          
          # Wait for rollout to complete
          kubectl rollout status deployment/${{ matrix.app }} -n horizon --timeout=300s

      - name: Run smoke tests
        run: |
          # Wait for service to be ready
          kubectl wait --for=condition=ready pod -l app=${{ matrix.app }} -n horizon --timeout=300s
          
          # Run basic health checks
          kubectl exec -n horizon deployment/${{ matrix.app }} -- curl -f http://localhost:3000/health || \
          kubectl exec -n horizon deployment/${{ matrix.app }} -- curl -f http://localhost:3001/health

  deploy-production:
    runs-on: ubuntu-latest
    needs: [setup, deploy-test]
    if: needs.setup.outputs.has-affected == 'true' && github.ref == 'refs/heads/main'
    environment: production
    strategy:
      matrix:
        app: ${{ fromJson(format('[{0}]', needs.setup.outputs.affected-apps)) }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Google Cloud CLI
        uses: google-github-actions/setup-gcloud@v2
        with:
          service_account_key: ${{ secrets.GCP_PROD_SA_KEY }}
          project_id: ${{ secrets.GCP_PROD_PROJECT_ID }}

      - name: Configure kubectl
        run: |
          gcloud container clusters get-credentials horizon-prod-gke --region us-central1

      - name: Deploy to production environment
        run: |
          # Update image tag in Kubernetes manifests
          sed -i "s|ghcr.io/${{ github.repository }}/${{ matrix.app }}:.*|ghcr.io/${{ github.repository }}/${{ matrix.app }}:${{ github.sha }}|g" k8s/apps/${{ matrix.app }}/deployment.yaml
          
          # Apply Kubernetes manifests with rolling update
          kubectl apply -f k8s/apps/${{ matrix.app }}/
          
          # Wait for rollout to complete
          kubectl rollout status deployment/${{ matrix.app }} -n horizon --timeout=600s

      - name: Run production smoke tests
        run: |
          # Wait for service to be ready
          kubectl wait --for=condition=ready pod -l app=${{ matrix.app }} -n horizon --timeout=300s
          
          # Run comprehensive health checks
          kubectl exec -n horizon deployment/${{ matrix.app }} -- curl -f http://localhost:3000/health || \
          kubectl exec -n horizon deployment/${{ matrix.app }} -- curl -f http://localhost:3001/health
          
          # Check metrics endpoint
          kubectl exec -n horizon deployment/${{ matrix.app }} -- curl -f http://localhost:3000/metrics || \
          kubectl exec -n horizon deployment/${{ matrix.app }} -- curl -f http://localhost:3001/metrics

  notify:
    runs-on: ubuntu-latest
    needs: [deploy-production]
    if: always()
    steps:
      - name: Notify Slack on success
        if: needs.deploy-production.result == 'success'
        uses: 8398a7/action-slack@v3
        with:
          status: success
          channel: '#deployments'
          text: '✅ Production deployment successful for ${{ github.repository }}'
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}

      - name: Notify Slack on failure
        if: needs.deploy-production.result == 'failure'
        uses: 8398a7/action-slack@v3
        with:
          status: failure
          channel: '#deployments'
          text: '❌ Production deployment failed for ${{ github.repository }}'
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```



## Release Workflow

### 1. Automated Release Management
```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

env:
  REGISTRY: ghcr.io

jobs:
  create-release:
    runs-on: ubuntu-latest
    outputs:
      release-id: ${{ steps.create-release.outputs.id }}
      upload-url: ${{ steps.create-release.outputs.upload_url }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate changelog
        id: changelog
        run: |
          # Generate changelog from git commits
          CHANGELOG=$(git log --pretty=format:"- %s" $(git describe --tags --abbrev=0 HEAD^)..HEAD)
          echo "changelog<<EOF" >> $GITHUB_OUTPUT
          echo "$CHANGELOG" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT

      - name: Create Release
        id: create-release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          body: |
            ## Changes in this Release
            ${{ steps.changelog.outputs.changelog }}
            
            ## Docker Images
            - `ghcr.io/${{ github.repository }}/web-dashboard:${{ github.ref_name }}`
            - `ghcr.io/${{ github.repository }}/api-core:${{ github.ref_name }}`
            - `ghcr.io/${{ github.repository }}/blockchain-deployer:${{ github.ref_name }}`
          draft: false
          prerelease: false

  build-release-images:
    runs-on: ubuntu-latest
    needs: create-release
    strategy:
      matrix:
        app: [web-dashboard, api-core, blockchain-deployer]
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ github.repository }}/${{ matrix.app }}
          tags: |
            type=ref,event=tag
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: apps/${{ matrix.app }}/Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64,linux/arm64

  deploy-release:
    runs-on: ubuntu-latest
    needs: [create-release, build-release-images]
    environment: production
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Google Cloud CLI
        uses: google-github-actions/setup-gcloud@v2
        with:
          service_account_key: ${{ secrets.GCP_PROD_SA_KEY }}
          project_id: ${{ secrets.GCP_PROD_PROJECT_ID }}

      - name: Configure kubectl
        run: |
          gcloud container clusters get-credentials horizon-prod-gke --region us-central1

      - name: Deploy release to production
        run: |
          # Update all application images to release tag
          for app in web-dashboard api-core blockchain-deployer; do
            if [ -f "k8s/apps/$app/deployment.yaml" ]; then
              sed -i "s|ghcr.io/${{ github.repository }}/$app:.*|ghcr.io/${{ github.repository }}/$app:${{ github.ref_name }}|g" k8s/apps/$app/deployment.yaml
              kubectl apply -f k8s/apps/$app/
              kubectl rollout status deployment/$app -n horizon --timeout=600s
            fi
          done

      - name: Verify deployment
        run: |
          # Verify all services are healthy
          for app in web-dashboard api-core blockchain-deployer; do
            if kubectl get deployment $app -n horizon >/dev/null 2>&1; then
              kubectl wait --for=condition=ready pod -l app=$app -n horizon --timeout=300s
              echo "✅ $app deployment verified"
            fi
          done

      - name: Update release with deployment info
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.repos.updateRelease({
              owner: context.repo.owner,
              repo: context.repo.repo,
              release_id: ${{ needs.create-release.outputs.release-id }},
              body: `## Changes in this Release
            ${{ steps.changelog.outputs.changelog }}
            
            ## Docker Images
            - \`ghcr.io/${{ github.repository }}/web-dashboard:${{ github.ref_name }}\`
            - \`ghcr.io/${{ github.repository }}/api-core:${{ github.ref_name }}\`
            - \`ghcr.io/${{ github.repository }}/blockchain-deployer:${{ github.ref_name }}\`
            
            ## Deployment Status
            ✅ Successfully deployed to production at ${new Date().toISOString()}`
            });
```

## Reusable Workflows

### 1. Reusable Build Workflow
```yaml
# .github/workflows/reusable-build.yml
name: Reusable Build

on:
  workflow_call:
    inputs:
      app-name:
        required: true
        type: string
      node-version:
        required: false
        type: string
        default: '18'
      build-command:
        required: false
        type: string
        default: 'build'
    outputs:
      image-tag:
        description: "Built image tag"
        value: ${{ jobs.build.outputs.image-tag }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build application
        run: npx nx ${{ inputs.build-command }} ${{ inputs.app-name }} --prod

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}/${{ inputs.app-name }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=sha,prefix={{branch}}-

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: apps/${{ inputs.app-name }}/Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

This template provides comprehensive GitHub Actions workflows following our CI/CD standards with NX monorepo support, security scanning, automated testing, and deployment automation.
