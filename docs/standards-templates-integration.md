# Standards and Templates Integration Planning
## Horizon SDLC

### 1. Overview

This document defines **simple file processing patterns and basic validation frameworks** for implementing the standards from requirements.md. It complements [requirements.md](./requirements.md) by focusing on the simplified technical implementation of standards integration.

**Reference**: See [requirements.md Section 3](./requirements.md#3-architectural-standards-applied-to-all-languages) for architectural standards and [Section 4](./requirements.md#4-opencode-ai-agent-modes) for agent mode definitions.

**Focus Areas**:
- Simple file processing with static file copying
- Basic string replacement patterns for project customization
- Lightweight validation for file syntax and structure
- Integration patterns for OpenCode agent consumption

### 2. JSON Schema Framework for Standards

**Reference**: See [requirements.md Section 3](./requirements.md#3-architectural-standards-applied-to-all-languages) for complete architectural standards.

#### 2.1 Standards Schema Definition

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Coding Standard Schema",
  "type": "object",
  "properties": {
    "standard": {
      "type": "string",
      "description": "Unique identifier for the standard"
    },
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$",
      "description": "Semantic version of the standard"
    },
    "description": {
      "type": "string",
      "description": "Human-readable description of the standard"
    },
    "languages": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["typescript", "go", "python", "java"]
      },
      "description": "Languages this standard applies to"
    },
    "category": {
      "type": "string",
      "enum": ["architectural", "coding", "testing", "documentation"],
      "description": "Category of the standard"
    },
    "implementation": {
      "type": "object",
      "description": "Implementation-specific details"
    },
    "validation": {
      "type": "object",
      "properties": {
        "rules": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Validation rules for compliance checking"
        },
        "automated": {
          "type": "boolean",
          "description": "Whether validation can be automated"
        },
        "tools": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Tools that can validate this standard"
        }
      }
    },
    "examples": {
      "type": "object",
      "description": "Language-specific examples"
    },
    "references": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "title": {"type": "string"},
          "url": {"type": "string", "format": "uri"}
        }
      },
      "description": "External references and documentation"
    }
  },
  "required": ["standard", "version", "description", "languages", "category"],
  "additionalProperties": false
}
```

#### 2.2 Project Configuration Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Project Configuration Schema",
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "description": "Project name",
      "pattern": "^[a-z0-9-]+$"
    },
    "description": {
      "type": "string",
      "description": "Project description"
    },
    "languages": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["typescript", "go", "python", "java"]
      },
      "minItems": 1
    },
    "features": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["testing", "linting", "ci-cd", "docker", "documentation"]
      }
    },
    "metadata": {
      "type": "object",
      "properties": {
        "version": {"type": "string", "pattern": "^\\d+\\.\\d+\\.\\d+$"},
        "author": {"type": "string"},
        "license": {"type": "string"},
        "repository": {"type": "string"}
      }
    }
  },
  "required": ["name", "languages"],
  "additionalProperties": false
}
```

### 3. Static File Processing Implementation Patterns

#### 3.1 Simple File Processing and String Replacement

