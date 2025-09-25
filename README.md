# tedpreamble.sty

日常写作会使用的各类功能进行打包得到的一个用来精简前言区的宏包, 使用XeLaTex或latexmk编译

## 安装

### Windows

当前在Windows下的安装有两种方式

1. 使用部署脚本Deploy.PS1将包部署至TeX Live下的系统目录, 这通常需要将Deploy.PS1设置为管理员权限运行.

2. 将宏包文件放置在需要编译的文档的同一文件夹下, 需要注意的是这需要在导言区调用宏包时设置使用LaTeX以及XeCJK包默认字体的选项:  `\usepackage[defaultfonts=true]{tedpreamble}`, 以避免系统或TeX Live 没有对应字体. 

### MacOS, Linux

#### 打开"终端" (Terminal)

1. 你可以在 应用程序 -> 实用工具 文件夹里找到它,或者直接通过 Spotlight 搜索 (快捷键 ⌘ + 空格) 输入 Terminal 并回车.

2. 进入脚本所在的文件夹

在终端里输入 cd  (注意 cd 后面有一个空格).

然后,直接把存有 deploy.sh 文件的文件夹从访达 (Finder) 拖拽到终端窗口里.

按下回车键.

3. 授予执行权限

运行以下命令.chmod 是 "change mode" 的缩写,+x 表示 "add executable" (增加执行权限).

chmod +x deploy.sh

运行脚本

./deploy.sh

### Overleaf
目前暂无对应部署脚本, 可以参考Windows安装方法(2)的安装方式

## TeXstudio 自动补全 (cwl 文件)

TeXstudio 的命令/宏自动补全依赖于 .cwl 文件.cwl 文件的来源与优先级通常为(优先级从高到低):

1. 用户提供的 cwl(放在用户目录下的 TeXstudio completion 目录)  
2. TeXstudio 内置的 cwl(随程序分发的默认集合)  
3. TeXstudio 根据可用的 LaTeX 样式(.sty 等)自动生成的 cwl(作为最后的回退,仅用于语法/命令列表,不包含参数上下文或提示)

常用的用户自定义 cwl 目录(根据操作系统):
- Windows: %appdata%\texstudio\completion\user  
- macOS/Linux: ~/.config/texstudio/completion/user

说明与建议:
- 如果你在本仓库中把某个包的 .cwl 放在与 .sty 相同的位置,TeXstudio 不一定会自动读取该目录下的 cwl;要让 TeXstudio 使用自定义 cwl,建议将其复制到上述用户 cwl 目录,或者在 TeXstudio 设置中手动导入.  
- 当 TeXstudio 只能使用自动生成的 cwl 时,完成项只提供命令/环境名与基本语法,参数的上下文信息和补全提示通常不可用.

## 基础使用

在文档前言区使用调用宏包指令: `\usepackage{tedpreamble}`| 使用XeLaTex编译或使用latexmk编译
