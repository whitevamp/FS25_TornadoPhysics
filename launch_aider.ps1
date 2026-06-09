# 1. Start your Python Backup Script
Start-Process python.exe -ArgumentList "C:\aider\auto_backup.py" -WindowStyle Minimized

# 2. Ensure .aiderignore exists (Ignore the 3GB texture bloat)
if (-not (Test-Path ".aiderignore")) {
@'
*.dds
*.fbx
*.wav
*.ogg
*.i3d
*.bin
*.zip
*.bak
*.copy
'@ | Set-Content -Path ".aiderignore" -Encoding utf8
}

# 3. Ensure .aider.model.settings.yml exists
# Fix: Using 'diff' format and ensuring zero leading spaces
if (-not (Test-Path ".aider.model.settings.yml")) {
@'
- name: openai/localhost:11434
  edit_format: diff
  use_repo_map: true
  send_undo_to_model: true
'@ | Set-Content -Path ".aider.model.settings.yml" -Encoding utf8
}

# 4. Launch Aider
# Use --architect here (the mode), while the config uses 'diff' (the format)
aider --model openai/localhost:11434 `
      --api-key openai=any `
      --read "..\dataS" `
      --encoding utf8 `
      --architect `
      --no-check-update `
      --no-fancy-input `
      --no-pretty `
      --no-show-model-warnings `
      *.lua *.xml