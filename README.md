# tedpreamble.sty

日常写作会使用的各类功能进行打包得到的一个用来精简前言区的宏包, 使用XeLaTex或latexmk编译

## 安装

### Windows

当前在Windows下的安装有两种方式

1. 使用部署脚本Deploy.PS1将包部署至TeX Live下的系统目录, 这通常需要将Deploy.PS1设置为管理员权限运行.

2. 将宏包文件放置在需要编译的文档的同一文件夹下, 需要注意的是这需要在导言区调用宏包时设置使用LaTeX以及XeCJK包默认字体的选项:  `\usepackage[defaultfonts=true]{tedpreamble}`, 以避免系统或TeX Live 没有对应字体. 

### MacOS, Linux

#### 打开“终端” (Terminal)
1. 你可以在 应用程序 -> 实用工具 文件夹里找到它，或者直接通过 Spotlight 搜索 (快捷键 ⌘ + 空格) 输入 Terminal 并回车。

2. 进入脚本所在的文件夹

在终端里输入 cd  (注意 cd 后面有一个空格)。

然后，直接把存有 deploy.sh 文件的文件夹从访达 (Finder) 拖拽到终端窗口里。

按下回车键。

3. 授予执行权限

运行以下命令。chmod 是 "change mode" 的缩写，+x 表示 "add executable" (增加执行权限)。

chmod +x deploy.sh

运行脚本

./deploy.sh

### Overleaf
目前暂无对应部署脚本, 可以参考Windows安装方法(2)的安装方式

## 基础使用

在文档前言区使用调用宏包指令: `\usepackage{tedpreamble}`| 使用XeLaTex编译或使用latexmk编译
