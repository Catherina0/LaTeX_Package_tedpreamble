#!/usr/bin/env bash

# deploy.sh (中文注释版)
#
# 这是一个为 macOS/Linux 设计的 LaTeX 相关文件部署脚本。
# 它的功能是:
#   - 部署 .latexmkrc 配置文件到用户的主目录 (~/.latexmkrc)
#   - 部署 *.sty 样式文件到 TeX Live 的 TEXMFLOCAL 或 TEXMFHOME 目录
#   - 部署 fonts/ 目录下的字体到 TEXMFLOCAL (这通常需要管理员/sudo权限)

# --- 'set -e' 表示脚本中的任何命令一旦执行失败，整个脚本就会立即停止执行。
set -e

# ==============================================================================
# region 辅助函数和控制台设置
# ==============================================================================

# --- 定义用于彩色输出的ANSI转义码 ---
COLOR_RESET='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_CYAN='\033[0;36m'

# --- 日志输出函数 ---
# 用法: log_msg <级别> "消息内容"
# 级别可以是: STEP, INFO, OK, WARN, ERROR
log_msg() {
  local level="$1"
  local msg="$2"
  local prefix="[${level}] "
  local color="$COLOR_RESET"

  case "$level" in
    ERROR) color="$COLOR_RED" ;;
    WARN)  color="$COLOR_YELLOW" ;;
    OK)    color="$COLOR_GREEN" ;;
    STEP)  color="$COLOR_CYAN" ;;
  esac

  # 使用 -e 参数让 echo 能够解析颜色代码
  echo -e "${color}${prefix}${msg}${COLOR_RESET}"
}

# --- 用户确认函数 ---
# 用法: if confirm_yes "您确定要执行此操作吗?"; then ...; fi
# 接受 'y', 'Y' (yes) 或 's', 'S' (是)作为肯定的回答
confirm_yes() {
  local question="$1"
  # -p 参数可以在同一行显示提示信息
  read -p "$question (Y/S/N, 默认 N): " answer
  # 使用正则表达式匹配用户的输入
  [[ "$answer" =~ ^[YySs]$ ]]
}

# --- 外部工具调用函数 ---
# 用法: invoke_tool <sudo命令前缀> <工具名> <参数1> <参数2> ...
invoke_tool() {
  local sudo_cmd="$1"   # 是否需要sudo (可以是"sudo"或空字符串)
  local tool_name="$2"  # 要执行的命令, 例如 mktexlsr
  shift 2               # 将前两个参数移出参数列表
  local tool_args=("$@") # 剩下的都是命令的参数

  # 检查命令是否存在于系统的PATH中
  if ! command -v "$tool_name" &> /dev/null; then
    log_msg 'WARN' "命令 '$tool_name' 未找到 (请检查它是否已安装并在 PATH 环境变量中)。"
    return 1 # 返回失败状态
  fi

  log_msg 'STEP' "正在运行: ${sudo_cmd} ${tool_name} ${tool_args[*]}"
  # 执行命令, 并根据其返回值判断成功或失败
  if ${sudo_cmd} "${tool_name}" "${tool_args[@]}"; then
    log_msg 'OK' "'$tool_name' 执行成功。"
    return 0 # 返回成功状态
  else
    local exit_code=$?
    log_msg 'WARN' "'$tool_name' 执行失败，退出码为 $exit_code。"
    return $exit_code # 返回具体的失败退出码
  fi
}
# endregion

# ==============================================================================
# region 脚本和 TeX Live 环境初始化
# ==============================================================================

# --- 确定脚本文件所在的绝对路径 ---
# 这是一个健壮的方法，无论脚本如何被调用，都能找到其真实位置
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
log_msg 'STEP' "脚本所在目录: $SCRIPT_DIR"

# --- 使用 kpsewhich 工具获取 TeX Live 的重要路径变量 ---
# '2>/dev/null' 是为了在命令失败时抑制错误信息
# '|| echo ""' 是为了在命令失败时给变量赋一个空值，防止脚本因变量未定义而中断
TEXMFLOCAL=$(kpsewhich --var-value=TEXMFLOCAL 2>/dev/null || echo "")
TEXMFHOME=$(kpsewhich --var-value=TEXMFHOME 2>/dev/null || echo "")