```typescript
interface FileProcessingContext {
  project: ProjectConfig;
  language: SupportedLanguage;
  features: ProjectFeature[];
  timestamp: Date;
  user: UserContext;
}

interface StringReplacementPattern {
  placeholder: string;
  value: string;
  description: string;
}

interface FileProcessingResult {
  sourceFile: string;
  targetFile: string;
  processed: boolean;
  replacements: number;
  errors: string[];
}

class SimpleStringReplacer {
  private patterns: Map<string, string> = new Map();

  constructor(context: FileProcessingContext) {
    this.buildReplacementPatterns(context);
  }

  private buildReplacementPatterns(context: FileProcessingContext): void {
    // Basic project information
    this.patterns.set('{{PROJECT_NAME}}', context.project.name);
    this.patterns.set('{{PROJECT_DESCRIPTION}}', context.project.description || '');
    this.patterns.set('{{PRIMARY_LANGUAGE}}', context.language);

    // User information
    this.patterns.set('{{AUTHOR_NAME}}', context.user.name || '');
    this.patterns.set('{{AUTHOR_EMAIL}}', context.user.email || '');
    this.patterns.set('{{GITHUB_USERNAME}}', context.user.githubUsername || '');

    // Date and version information
    this.patterns.set('{{CURRENT_YEAR}}', new Date().getFullYear().toString());
    this.patterns.set('{{CURRENT_DATE}}', new Date().toISOString().split('T')[0]);
    this.patterns.set('{{TIMESTAMP}}', context.timestamp.toISOString());
    this.patterns.set('{{VERSION}}', context.project.metadata.version);

    // Feature flags (simple boolean replacements)
    this.patterns.set('{{HAS_TESTING}}', context.features.includes('testing').toString());
    this.patterns.set('{{HAS_LINTING}}', context.features.includes('linting').toString());
    this.patterns.set('{{HAS_CI_CD}}', context.features.includes('ci-cd').toString());
    this.patterns.set('{{HAS_DOCKER}}', context.features.includes('docker').toString());
  }

  processContent(content: string): { content: string; replacements: number } {
    let processedContent = content;
    let replacementCount = 0;

    for (const [placeholder, value] of this.patterns) {
      const regex = new RegExp(placeholder.replace(/[{}]/g, '\\$&'), 'g');
      const matches = processedContent.match(regex);
      if (matches) {
        processedContent = processedContent.replace(regex, value);
        replacementCount += matches.length;
      }
    }

    return { content: processedContent, replacements: replacementCount };
  }

  getAvailablePatterns(): StringReplacementPattern[] {
    return Array.from(this.patterns.entries()).map(([placeholder, value]) => ({
      placeholder,
      value,
      description: this.getPatternDescription(placeholder)
    }));
  }

  private getPatternDescription(placeholder: string): string {
    const descriptions: Record<string, string> = {
      '{{PROJECT_NAME}}': 'Project name from configuration',
      '{{PROJECT_DESCRIPTION}}': 'Project description from configuration',
      '{{PRIMARY_LANGUAGE}}': 'Primary programming language',
      '{{AUTHOR_NAME}}': 'Author name from user context',
      '{{AUTHOR_EMAIL}}': 'Author email from user context',
      '{{GITHUB_USERNAME}}': 'GitHub username from user context',
      '{{CURRENT_YEAR}}': 'Current year (YYYY)',
      '{{CURRENT_DATE}}': 'Current date (YYYY-MM-DD)',
      '{{TIMESTAMP}}': 'ISO timestamp of generation',
      '{{VERSION}}': 'Project version from metadata',
      '{{HAS_TESTING}}': 'Boolean flag for testing feature',
      '{{HAS_LINTING}}': 'Boolean flag for linting feature',
      '{{HAS_CI_CD}}': 'Boolean flag for CI/CD feature',
      '{{HAS_DOCKER}}': 'Boolean flag for Docker feature'
    };
    return descriptions[placeholder] || 'Unknown placeholder';
  }
}
```

#### 3.2 Static File Processing Pipeline

```typescript
class StaticFileProcessor {
  private replacer: SimpleStringReplacer;
  private validator: FileValidator;

  constructor(context: FileProcessingContext) {
    this.replacer = new SimpleStringReplacer(context);
    this.validator = new FileValidator();
  }

  async processFile(
    sourceFile: string,
    targetFile: string,
    options: FileProcessingOptions = {}
  ): Promise<FileProcessingResult> {

    try {
      // 1. Read source file
      const sourceContent = await fs.readFile(sourceFile, 'utf-8');

      // 2. Apply string replacements
      const { content: processedContent, replacements } = this.replacer.processContent(sourceContent);

      // 3. Validate processed content
      const validation = await this.validator.validateContent(processedContent, sourceFile);

      if (!validation.isValid && options.strictValidation) {
        throw new Error(`Validation failed: ${validation.errors.map(e => e.message).join(', ')}`);
      }

      // 4. Ensure target directory exists
      await fs.ensureDir(path.dirname(targetFile));

      // 5. Write processed content
      await fs.writeFile(targetFile, processedContent, 'utf-8');

      // 6. Preserve file permissions if requested
      if (options.preservePermissions) {
        const stats = await fs.stat(sourceFile);
        await fs.chmod(targetFile, stats.mode);
      }

      return {
        sourceFile,
        targetFile,
        processed: true,
        replacements,
        errors: validation.errors.map(e => e.message)
      };

    } catch (error) {
      return {
        sourceFile,
        targetFile,
        processed: false,
        replacements: 0,
        errors: [error.message]
      };
    }
  }

  async processDirectory(
    sourceDir: string,
    targetDir: string,
    options: FileProcessingOptions = {}
  ): Promise<FileProcessingResult[]> {

    const results: FileProcessingResult[] = [];
    const files = await this.getFilesToProcess(sourceDir, options.filePattern);

    // Process files in parallel for better performance
    const processingPromises = files.map(async (sourceFile) => {
      const relativePath = path.relative(sourceDir, sourceFile);
      const targetFile = path.join(targetDir, relativePath);

      return this.processFile(sourceFile, targetFile, options);
    });

    const processedResults = await Promise.all(processingPromises);
    results.push(...processedResults);

    return results;
  }

  private async getFilesToProcess(sourceDir: string, pattern?: string): Promise<string[]> {
    const globPattern = pattern || '**/*';
    const files = await glob(globPattern, {
      cwd: sourceDir,
      absolute: true,
      nodir: true,
      dot: true
    });

    return files;
  }
}
```

