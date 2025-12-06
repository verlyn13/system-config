#!/usr/bin/env fish
# Project Template Generator
# Creates new projects with standardized structure and tooling

set -l project_type $argv[1]
set -l project_name $argv[2]

if test -z "$project_type" -o -z "$project_name"
    echo "Usage: new-project <type> <name>"
    echo ""
    echo "Types:"
    echo "  node       - Node.js/TypeScript project with Bun"
    echo "  python     - Python project with uv"
    echo "  go         - Go module project"
    echo "  rust       - Rust project with cargo"
    echo "  react      - React app with Vite"
    echo "  next       - Next.js 15 app"
    echo "  cli        - CLI tool (multi-language)"
    echo "  lib        - Library project"
    echo "  api        - API service"
    exit 1
end

# Determine project location
set -l github_user (chezmoi data | jq -r '.github_user')
set -l project_dir "$HOME/Development/$github_user/$project_name"

if test -d "$project_dir"
    echo "Error: Project already exists at $project_dir"
    exit 1
end

echo "🚀 Creating $project_type project: $project_name"
mkdir -p "$project_dir"
cd "$project_dir"

# Initialize git
git init --initial-branch=main

# Common files for all projects
echo "# $project_name

## Description
[Project description here]

## Installation
\`\`\`bash
# Installation instructions
\`\`\`

## Usage
\`\`\`bash
# Usage examples
\`\`\`

## Development
\`\`\`bash
# Development setup
\`\`\`

## License
MIT
" > README.md

# Create .gitignore
echo "# Dependencies
node_modules/
vendor/
target/
dist/
build/
*.egg-info/
__pycache__/

# Environment
.env
.env.*
!.env.example

# IDE
.vscode/
.idea/
*.swp
*.swo
.DS_Store

# Logs
*.log
logs/

# Test coverage
coverage/
*.coverage
.pytest_cache/

# Mise
.mise.local.toml
" > .gitignore

# Create .editorconfig
echo "# EditorConfig is awesome: https://EditorConfig.org
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2
trim_trailing_whitespace = true

[*.{py,go}]
indent_size = 4

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab
" > .editorconfig

# Create project-specific files based on type
switch $project_type
    case node
        # Node.js/TypeScript project with Bun
        echo "node 24
bun latest" > .mise.toml
        
        bun init -y
        
        # Add TypeScript
        bun add -d @types/bun typescript @types/node
        bun add -d @biomejs/biome vitest
        
        # Create tsconfig.json
        echo '{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "lib": ["ES2022"],
    "jsx": "react-jsx",
    "moduleResolution": "bundler",
    "moduleDetection": "force",
    "allowImportingTsExtensions": true,
    "strict": true,
    "skipLibCheck": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noEmit": true,
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "types": ["bun-types"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}' > tsconfig.json
        
        # Create source structure
        mkdir -p src tests
        echo "export const hello = (name: string) => \`Hello, \${name}!\`;

console.log(hello('World'));" > src/index.ts
        
        # Update package.json scripts
        set -l pkg_content (cat package.json)
        echo $pkg_content | jq '.scripts = {
          "dev": "bun run src/index.ts",
          "build": "bun build src/index.ts --outdir dist",
          "test": "vitest",
          "test:run": "vitest run",
          "lint": "biome check .",
          "format": "biome format --write ."
        }' > package.json
        
    case python
        # Python project with uv
        echo "python 3.13" > .mise.toml
        
        uv init --python 3.13
        uv add --dev pytest pytest-cov black ruff mypy
        
        # Create project structure
        mkdir -p src/$project_name tests docs
        echo "\"\"\"$project_name - [description here]\"\"\"

__version__ = \"0.1.0\"


def main():
    \"\"\"Main entry point.\"\"\"
    print(f\"Hello from {__name__}!\")


if __name__ == \"__main__\":
    main()
" > src/$project_name/__init__.py
        
        # Create pyproject.toml additions
        echo "[tool.black]
line-length = 88
target-version = ['py313']

[tool.ruff]
line-length = 88
select = [\"E\", \"F\", \"I\", \"N\", \"W\"]
ignore = []

[tool.mypy]
python_version = \"3.13\"
warn_return_any = true
warn_unused_configs = true

[tool.pytest.ini_options]
testpaths = [\"tests\"]
python_files = [\"test_*.py\", \"*_test.py\"]
" >> pyproject.toml
        
    case go
        # Go module project
        echo "go 1.25" > .mise.toml
        
        go mod init "github.com/$github_user/$project_name"
        
        # Create project structure
        mkdir -p cmd/$project_name pkg internal
        
        echo "package main

import (
    \"fmt\"
    \"log\"
)

func main() {
    fmt.Println(\"Hello from $project_name\")
}
" > cmd/$project_name/main.go
        
        # Create Makefile
        echo ".PHONY: build run test clean

build:
\tgo build -o bin/$project_name cmd/$project_name/main.go

run:
\tgo run cmd/$project_name/main.go

test:
\tgo test -v ./...

clean:
\trm -rf bin/

install:
\tgo install cmd/$project_name/main.go
" > Makefile
        
    case rust
        # Rust project with cargo
        echo "rust stable" > .mise.toml
        
        cargo init --name $project_name
        
        # Add common dependencies
        cargo add tokio --features full
        cargo add --dev criterion
        
    case react
        # React app with Vite
        echo "node 24
bun latest" > .mise.toml
        
        bunx create-vite . --template react-ts
        bun install
        bun add -d @biomejs/biome @testing-library/react @testing-library/jest-dom vitest jsdom
        
        # Configure Vite for testing
        echo "import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/test/setup.ts',
  },
})" > vite.config.ts
        
    case next
        # Next.js 15 app
        echo "node 24
bun latest" > .mise.toml
        
        bunx create-next-app@latest . \
            --typescript \
            --tailwind \
            --app \
            --no-src-dir \
            --import-alias "@/*" \
            --use-bun
        
    case cli
        # CLI tool template (Node.js by default)
        echo "node 24
bun latest" > .mise.toml
        
        bun init -y
        bun add commander chalk ora inquirer
        bun add -d @types/node typescript
        
        mkdir -p src
        echo "#!/usr/bin/env node
import { Command } from 'commander';
import chalk from 'chalk';

const program = new Command();

program
  .name('$project_name')
  .description('CLI tool description')
  .version('0.1.0');

program
  .command('hello <name>')
  .description('Say hello')
  .action((name) => {
    console.log(chalk.green(\`Hello, \${name}!\`));
  });

program.parse();
" > src/cli.ts
        
        # Update package.json
        set -l pkg_content (cat package.json)
        echo $pkg_content | jq '.bin = {"'$project_name'": "./dist/cli.js"} | .scripts.build = "bun build src/cli.ts --outfile dist/cli.js --target node"' > package.json
        
    case lib
        # Library project (TypeScript)
        echo "node 24
bun latest" > .mise.toml
        
        bun init -y
        bun add -d typescript @types/node tsup vitest
        
        # Create library structure
        mkdir -p src tests
        echo "export function add(a: number, b: number): number {
  return a + b;
}

export function multiply(a: number, b: number): number {
  return a * b;
}
" > src/index.ts
        
        # Configure tsup for building
        echo "import { defineConfig } from 'tsup';

export default defineConfig({
  entry: ['src/index.ts'],
  format: ['cjs', 'esm'],
  dts: true,
  splitting: false,
  sourcemap: true,
  clean: true,
});" > tsup.config.ts
        
    case api
        # API service (Node.js with Fastify)
        echo "node 24
bun latest" > .mise.toml
        
        bun init -y
        bun add fastify @fastify/cors @fastify/helmet @fastify/swagger @fastify/swagger-ui
        bun add -d @types/node typescript tsx nodemon
        
        mkdir -p src/routes src/plugins
        
        echo "import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';

const server = Fastify({
  logger: true
});

server.register(cors, { origin: true });
server.register(helmet);

server.get('/health', async () => {
  return { status: 'ok', timestamp: new Date().toISOString() };
});

server.get('/', async () => {
  return { message: 'Hello from $project_name API' };
});

const start = async () => {
  try {
    await server.listen({ port: 3000, host: '0.0.0.0' });
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};

start();
" > src/server.ts
        
        # Update package.json scripts
        set -l pkg_content (cat package.json)
        echo $pkg_content | jq '.scripts = {
          "dev": "tsx watch src/server.ts",
          "build": "bun build src/server.ts --outdir dist --target node",
          "start": "node dist/server.js",
          "test": "vitest"
        }' > package.json
        
    case '*'
        echo "Unknown project type: $project_type"
        rm -rf "$project_dir"
        exit 1
end

# Create .envrc for direnv (robust mise integration)
echo "# Direnv configuration
# Automatically load project environment

# Load mise integration and activate tools (no external calls)
use_mise() {
  direnv_load mise direnv exec
}
use mise

# Project-specific environment variables
export PROJECT_NAME=\"$project_name\"
export PROJECT_TYPE=\"$project_type\"

# Add local bins
PATH_add bin
PATH_add node_modules/.bin

# Load env files if present
dotenv_if_exists .env.local
dotenv_if_exists .env
" > .envrc

direnv allow .

# Create VS Code settings
mkdir -p .vscode
echo '{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  },
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/node_modules": true,
    "**/target": true,
    "**/__pycache__": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/build": true,
    "**/target": true
  }
}' > .vscode/settings.json

# Initial git commit
git add -A
git commit -m "Initial commit: $project_type project setup"

echo ""
echo "✅ Project created successfully at: $project_dir"
echo ""
echo "Next steps:"
echo "  cd $project_dir"
echo "  mise install        # Install language versions"
echo "  direnv allow .      # Allow environment loading (dot required!)"

switch $project_type
    case node react next cli lib api
        echo "  bun install        # Install dependencies"
        echo "  bun run dev        # Start development"
    case python
        echo "  uv sync            # Install dependencies"
        echo "  uv run python src/$project_name/__init__.py"
    case go
        echo "  make build         # Build the project"
        echo "  make run           # Run the project"
    case rust
        echo "  cargo build        # Build the project"
        echo "  cargo run          # Run the project"
end

echo ""
echo "🎉 Happy coding!"