log_msg 'STEP' "检测到 TEXMFLOCAL = $TEXMFLOCAL"
log_msg 'STEP' "检测到 TEXMFHOME  = $TEXMFHOME"
echo "" # 输出一个空行用于分隔
# endregion

# ==============================================================================
# region 主要部署逻辑
# ==============================================================================

# --- 用于最后生成报告的结果标记 ---
RC_INSTALLED=false
STY_INSTALLED=false
FONTS_INSTALLED=false
FONTS_SKIP_REASON="" # 记录字体安装被跳过的原因

# --- 1) 部署 latexmkrc 配置文件 ---
if confirm_yes "是否要安装/更新 latexmkrc 配置文件到您的用户目录?"; then
  SRC_RC=""
  # 检查当前目录下是否存在 latexmkrc 或 .latexmkrc
  if [ -f "$SCRIPT_DIR/latexmkrc" ]; then
    SRC_RC="$SCRIPT_DIR/latexmkrc"
  elif [ -f "$SCRIPT_DIR/.latexmkrc" ]; then
    SRC_RC="$SCRIPT_DIR/.latexmkrc"
  fi
  
  # 目标路径是用户主目录下的 .latexmkrc 文件
  DST_RC="$HOME/.latexmkrc"

  if [ -n "$SRC_RC" ]; then # 检查是否找到了源文件
    if [ -f "$DST_RC" ]; then
      log_msg 'INFO' "检测到已存在的目标文件，将执行覆盖: $DST_RC"
    else
      log_msg 'INFO' "将在以下位置创建新文件: $DST_RC"
    fi
    log_msg 'STEP' "正在复制 latexmkrc -> $DST_RC"
    cp -f "$SRC_RC" "$DST_RC" # -f 参数表示强制覆盖
    log_msg 'OK' "latexmkrc 配置文件安装完成。"
    RC_INSTALLED=true
  else
    log_msg 'WARN' "脚本目录中未找到 latexmkrc 或 .latexmkrc 文件，跳过此步骤。"
  fi
else
  log_msg 'INFO' "用户选择跳过 latexmkrc 的安装。"
fi
echo ""
# endregion

