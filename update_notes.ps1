$RepoPath = "D:\STUDY\university\programming\深度学习（python）\OpenCV"      # ← Typora 仓库目录
$Remote   = "origin"

Write-Host "== Typora 笔记自动同步 =="

# 进入仓库
Set-Location -Path $RepoPath

# 检查 git 是否可用
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host "未检测到 Git，请先安装 Git。" -ForegroundColor Red
  exit 1
}

# （可选）启动并使用 Windows 内置 ssh-agent 记住私钥密码
try {
  $svc = Get-Service ssh-agent -ErrorAction Stop
  if ($svc.Status -ne "Running") { Start-Service ssh-agent }
  # 如果你用的是 id_rsa/id_ed25519，下面这行会把私钥加入 agent（已加入过会提示已存在）
  ssh-add $env:USERPROFILE\.ssh\id_rsa 2>$null
  ssh-add $env:USERPROFILE\.ssh\id_ed25519 2>$null
} catch { }

# 当前分支名
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if (-not $branch) { Write-Host "无法检测当前分支。" -ForegroundColor Red; exit 1 }
Write-Host "当前分支: $branch"

# 先拉取远程（优先用 rebase，历史更整洁）
Write-Host "拉取远程更新..."
git pull --rebase $Remote $branch
if ($LASTEXITCODE -ne 0) {
  Write-Host "拉取时出现冲突/错误，请先解决冲突（git status / 编辑冲突文件 / git add / git rebase --continue）。" -ForegroundColor Yellow
  exit 1
}

# 是否有变更
$changed = git status --porcelain
if ([string]::IsNullOrWhiteSpace($changed)) {
  Write-Host "没有变更需要提交。"
  exit 0
}

# 添加 & 提交
git add -A
$now = Get-Date -Format "yyyy-MM-dd HH:mm"
git commit -m "更新笔记：$now"

if ($LASTEXITCODE -ne 0) {
  Write-Host "没有可提交的变更或提交失败。" -ForegroundColor Yellow
  exit 0
}

# 推送（如果未设置上游，第一次自动加 -u）
try {
  git rev-parse --abbrev-ref --symbolic-full-name "@{u}" *> $null
  $hasUpstream = $LASTEXITCODE -eq 0
} catch { $hasUpstream = $false }

if ($hasUpstream) {
  git push $Remote $branch
} else {
  git push -u $Remote $branch
}

if ($LASTEXITCODE -eq 0) {
  Write-Host "✅ 同步完成！" -ForegroundColor Green
} else {
  Write-Host "❌ 推送失败，请检查网络/凭据或冲突。" -ForegroundColor Red
}