#### 3.3 Static Configuration File Patterns

**Reference**: See [requirements.md Section 7.1](./requirements.md#71-opencode-configuration-specifications) for complete OpenCode configuration requirements.

```json
// Static OpenCode Configuration Template (opencode.json)
{
  "provider": "openrouter",
  "model": "anthropic/claude-sonnet-4-20250514",
  "apiKey": "{env:OPENROUTER_API_KEY}",
  "dataDirectory": ".opencode",
  "mcpServers": {
    "context7": {
      "type": "local",
      "command": ["context7-mcp-server"],
      "enabled": true
    },
    "github": {
      "type": "local",
      "command": ["github-mcp-server"],
      "enabled": true,
      "env": {
        "GITHUB_TOKEN": "{env:GITHUB_TOKEN}"
      }
    },
    "playwright": {
      "type": "local",
      "command": ["playwright-mcp-server"],
      "enabled": true
    },
    "shadcn-ui": {
      "type": "local",
      "command": ["shadcn-ui-mcp-server"],
      "enabled": true
    },
    "sequential-thinking": {
      "type": "local",
      "command": ["sequential-thinking-mcp-server"],
      "enabled": true
    }
  },
  "workspace": {
    "mountPoints": [
      {
        "hostPath": "{{PROJECT_NAME}}",
        "containerPath": "/workspace",
        "readOnly": false
      },
      {
        "hostPath": "{{PROJECT_NAME}}/.ai",
        "containerPath": "/.ai",
        "readOnly": false
      },
      {
        "hostPath": "{{PROJECT_NAME}}/.opencode",
        "containerPath": "/.opencode",
        "readOnly": false
      }
    ],
    "environmentVariables": {
      "PROJECT_NAME": "{{PROJECT_NAME}}",
      "PRIMARY_LANGUAGE": "{{PRIMARY_LANGUAGE}}"
    }
  }
}
```

**Static Package.json Template Example:**
```json
{
  "name": "{{PROJECT_NAME}}",
  "version": "{{VERSION}}",
  "description": "{{PROJECT_DESCRIPTION}}",
  "author": "{{AUTHOR_NAME}} <{{AUTHOR_EMAIL}}>",
  "license": "MIT",
  "scripts": {
    "build": "tsc",
    "test": "jest",
    "lint": "eslint src/**/*.ts",
    "start": "node dist/index.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0",
    "jest": "^29.0.0",
    "eslint": "^8.0.0"
  }
}
```

### 4. Validation Framework Implementation

**Reference**: See [requirements.md Section 4](./requirements.md#4-opencode-ai-agent-modes) for agent mode definitions and [Section 6](./requirements.md#6-workflow-template-installation) for workflow templates.

#### 4.1 Standards Compliance Validation

```typescript
interface SimpleValidationResult {
  passed: boolean;
  errors: string[];
  warnings: string[];
  filesChecked: number;
}

interface FileValidationRule {
  name: string;
  description: string;
  filePattern: string;
  validator: (content: string, filePath: string) => string[];
}

class SimpleProjectValidator {
  private fileRules: FileValidationRule[] = [
    {
      name: 'JSON Syntax',
      description: 'Validates JSON files have correct syntax',
      filePattern: '**/*.json',
      validator: this.validateJsonSyntax.bind(this)
    },
    {
      name: 'Package.json Structure',
      description: 'Validates package.json has required fields',
      filePattern: '**/package.json',
      validator: this.validatePackageJson.bind(this)
    },
    {
      name: 'TypeScript Config',
      description: 'Validates tsconfig.json structure',
      filePattern: '**/tsconfig.json',
      validator: this.validateTsConfig.bind(this)
    },
    {
      name: 'Placeholder Resolution',
      description: 'Checks for unresolved placeholders',
      filePattern: '**/*',
      validator: this.validatePlaceholders.bind(this)
    }
  ];

  async validateProject(projectPath: string): Promise<SimpleValidationResult> {
    const errors: string[] = [];
    const warnings: string[] = [];
    let filesChecked = 0;

    for (const rule of this.fileRules) {
      const files = await glob(rule.filePattern, {
        cwd: projectPath,
        absolute: true,
        ignore: ['**/node_modules/**', '**/dist/**', '**/.git/**']
      });

      for (const filePath of files) {
        try {
          const content = await fs.readFile(filePath, 'utf-8');
          const ruleErrors = rule.validator(content, filePath);

          if (ruleErrors.length > 0) {
            const relativePath = path.relative(projectPath, filePath);
            errors.push(`${rule.name} - ${relativePath}: ${ruleErrors.join(', ')}`);
          }

          filesChecked++;
        } catch (error) {
          warnings.push(`Could not read file ${filePath}: ${error.message}`);
        }
      }
    }

    return {
      passed: errors.length === 0,
      errors,
      warnings,
      filesChecked
    };
  }

  private validateJsonSyntax(content: string, filePath: string): string[] {
    try {
      JSON.parse(content);
      return [];
    } catch (error) {
      return [`Invalid JSON syntax: ${error.message}`];
    }
  }

  private validatePackageJson(content: string, filePath: string): string[] {
    const errors: string[] = [];

    try {
      const pkg = JSON.parse(content);

      if (!pkg.name) errors.push('Missing required field: name');
      if (!pkg.version) errors.push('Missing required field: version');
      if (!pkg.scripts) errors.push('Missing scripts section');

    } catch (error) {
      errors.push(`Invalid JSON: ${error.message}`);
    }

    return errors;
  }

  private validateTsConfig(content: string, filePath: string): string[] {
    const errors: string[] = [];

    try {
      const config = JSON.parse(content);

      if (!config.compilerOptions) {
        errors.push('Missing compilerOptions');
      } else {
        if (!config.compilerOptions.target) {
          errors.push('Missing compilerOptions.target');
        }
        if (!config.compilerOptions.module) {
          errors.push('Missing compilerOptions.module');
        }
      }

    } catch (error) {
      errors.push(`Invalid JSON: ${error.message}`);
    }

    return errors;
  }

  private validatePlaceholders(content: string, filePath: string): string[] {
    const errors: string[] = [];
    const placeholderPattern = /\{\{[A-Z_]+\}\}/g;
    const matches = content.match(placeholderPattern);

    if (matches && matches.length > 0) {
      const uniquePlaceholders = [...new Set(matches)];
      errors.push(`Unresolved placeholders: ${uniquePlaceholders.join(', ')}`);
    }

    return errors;
  }


}
```

#### 4.2 File Validation Framework

```typescript
class FileValidator {
  constructor() {
    // Simple file validator - no complex schema validation needed
  }

  async validateContent(content: string, filePath: string): Promise<ValidationResult> {
    const violations: Violation[] = [];
    const warnings: ValidationWarning[] = [];

    // 1. Basic content validation
    if (!content.trim()) {
      warnings.push({
        field: 'content',
        message: 'File content is empty',
        suggestion: 'Verify this is intentional'
      });
    }

    // 2. Check for unresolved placeholders
    const unresolvedPlaceholders = this.findUnresolvedPlaceholders(content);
    if (unresolvedPlaceholders.length > 0) {
      violations.push({
        ruleId: 'unresolved-placeholders',
        severity: 'warning',
        message: `Unresolved placeholders found: ${unresolvedPlaceholders.join(', ')}`,
        suggestion: 'Ensure all placeholders have corresponding replacement values'
      });
    }

    // 3. File-type specific validation
    const fileExtension = path.extname(filePath);
    switch (fileExtension) {
      case '.json':
        await this.validateJsonSyntax(content, violations);
        break;
      case '.yaml':
      case '.yml':
        await this.validateYamlSyntax(content, violations);
        break;
      case '.ts':
      case '.js':
        await this.validateJavaScriptSyntax(content, violations);
        break;
    }

    return {
      passed: violations.filter(v => v.severity === 'error').length === 0,
      violations,
      warnings,
      metrics: {
        contentLength: content.length,
        placeholdersResolved: this.countResolvedPlaceholders(content)
      }
    };
  }

  private findUnresolvedPlaceholders(content: string): string[] {
    const placeholderRegex = /\{\{[A-Z_]+\}\}/g;
    const matches = content.match(placeholderRegex);
    return matches ? [...new Set(matches)] : [];
  }

  private countResolvedPlaceholders(content: string): number {
    // Count how many placeholders were likely resolved (heuristic)
    const commonPatterns = [
      /\{\{PROJECT_NAME\}\}/g,
      /\{\{AUTHOR_NAME\}\}/g,
      /\{\{CURRENT_YEAR\}\}/g
    ];

    let resolvedCount = 0;
    for (const pattern of commonPatterns) {
      const originalMatches = content.match(pattern);
      if (!originalMatches) {
        resolvedCount++; // Likely was resolved
      }
    }

    return resolvedCount;
  }

  private async validateJsonSyntax(content: string, violations: Violation[]): Promise<void> {
    try {
      JSON.parse(content);
    } catch (error) {
      violations.push({
        ruleId: 'json-syntax',
        severity: 'error',
        message: `Invalid JSON syntax: ${error.message}`,
        suggestion: 'Fix JSON syntax errors'
      });
    }
  }

  private async validateYamlSyntax(content: string, violations: Violation[]): Promise<void> {
    try {
      // Basic YAML validation - check for common issues
      if (content.includes('\t')) {
        violations.push({
          ruleId: 'yaml-tabs',
          severity: 'warning',
          message: 'YAML files should use spaces, not tabs',
          suggestion: 'Replace tabs with spaces'
        });
      }
    } catch (error) {
      violations.push({
        ruleId: 'yaml-syntax',
        severity: 'error',
        message: `YAML syntax error: ${error.message}`,
        suggestion: 'Fix YAML syntax errors'
      });
    }
  }

  private async validateJavaScriptSyntax(content: string, violations: Violation[]): Promise<void> {
    // Basic JavaScript/TypeScript validation
    const commonIssues = [
      { pattern: /console\.log\(/g, message: 'Consider removing console.log statements', severity: 'info' as const },
      { pattern: /debugger;/g, message: 'Remove debugger statements', severity: 'warning' as const }
    ];

    for (const issue of commonIssues) {
      const matches = content.match(issue.pattern);
      if (matches) {
        violations.push({
          ruleId: 'js-best-practices',
          severity: issue.severity,
          message: issue.message,
          suggestion: 'Review and clean up development code'
        });
      }
    }
  }
}
```

### 5. Integration Patterns for OpenCode Agent Consumption

**Reference**: See [requirements.md Section 4](./requirements.md#4-opencode-ai-agent-modes) for complete agent mode definitions and [Section 6](./requirements.md#6-workflow-template-installation) for workflow templates.

#### 5.1 Simple Standards Loading Strategy

```typescript
class SimpleStandardsLoader {
  private cache = new Map<string, any>();
  private validator = new FileValidator();

  async loadStandard(category: string, name: string): Promise<any> {
    const cacheKey = `${category}:${name}`;

    if (this.cache.has(cacheKey)) {
      return this.cache.get(cacheKey);
    }

    const standardPath = path.join('.ai/standards', category, `${name}.json`);
    const standard = await this.loadAndValidateStandard(standardPath);

    this.cache.set(cacheKey, standard);

    return standard;
  }

  private async loadAndValidateStandard(standardPath: string): Promise<any> {
    try {
      const content = await fs.readFile(standardPath, 'utf-8');

      // Validate JSON syntax
      const validation = await this.validator.validateContent(content, standardPath);
      if (!validation.passed) {
        throw new Error(`Invalid standard at ${standardPath}: ${validation.violations.map(v => v.message).join(', ')}`);
      }

      const standard = JSON.parse(content);

      // Basic structure validation
      if (!standard.standard || !standard.version || !standard.description) {
        throw new Error(`Standard at ${standardPath} missing required fields: standard, version, description`);
      }

      return standard;
    } catch (error) {
      console.error(`Failed to load standard from ${standardPath}:`, error.message);
      throw error;
    }
  }

  async loadAllStandards(standardsDir: string): Promise<Record<string, any>> {
    const standards: Record<string, any> = {};

    try {
      const categories = await fs.readdir(standardsDir);

      for (const category of categories) {
        const categoryPath = path.join(standardsDir, category);
        const stat = await fs.stat(categoryPath);

        if (stat.isDirectory()) {
          standards[category] = {};
          const files = await fs.readdir(categoryPath);

          for (const file of files) {
            if (file.endsWith('.json')) {
              const name = path.basename(file, '.json');
              try {
                standards[category][name] = await this.loadStandard(category, name);
              } catch (error) {
                console.warn(`Failed to load standard ${category}/${name}:`, error.message);
              }
            }
          }
        }
      }
    } catch (error) {
      console.error(`Failed to load standards from ${standardsDir}:`, error.message);
    }

    return standards;
  }

  clearCache(): void {
    this.cache.clear();
  }
}
```

#### 5.2 Simple Agent Context Integration

```typescript
interface SimpleAgentContext {
  mode: AgentMode;
  project: ProjectConfig;
  standards: Record<string, any>;
  workspace: WorkspaceContext;
}

class SimpleAgentContextBuilder {
  constructor(private standardsLoader: SimpleStandardsLoader) {}

  async buildContext(mode: AgentMode, project: ProjectConfig): Promise<SimpleAgentContext> {
    // Load all available standards
    const standards = await this.loadProjectStandards(project);

    // Build workspace context
    const workspace = await this.buildWorkspaceContext(project);

    return {
      mode,
      project,
      standards,
      workspace
    };
  }

  private async loadProjectStandards(project: ProjectConfig): Promise<Record<string, any>> {
    const standardsDir = path.join(project.name, '.ai/standards');

    try {
      // Check if standards directory exists
      await fs.access(standardsDir);

      // Load all standards from the project's .ai directory
      return await this.standardsLoader.loadAllStandards(standardsDir);
    } catch (error) {
      console.warn(`Standards directory not found at ${standardsDir}, using empty standards`);
      return {};
    }
  }

  private async buildWorkspaceContext(project: ProjectConfig): Promise<WorkspaceContext> {
    return {
      projectPath: project.name,
      aiDirectory: path.join(project.name, '.ai'),
      opencodeDirectory: path.join(project.name, '.opencode'),
      languages: project.languages,
      features: project.features
    };
  }

  async refreshStandards(context: SimpleAgentContext): Promise<SimpleAgentContext> {
    // Clear cache and reload standards
    this.standardsLoader.clearCache();
    const updatedStandards = await this.loadProjectStandards(context.project);

    return {
      ...context,
      standards: updatedStandards
    };
  }
}

interface WorkspaceContext {
  projectPath: string;
  aiDirectory: string;
  opencodeDirectory: string;
  languages: SupportedLanguage[];
  features: ProjectFeature[];
}
```

#### 5.3 Simple File Validation Integration

```typescript
class SimpleFileValidator {
  private fileValidator: FileValidator;
  private standardsValidator: StandardsValidator;

  constructor() {
    this.fileValidator = new FileValidator();
    this.standardsValidator = new StandardsValidator();
  }

  async validateFile(filePath: string, context: SimpleAgentContext): Promise<ValidationResult> {
    try {
      const content = await fs.readFile(filePath, 'utf-8');

      // Basic file validation
      const fileValidation = await this.fileValidator.validateContent(content, filePath);

      // Standards validation if applicable
      const standardsValidation = await this.validateAgainstStandards(filePath, content, context);

      // Combine results
      return this.combineValidationResults([fileValidation, standardsValidation]);
    } catch (error) {
      return {
        passed: false,
        violations: [{
          ruleId: 'file-access',
          severity: 'error',
          message: `Cannot validate file: ${error.message}`
        }],
        warnings: [],
        metrics: {}
      };
    }
  }

  async validateProject(context: SimpleAgentContext): Promise<ValidationResult> {
    const results: ValidationResult[] = [];

    // Find all relevant files to validate
    const filesToValidate = await this.getFilesToValidate(context.workspace.projectPath);

    // Validate each file
    for (const filePath of filesToValidate) {
      const result = await this.validateFile(filePath, context);
      results.push(result);
    }

    return this.combineValidationResults(results);
  }

  private async validateAgainstStandards(
    filePath: string,
    content: string,
    context: SimpleAgentContext
  ): Promise<ValidationResult> {
    const violations: Violation[] = [];
    const warnings: ValidationWarning[] = [];

    // Get relevant standards for this file type
    const fileExtension = path.extname(filePath);
    const language = this.getLanguageFromExtension(fileExtension);

    if (language && context.standards.coding && context.standards.coding[language]) {
      const codingStandards = context.standards.coding[language];

      // Apply basic coding standards validation
      if (codingStandards.naming) {
        const namingViolations = this.validateNamingConventions(content, codingStandards.naming);
        violations.push(...namingViolations);
      }

      if (codingStandards.patterns) {
        const patternViolations = this.validatePatterns(content, codingStandards.patterns);
        warnings.push(...patternViolations);
      }
    }

    return {
      passed: violations.length === 0,
      violations,
      warnings,
      metrics: { standardsApplied: Object.keys(context.standards).length }
    };
  }

  private async getFilesToValidate(projectPath: string): Promise<string[]> {
    const patterns = [
      '**/*.ts',
      '**/*.js',
      '**/*.json',
      '**/*.yaml',
      '**/*.yml',
      '**/*.md'
    ];

    const files: string[] = [];
    for (const pattern of patterns) {
      const matchedFiles = await glob(pattern, {
        cwd: projectPath,
        absolute: true,
        ignore: ['**/node_modules/**', '**/dist/**', '**/.git/**']
      });
      files.push(...matchedFiles);
    }

    return files;
  }

  private getLanguageFromExtension(extension: string): SupportedLanguage | null {
    const extensionMap: Record<string, SupportedLanguage> = {
      '.ts': 'typescript',
      '.js': 'typescript', // Treat JS as TypeScript for standards
      '.go': 'go',
      '.py': 'python',
      '.java': 'java'
    };

    return extensionMap[extension] || null;
  }

  private combineValidationResults(results: ValidationResult[]): ValidationResult {
    const allViolations: Violation[] = [];
    const allWarnings: ValidationWarning[] = [];
    let totalMetrics = {};

    for (const result of results) {
      allViolations.push(...result.violations);
      allWarnings.push(...(result.warnings || []));
      totalMetrics = { ...totalMetrics, ...result.metrics };
    }

    return {
      passed: allViolations.filter(v => v.severity === 'error').length === 0,
      violations: allViolations,
      warnings: allWarnings,
      metrics: totalMetrics
    };
  }
}
```

### 6. Summary and Integration Points

#### 6.1 Simplified Integration Components

✅ **Basic Standards Validation**: Simple JSON file validation without complex schemas
✅ **Static File Processing**: Straightforward file copying with basic string replacement
✅ **File Validation Framework**: Basic validation for file syntax and standards compliance
✅ **Simple Standards Loading**: Direct JSON file loading with caching
✅ **Project Validation**: Comprehensive project-level validation with clear reporting

#### 6.2 Benefits of Simplified Approach

**Maintainability**:
- ✅ No complex template compilation or caching systems
- ✅ Easy to understand and debug file processing
- ✅ Simple string replacement patterns that humans can easily read and modify
- ✅ Direct file copying preserves original formatting and structure

**Performance**:
- ✅ Faster processing due to elimination of template compilation overhead
- ✅ Reduced memory usage without template caching systems
- ✅ Parallel file operations for improved throughput
- ✅ Simple validation rules that execute quickly

**Human Readability**:
- ✅ Static files are directly readable and editable
- ✅ Clear placeholder patterns ({{PROJECT_NAME}}) that are self-documenting
- ✅ No need to understand complex templating syntax
- ✅ Easy to customize and extend by users

#### 6.3 Complementary to requirements.md

This document provides the **simplified technical implementation patterns** for the standards and templates defined in requirements.md:

- **requirements.md**: Defines WHAT standards and templates are needed (authoritative source)
- **standards-templates-integration.md**: Defines HOW to implement them with simple, maintainable patterns

#### 6.4 Integration with Other Documents

- **technical-requirements.md**: Provides TypeScript interfaces for the simplified file processing system
- **repository-structure.md**: Defines where static files and standards are stored and organized
- **implementation-plan.md**: Schedules when simplified processing components are built

This simplified integration plan ensures that the standards from requirements.md are implemented in a maintainable, human-readable way that prioritizes simplicity and ease of use over complex templating capabilities.