# --- 2) 部署 *.sty 样式文件 ---
if confirm_yes "是否要安装/更新 *.sty 样式文件到 TeX Live 系统?"; then
  # 使用 find 命令查找所有 .sty 文件，-print0 和 read -d '' 的组合可以正确处理带空格的文件名
  STY_FILES=()
  while IFS= read -r -d $'\0'; do
    STY_FILES+=("$REPLY")
  done < <(find "$SCRIPT_DIR" -maxdepth 1 -type f -name '*.sty' -print0)

  # 检查是否找到了任何 .sty 文件
  if [ ${#STY_FILES[@]} -gt 0 ]; then
    TARGET_TREE=""
    # 优先使用 TEXMFLOCAL (系统级)，前提是它存在且当前用户可写
    if [ -n "$TEXMFLOCAL" ] && [ -d "$TEXMFLOCAL" ] && [ -w "$TEXMFLOCAL" ]; then
      TARGET_TREE="$TEXMFLOCAL"
      log_msg 'STEP' "将把 .sty 文件安装到 (LOCAL): $TARGET_TREE"
    else
      # 如果 TEXMFLOCAL 不满足条件，则回退到 TEXMFHOME (用户级)
      if [ -z "$TEXMFHOME" ]; then
        TEXMFHOME="$HOME/texmf" # 如果 TEXMFHOME 未定义，则使用一个默认值
        log_msg 'INFO' "TEXMFHOME 未定义，将使用默认路径: $TEXMFHOME"
      fi
      TARGET_TREE="$TEXMFHOME"
      log_msg 'STEP' "回退方案: 将把 .sty 文件安装到 (HOME): $TARGET_TREE"
    fi
    
    # 样式文件通常放在 tex/latex 目录下
    TEXLATEX_DIR="$TARGET_TREE/tex/latex"
    if [ ! -d "$TEXLATEX_DIR" ]; then
      log_msg 'STEP' "目标目录不存在，正在创建: $TEXLATEX_DIR"
      mkdir -p "$TEXLATEX_DIR" # -p 参数可以创建多级目录
    fi

    # 遍历所有找到的 .sty 文件
    for f in "${STY_FILES[@]}"; do
      FILENAME=$(basename "$f")      # 获取文件名，如 a.sty
      PKG_NAME="${FILENAME%.*}"      # 去掉扩展名，获取包名，如 a
      PKG_DIR="$TEXLATEX_DIR/$PKG_NAME" # 每个包有自己的独立文件夹

      if [ ! -d "$PKG_DIR" ]; then
        log_msg 'STEP' "正在为宏包 '$PKG_NAME' 创建目录: $PKG_DIR"
        mkdir -p "$PKG_DIR"
      fi
      
      DST_FILE="$PKG_DIR/$FILENAME"
      if [ -f "$DST_FILE" ]; then
        log_msg 'INFO' "文件已存在，将覆盖: $DST_FILE"
      else
        log_msg 'INFO' "新安装: $DST_FILE"
      fi
      log_msg 'STEP' "正在复制: $FILENAME -> $DST_FILE"
      cp -f "$f" "$DST_FILE"
      log_msg 'OK' "完成复制: $FILENAME"
      STY_INSTALLED=true
    done
  else
    log_msg 'WARN' "未在本目录找到任何 .sty 文件，跳过样式安装。"
  fi
else
  log_msg 'INFO' "用户选择跳过 *.sty 文件的安装。"
fi
echo ""
# endregion

# --- 3) 部署 fonts 字体文件 (仅限 TEXMFLOCAL) ---
if confirm_yes "是否要安装/更新 fonts 目录中的字体? (可能需要管理员权限)"; then
  FONTS_SRC_DIR="$SCRIPT_DIR/fonts"
  SUDO_CMD="" # 默认不需要 sudo

  # 自动创建 fonts 目录（如果不存在）
  if [ ! -d "$FONTS_SRC_DIR" ]; then
    log_msg 'INFO' "未找到 'fonts' 目录，已自动创建。"
    mkdir -p "$FONTS_SRC_DIR"
  fi

  if [ -d "$FONTS_SRC_DIR" ]; then
    # 字体必须安装到 TEXMFLOCAL
    if [ -z "$TEXMFLOCAL" ] || [ ! -d "$TEXMFLOCAL" ]; then
      FONTS_SKIP_REASON="未找到 TEXMFLOCAL 目录。"
      log_msg 'WARN' "$FONTS_SKIP_REASON 无法安装字体。"
    # 如果 TEXMFLOCAL 存在但不可写，说明需要管理员权限
    elif ! [ -w "$TEXMFLOCAL" ]; then
      log_msg 'WARN' "TEXMFLOCAL 目录不可写，将尝试使用 'sudo'。"
      SUDO_CMD="sudo"
      log_msg 'INFO' "后续操作可能需要您输入管理员密码。"
      sudo -v # 提前请求一次sudo权限, 避免在循环中反复输入密码
    fi

    # 如果没有跳过原因，则继续安装
    if [ -z "$FONTS_SKIP_REASON" ]; then
      FONTS_DST_ROOT="$TEXMFLOCAL/fonts"
      log_msg 'STEP' "准备将字体安装到: $FONTS_DST_ROOT"
      ${SUDO_CMD} mkdir -p "$FONTS_DST_ROOT"

      # 递归查找 fonts 源目录下的所有文件
      while IFS= read -r -d $'\0'; do
        f="$REPLY"
        # 获取并转换为小写扩展名
        EXT="${f##*.}"
        LOWER_EXT=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
        
        # 根据扩展名确定字体类型和目标子目录
        CAT=""
        case "$LOWER_EXT" in
          otf)     CAT="opentype" ;;
          ttf|ttc) CAT="truetype" ;;
          pfb)     CAT="type1"    ;;
          afm)     CAT="afm"      ;;
          tfm)     CAT="tfm"      ;;
          vf)      CAT="vf"       ;;
          enc)     CAT="enc"      ;;
          map)     CAT="map"      ;;
          *)       continue ;; # 如果是未知扩展名，则跳过
        esac

        # 计算文件在源目录中的相对路径
        REL_DIR=$(dirname "${f#$FONTS_SRC_DIR/}")
        if [ "$REL_DIR" == "." ]; then REL_DIR=""; fi
        
        # 拼接出完整的目标目录路径
        DST_DIR="$FONTS_DST_ROOT/$CAT/$REL_DIR"
        
        if ! [ -d "$DST_DIR" ]; then
          log_msg 'STEP' "正在创建字体子目录: $DST_DIR"
          ${SUDO_CMD} mkdir -p "$DST_DIR"
        fi

        FILENAME=$(basename "$f")
        DST_FILE="$DST_DIR/$FILENAME"

        if [ -f "$DST_FILE" ]; then
          log_msg 'INFO' "字体已存在，将覆盖: $DST_FILE"
        else
          log_msg 'INFO' "正在安装新字体: $DST_FILE"
        fi
        log_msg 'STEP' "正在复制字体: $FILENAME -> $DST_FILE"
        ${SUDO_CMD} cp -f "$f" "$DST_FILE"
        log_msg 'OK' "完成复制: $FILENAME"
        FONTS_INSTALLED=true
      done < <(find "$FONTS_SRC_DIR" -type f -print0)

      if [ "$FONTS_INSTALLED" = true ]; then
        log_msg 'OK' "字体文件部署完成。"
      else
        log_msg 'INFO' "未找到可识别的字体文件，字体目录未发生变更。"
      fi
    fi
  else
    log_msg 'WARN' "未找到 'fonts' 目录，跳过字体安装。"
    FONTS_SKIP_REASON="源 'fonts' 目录不存在。"
  fi
