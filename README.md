# tedpreamble.sty

日常写作会使用的各类功能进行打包得到的一个用来精简前言区的宏包, 使用XeLaTex或latexmk编译

## 安装

### Windows

当前在Windows下的安装有两种方式

1. 使用部署脚本Deploy.PS1将包部署至TeX Live下的系统目录, 这通常需要将Deploy.PS1设置为管理员权限运行.

2. 将宏包文件放置在需要编译的文档的同一文件夹下, 需要注意的是这需要在导言区调用宏包时设置使用LaTeX以及XeCJK包默认字体的选项:  `\usepackage[defaultfonts=true]{tedpreamble}`, 以避免系统或TeX Live 没有对应字体. 

### MacOS, Linux以及Overleaf

目前这几个平台暂无对应部署脚本, 可以参考Windows安装方法(2)的安装方式

## 基础使用

在文档前言区使用调用宏包指令: `\usepackage{tedpreamble}`| 使用XeLaTex编译或使用latexmk编译
