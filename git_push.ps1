<#
.SYNOPSIS
    初始化本地 Git 仓库并推送到 GitHub 远程仓库
.DESCRIPTION
    自动完成：.gitignore 生成、Git 初始化、暂存文件、提交、远程仓库配置、推送
    包含完整的错误处理机制
#>

param(
    [string]$RemoteUrl = "",          # GitHub 远程仓库 URL（留空则使用已存在的 origin）
    [string]$RemoteName = "origin",   # 远程仓库名称
    [string]$BranchName = "main",     # 主分支名称
    [string]$CommitMessage = "chore: initial commit - 初始化项目"  # 提交信息
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "   Git 仓库初始化 & 推送工具" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# ============================================================
# 辅助函数
# ============================================================

function Write-Step {
    param([string]$Message)
    Write-Host "[$([DateTime]::Now.ToString('HH:mm:ss'))] " -NoNewline -ForegroundColor DarkGray
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✔ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "  ⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "  ✘ $Message" -ForegroundColor Red
}

function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# ============================================================
# Step 0: 环境检查
# ============================================================

Write-Step "Step 0/6: 环境检查..."

if (-not (Test-Command "git")) {
    Write-Error "未检测到 Git，请先安装 Git: https://git-scm.com/"
    exit 1
}
Write-Success "Git 已安装 ($(git --version 2>&1))"

# ============================================================
# Step 1: 生成 .gitignore
# ============================================================

Write-Step "Step 1/6: 生成 .gitignore 文件..."

$gitignoreContent = @"
# ============ Node.js ============
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
package-lock.json
yarn.lock
pnpm-lock.yaml

# ============ 构建输出 ============
dist/
build/
out/
.next/
.nuxt/

# ============ 系统文件 ============
.DS_Store
.DS_Store?
._*
Thumbs.db
desktop.ini
ehthumbs.db
$RECYCLE.BIN/

# ============ IDE / 编辑器 ============
.vscode/
.idea/
*.swp
*.swo
*~
*.sublime-workspace
*.sublime-project

# ============ 环境配置 ============
.env
.env.local
.env.*.local
*.env
secrets.*
credentials.*
*.pem
*.key

# ============ 日志文件 ============
*.log
logs/
*.pid

# ============ 临时文件 ============
tmp/
temp/
*.tmp
*.temp
.cache/

# ============ 操作系统 ============
# Windows
Windows/
# Linux
.directory
# macOS
.AppleDouble
.LSOverride
Icon

# ============ CodeBuddy ============
.codebuddy/sandbox/

# ============ 其他 ============
*.bak
*.orig
*.zip
*.tar.gz
*.7z
coverage/
.nyc_output/
"@

$gitignorePath = Join-Path $ScriptDir ".gitignore"
if (Test-Path $gitignorePath) {
    Write-Warning ".gitignore 已存在，将被覆盖"
}
Set-Content -Path $gitignorePath -Value $gitignoreContent -Encoding UTF8
Write-Success ".gitignore 已生成（排除 node_modules/系统文件/环境配置等）"

# ============================================================
# Step 2: 初始化 Git 仓库
# ============================================================

Write-Step "Step 2/6: 检查 Git 仓库状态..."

$isGitRepo = Test-Path (Join-Path $ScriptDir ".git")
if (-not $isGitRepo) {
    Write-Host "  正在初始化 Git 仓库..."
    git init
    Write-Success "Git 仓库已初始化"
} else {
    Write-Success "Git 仓库已存在，跳过初始化"
}

# ============================================================
# Step 3: 暂存所有文件
# ============================================================

Write-Step "Step 3/6: 暂存所有项目文件..."

git add -A
Write-Success "所有文件已添加到暂存区"

# 显示暂存状态
$status = git status --short 2>&1
if ($status) {
    Write-Host "  暂存文件列表:" -ForegroundColor DarkGray
    $status -split "`n" | ForEach-Object {
        if ($_.Trim() -ne "") {
            Write-Host "    $_" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Warning "没有文件需要提交，工作区干净"
    exit 0
}

# ============================================================
# Step 4: 提交
# ============================================================

Write-Step "Step 4/6: 提交代码..."

# 获取当前分支名
$currentBranch = (git branch --show-current 2>&1) -replace '\* ', ''
if (-not $currentBranch) {
    $currentBranch = $BranchName
}

# 如果当前分支不是 main，尝试重命名
if ($currentBranch -ne $BranchName) {
    Write-Host "  当前分支为 '$currentBranch'，将重命名为 '$BranchName'..."
    git branch -M $BranchName
    $currentBranch = $BranchName
    Write-Success "分支已重命名为 '$BranchName'"
}

# 执行提交
$commitOutput = git commit -m $CommitMessage 2>&1
if ($LASTEXITCODE -ne 0) {
    if ($commitOutput -match "nothing to commit") {
        Write-Warning "没有变更需要提交"
    } else {
        Write-Error "提交失败: $commitOutput"
        exit 1
    }
} else {
    Write-Success "提交成功: '$CommitMessage'"
}

# ============================================================
# Step 5: 配置远程仓库
# ============================================================

Write-Step "Step 5/6: 配置远程仓库..."

$existingRemotes = git remote 2>&1

if ($RemoteUrl -ne "") {
    # 用户指定了远程 URL
    if ($existingRemotes -match $RemoteName) {
        $currentUrl = (git remote get-url $RemoteName 2>&1)
        if ($currentUrl -ne $RemoteUrl) {
            Write-Warning "远程 '$RemoteName' 已存在，URL 不同，正在更新..."
            git remote set-url $RemoteName $RemoteUrl
            Write-Success "远程 '$RemoteName' URL 已更新为: $RemoteUrl"
        } else {
            Write-Success "远程 '$RemoteName' 已配置: $RemoteUrl"
        }
    } else {
        git remote add $RemoteName $RemoteUrl
        Write-Success "远程 '$RemoteName' 已添加: $RemoteUrl"
    }
} elseif ($existingRemotes -match $RemoteName) {
    # 使用已有的 origin
    $currentUrl = (git remote get-url $RemoteName 2>&1)
    Write-Success "使用现有远程 '$RemoteName': $currentUrl"
} else {
    Write-Error "未指定远程仓库 URL，且不存在 '$RemoteName' 远程配置"
    Write-Host ""
    Write-Host "  请执行以下操作之一:" -ForegroundColor Yellow
    Write-Host "  1. 在 GitHub 上创建仓库后，运行:" -ForegroundColor Yellow
    Write-Host "     .\git_push.ps1 -RemoteUrl 'https://github.com/你的用户名/仓库名.git'" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. 或者手动添加远程仓库:" -ForegroundColor Yellow
    Write-Host "     git remote add origin https://github.com/你的用户名/仓库名.git" -ForegroundColor White
    Write-Host "     然后运行: .\git_push.ps1" -ForegroundColor White
    Write-Host ""
    exit 1
}

# ============================================================
# Step 6: 推送到远程仓库
# ============================================================

Write-Step "Step 6/6: 推送代码到远程仓库..."

# 先尝试拉取远程分支（处理远程已有内容的情况）
$remoteExists = $false
try {
    $lsRemote = git ls-remote --heads $RemoteName $BranchName 2>&1
    if ($lsRemote -and $lsRemote.Trim() -ne "") {
        $remoteExists = $true
    }
} catch {
    $remoteExists = $false
}

$maxRetries = 2
$retryCount = 0
$pushSuccess = $false

while ($retryCount -le $maxRetries -and -not $pushSuccess) {
    if ($retryCount -gt 0) {
        Write-Host "  第 $retryCount 次重试..." -ForegroundColor Yellow
    }

    if ($remoteExists -and $retryCount -eq 0) {
        # 远程已有分支，先拉取合并
        Write-Host "  远程分支已存在，尝试拉取合并..."
        $pullOutput = git pull $RemoteName $BranchName --allow-unrelated-histories 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "拉取失败（可能有冲突），将尝试强制推送..."
            Write-Warning "  输出: $pullOutput"
        }
    }

    $pushOutput = git push -u $RemoteName $BranchName 2>&1
    if ($LASTEXITCODE -eq 0) {
        $pushSuccess = $true
        Write-Success "推送成功！代码已推送到 $RemoteName/$BranchName"
    } else {
        if ($pushOutput -match "rejected" -or $pushOutput -match "non-fast-forward") {
            Write-Warning "推送被拒绝（non-fast-forward），尝试强制推送..."
            $forcePush = git push -u $RemoteName $BranchName --force 2>&1
            if ($LASTEXITCODE -eq 0) {
                $pushSuccess = $true
                Write-Success "强制推送成功！"
            } else {
                Write-Error "强制推送也失败了: $forcePush"
            }
        } elseif ($pushOutput -match "Authentication failed" -or $pushOutput -match "403") {
            Write-Error "认证失败！请检查 GitHub 凭据"
            Write-Host "  解决方式:" -ForegroundColor Yellow
            Write-Host "  - 使用 GitHub CLI: gh auth login" -ForegroundColor White
            Write-Host "  - 使用 Personal Access Token" -ForegroundColor White
            Write-Host "  - 配置 SSH Key: git remote set-url origin git@github.com:用户名/仓库名.git" -ForegroundColor White
            break
        } elseif ($pushOutput -match "could not find remote") {
            Write-Error "找不到远程仓库！请确认仓库 URL 正确且仓库已创建"
            break
        } else {
            Write-Error "推送失败: $pushOutput"
        }
    }
    $retryCount++
}

# ============================================================
# 完成总结
# ============================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
if ($pushSuccess) {
    Write-Host "   🎉 全部完成！代码已成功推送到 GitHub" -ForegroundColor Green
} else {
    Write-Host "   ⚠ 部分步骤未完成，请检查上方错误信息" -ForegroundColor Yellow
}
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# 显示仓库信息
Write-Host "  仓库信息:" -ForegroundColor DarkGray
Write-Host "    本地路径 : $ScriptDir" -ForegroundColor White
try {
    $remoteUrl = (git remote get-url $RemoteName 2>&1)
    Write-Host "    远程仓库 : $remoteUrl" -ForegroundColor White
} catch {}
Write-Host "    分支     : $BranchName" -ForegroundColor White
Write-Host ""