else
  log_msg 'INFO' "用户选择跳过字体安装。"
fi
echo ""
# endregion

# ==============================================================================
# region 安装后刷新
# ==============================================================================

# 检查是否有任何类型的安装被执行过
DID_ANY_INSTALL=false
if [ "$RC_INSTALLED" = true ] || [ "$STY_INSTALLED" = true ] || [ "$FONTS_INSTALLED" = true ]; then
  DID_ANY_INSTALL=true
fi

if [ "$DID_ANY_INSTALL" = true ]; then
  log_msg 'STEP' "检测到文件变更，开始刷新 TeX Live 文件数据库..."
  SUDO_CMD=""
  # 如果安装了字体到系统目录，刷新数据库也需要 sudo
  if [ "$FONTS_INSTALLED" = true ]; then SUDO_CMD="sudo"; fi

  # 刷新文件名数据库，这是最基本的操作
  invoke_tool "${SUDO_CMD}" mktexlsr

  # 如果安装了字体，还需要刷新字体映射
  if [ "$FONTS_INSTALLED" = true ]; then
    # updmap-sys 用于更新 PostScript 和 PDF 的字体映射
    invoke_tool "sudo" updmap-sys
    # luaotfload-tool 用于更新 LuaLaTeX 的字体缓存
    invoke_tool "sudo" luaotfload-tool -u --force
  fi
else
  log_msg 'INFO' "未执行任何安装操作，无需刷新数据库。"
fi
# endregion

# ==============================================================================
# region 总结报告
# ==============================================================================
echo ""
echo "==================== 安装汇总 ===================="
if [ "$RC_INSTALLED" = true ]; then echo "latexmkrc : 已安装"; else echo "latexmkrc : 未安装"; fi
if [ "$STY_INSTALLED" = true ]; then echo "*.sty     : 已安装"; else echo "*.sty     : 未安装"; fi

if [ "$FONTS_INSTALLED" = true ]; then
  echo "fonts     : 已安装"
elif [ -n "$FONTS_SKIP_REASON" ]; then
  echo "fonts     : 未安装 (原因: $FONTS_SKIP_REASON)"
else
  echo "fonts     : 未安装"
fi
echo "=================================================="
read -p "按回车键退出..."
# endregion