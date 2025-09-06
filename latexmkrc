# 构建目录: 让中间文件集中到 .latexmk
use strict;
use warnings;
use File::Path qw(make_path);
use IO::Handle;  # 为 autoflush/flush

our $out_dir = '.latexmk';
our $aux_dir = '.latexmk';
$out_dir = $out_dir;
$aux_dir = $aux_dir;

# 目录准备: 若不存在则创建 (静默)
BEGIN {
  for my $d ($out_dir) {
    next if -d $d;
    eval { make_path($d) };
  }
}

# 引擎选择: 使用 XeLaTeX 生成 pdf
$pdf_mode = 5;      # 等价于 -xelatex
$dvi_mode = 0;
$postscript_mode = 0;

# xdvipdfmx 参数: 压缩级别等
$xdvipdfmx = 'xdvipdfmx -z 1 -E -o %D %O %S';

# 记录依赖: 生成 .fls 以便工具分析依赖
$recorder = 1;

# XeLaTeX 命令: 不强制开启 shell-escape
$xelatex = 'xelatex -synctex=1 -file-line-error -halt-on-error %O %S';

# 交叉引用重复编译次数
$max_repeat = 5;

# 计时与统计: 统计 XeLaTeX 运行次数与总用时
BEGIN { eval 'use Time::HiRes qw(time)'; }
our $BUILD_T0 = time;
our $xelatex_runs = 0;

# 钩子: 在一次 *latex 运行结束后计数
add_hook('after_xlatex', sub { $xelatex_runs++; return 0; });

# 输出编码: 让 TeXstudio 能正确显示中文, 并启用立即刷新
BEGIN {
  my $enc =
    $ENV{LATEXMK_MSG_ENCODING} ? $ENV{LATEXMK_MSG_ENCODING}
    : ($^O =~ /MSWin32/ ? 'cp936' : 'UTF-8');
  binmode(STDERR, ":encoding($enc)");
  binmode(STDOUT, ":encoding($enc)");
  STDERR->autoflush(1);
  STDOUT->autoflush(1);
}

# 结束信息: 两条独立消息，使用 warn 且以 \n 结尾
END {
  my $elapsed = time - $BUILD_T0;

  # 立刻刷新，避免缓冲合并
  local $| = 1;

  # 注意：warn 若不以 \n 结尾，Perl 会附加 " at ... line ..." 的尾巴
  warn "! Build info: runs ${xelatex_runs} times.\n";
  warn "! Build info: Elapsed " . sprintf('%.6f', $elapsed) . " s\n";
}

# 可选: 更安静的输出
$silent = 1;

# 可选: 额外清理的扩展名
# push @clean_ext, 'run.xml', 'bcf';
