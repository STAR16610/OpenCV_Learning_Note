@echo off
cd /d D:\STUDY\university\programming\深度学习（python）\OpenCV   :: 改成你的笔记路径

for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD') do set BRANCH=%%b
echo 当前分支: %BRANCH%

echo 检查本地改动...
git add -A
for /f "delims=" %%s in ('git status --porcelain') do set CHANGED=1
if defined CHANGED (
  for /f "delims=" %%t in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm\""') do set NOW=%%t
  git commit -m "自动提交笔记：%NOW%"
)

echo 拉取远程更新...
git pull --rebase origin %BRANCH%

echo 推送到远程...
git push origin %BRANCH%

pause
