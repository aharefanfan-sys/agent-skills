#!/bin/bash
# 创建 GitHub 仓库并推送的步骤

# 1. 在 GitHub 网页上创建仓库：
#    https://github.com/new
#    仓库名: agent-skills
#    设为 Public 或 Private

# 2. 添加远程仓库并推送：
git remote add origin https://github.com/YOUR_USERNAME/agent-skills.git
git branch -M main
git push -u origin main

# 3. 在 QClaw 配置中添加此仓库地址：
#    skills_repo: https://github.com/YOUR_USERNAME/agent-skills
