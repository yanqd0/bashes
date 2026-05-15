#!/bin/bash
set -euo pipefail

SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

echo "==> 下载 Android 命令行工具..."
TMP_DIR="$(mktemp -d)"
curl -L --progress-bar -o "$TMP_DIR/cmdline-tools.zip" "$CMDLINE_TOOLS_URL"

echo "==> 安装到 $SDK_ROOT ..."
mkdir -p "$SDK_ROOT/cmdline-tools"
unzip -qo "$TMP_DIR/cmdline-tools.zip" -d "$TMP_DIR/cmdline-tools"
mkdir -p "$SDK_ROOT/cmdline-tools/latest"
mv "$TMP_DIR"/cmdline-tools/cmdline-tools/* "$SDK_ROOT/cmdline-tools/latest/"
rm -rf "$TMP_DIR"

# 写入或更新环境变量
ENV_FILE="$HOME/.bashrc"
SDK_VARS=(
  "export ANDROID_SDK_ROOT=$SDK_ROOT"
  "export ANDROID_HOME=$SDK_ROOT"
  'export PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator"'
)

for var in "${SDK_VARS[@]}"; do
  if ! grep -qxF "$var" "$ENV_FILE"; then
    echo "$var" >> "$ENV_FILE"
  fi
done

# 加载到当前 shell
export ANDROID_SDK_ROOT="$SDK_ROOT"
export ANDROID_HOME="$SDK_ROOT"
export PATH="$PATH:$SDK_ROOT/cmdline-tools/latest/bin:$SDK_ROOT/platform-tools:$SDK_ROOT/emulator"

echo ""
echo "============================================"
echo "  命令行工具安装完成！"
echo "============================================"
echo ""
echo "重新打开终端或执行以下命令使环境变量生效："
echo ""
echo "  source ~/.bashrc"
echo ""
echo "然后通过 sdkmanager 安装 Android SDK 组件："
echo ""
echo "  # 查看可用组件"
echo "  sdkmanager --list"
echo ""
echo "  # 安装基础 SDK（推荐）"
echo '  sdkmanager \'
echo '    "platform-tools" \'
echo '    "build-tools;34.0.0" \'
echo '    "platforms;android-34" \'
echo '    "cmdline-tools;latest"'
echo ""
echo "  # 安装模拟器（可选）"
echo '  sdkmanager \'
echo '    "emulator" \'
echo '    "system-images;android-34;google_apis;x86_64"'
echo ""
echo "  # 接受许可协议"
echo "  sdkmanager --licenses"
echo ""
echo "sdkmanager 数据会下载到 \$ANDROID_SDK_ROOT 目录。"
